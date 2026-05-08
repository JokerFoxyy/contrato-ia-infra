#!/bin/bash
set -euo pipefail

# ==============================================================================
# EC2 Bootstrap Script — Docker + PostgreSQL + CloudWatch Agent
# ContratoIA Backend (${environment})
# ==============================================================================

echo ">>> Starting bootstrap for ${project} (${environment})"

# ──────────────────────────────────────────────────────────────────────────────
# 1. System updates
# ──────────────────────────────────────────────────────────────────────────────
dnf update -y

# ──────────────────────────────────────────────────────────────────────────────
# 2. Install Docker
# ──────────────────────────────────────────────────────────────────────────────
dnf install -y docker jq
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# ──────────────────────────────────────────────────────────────────────────────
# 3. Install Docker Compose plugin
# ──────────────────────────────────────────────────────────────────────────────
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# ──────────────────────────────────────────────────────────────────────────────
# 4. Install CodeDeploy Agent
# ──────────────────────────────────────────────────────────────────────────────
dnf install -y ruby wget
cd /tmp
wget "https://aws-codedeploy-${aws_region}.s3.${aws_region}.amazonaws.com/latest/install"
chmod +x ./install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# ──────────────────────────────────────────────────────────────────────────────
# 5. Install and configure CloudWatch Agent
# ──────────────────────────────────────────────────────────────────────────────
dnf install -y amazon-cloudwatch-agent

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/contrato-ia/app.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/app",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/contrato-ia/postgres.log",
            "log_group_name": "${log_group_name}",
            "log_stream_name": "{instance_id}/postgres",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "${project}/${environment}",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"],
        "metrics_collection_interval": 300
      }
    }
  }
}
CWCONFIG

systemctl enable amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# ──────────────────────────────────────────────────────────────────────────────
# 5. Create app directories
# ──────────────────────────────────────────────────────────────────────────────
mkdir -p /opt/contrato-ia
mkdir -p /var/log/contrato-ia
mkdir -p /opt/contrato-ia/postgres-data
chown -R ec2-user:ec2-user /opt/contrato-ia /var/log/contrato-ia

# ──────────────────────────────────────────────────────────────────────────────
# 6. Create Docker Compose (PostgreSQL + Backend)
# ──────────────────────────────────────────────────────────────────────────────
cat > /opt/contrato-ia/docker-compose.yml <<'COMPOSE'
services:
  postgres:
    image: postgres:16-alpine
    container_name: contrato-ia-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: contratoiadb
      POSTGRES_USER: $${DB_USERNAME}
      POSTGRES_PASSWORD: $${DB_PASSWORD}
    volumes:
      - /opt/contrato-ia/postgres-data:/var/lib/postgresql/data
      - /var/log/contrato-ia/postgres.log:/var/log/postgresql/postgresql.log
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${DB_USERNAME} -d contratoiadb"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    image: $${BACKEND_IMAGE}
    container_name: contrato-ia-backend
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    environment:
      DB_URL: jdbc:postgresql://postgres:5432/contratoiadb
      DB_USERNAME: $${DB_USERNAME}
      DB_PASSWORD: $${DB_PASSWORD}
      CLAUDE_API_KEY: $${CLAUDE_API_KEY}
      KEYCLOAK_ISSUER_URI: $${KEYCLOAK_ISSUER_URI}
      SPRING_PROFILES_ACTIVE: prod
      AWS_DEFAULT_REGION: ${aws_region}
      AWS_SQS_GENERATION_QUEUE_URL: $${SQS_QUEUE_URL}
      AWS_S3_BUCKET: $${S3_BUCKET}
      JAVA_OPTS: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
    ports:
      - "8080:8080"
    volumes:
      - /var/log/contrato-ia:/app/logs
COMPOSE

# ──────────────────────────────────────────────────────────────────────────────
# 7. Create deploy script (used by CI/CD)
# ──────────────────────────────────────────────────────────────────────────────
cat > /opt/contrato-ia/deploy.sh <<'DEPLOY'
#!/bin/bash
set -euo pipefail

REGION="${aws_region}"
IMAGE="$1"

echo ">>> Deploying: $IMAGE"

# Login to GHCR
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

# Pull new image
docker pull "$IMAGE"

# Get secrets from Secrets Manager
SECRETS=$(aws secretsmanager get-secret-value \
  --region "$REGION" \
  --secret-id "${project}/${environment}/app-secrets" \
  --query SecretString --output text)

# Export secrets as env vars for docker-compose
export DB_USERNAME=$(echo "$SECRETS" | jq -r '.DB_USERNAME')
export DB_PASSWORD=$(echo "$SECRETS" | jq -r '.DB_PASSWORD')
export CLAUDE_API_KEY=$(echo "$SECRETS" | jq -r '.CLAUDE_API_KEY')
export KEYCLOAK_ISSUER_URI=$(echo "$SECRETS" | jq -r '.KEYCLOAK_ISSUER_URI')
export BACKEND_IMAGE="$IMAGE"
export SQS_QUEUE_URL="$SQS_QUEUE_URL"
export S3_BUCKET="$S3_BUCKET"

cd /opt/contrato-ia

# Start/update services
docker compose up -d

# Cleanup old images
docker image prune -f

echo ">>> Deploy complete: $IMAGE"
DEPLOY
chmod +x /opt/contrato-ia/deploy.sh

# ──────────────────────────────────────────────────────────────────────────────
# 8. Start PostgreSQL on first boot
# ──────────────────────────────────────────────────────────────────────────────
cd /opt/contrato-ia

# Get secrets for initial PostgreSQL start
SECRETS=$(aws secretsmanager get-secret-value \
  --region "${aws_region}" \
  --secret-id "${project}/${environment}/app-secrets" \
  --query SecretString --output text 2>/dev/null || echo '{}')

export DB_USERNAME=$(echo "$SECRETS" | jq -r '.DB_USERNAME // "contrato_user"')
export DB_PASSWORD=$(echo "$SECRETS" | jq -r '.DB_PASSWORD // "changeme"')
export BACKEND_IMAGE="hello-world"  # placeholder until first deploy
export CLAUDE_API_KEY="placeholder"
export KEYCLOAK_ISSUER_URI="placeholder"
export SQS_QUEUE_URL="placeholder"
export S3_BUCKET="placeholder"

# Start only PostgreSQL first (backend will be deployed via CI/CD)
docker compose up -d postgres

echo ">>> Bootstrap complete for ${project} (${environment})"
echo ">>> PostgreSQL running on port 5432"
echo ">>> Run deploy.sh to start the backend"

#!/bin/bash
set -euo pipefail

# ==============================================================================
# EC2 Bootstrap Script — Docker + CloudWatch Agent
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
dnf install -y docker
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
# 4. Install and configure CloudWatch Agent
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
chown -R ec2-user:ec2-user /opt/contrato-ia /var/log/contrato-ia

# ──────────────────────────────────────────────────────────────────────────────
# 6. Create deploy script (used by CI/CD)
# ──────────────────────────────────────────────────────────────────────────────
cat > /opt/contrato-ia/deploy.sh <<'DEPLOY'
#!/bin/bash
set -euo pipefail

REGION="${aws_region}"
IMAGE="$1"

echo ">>> Pulling image: $IMAGE"

# Login to GHCR
echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin

# Pull new image
docker pull "$IMAGE"

# Stop existing container
docker stop contrato-ia-backend 2>/dev/null || true
docker rm contrato-ia-backend 2>/dev/null || true

# Get secrets from Secrets Manager
SECRETS=$(aws secretsmanager get-secret-value \
  --region "$REGION" \
  --secret-id "${project}/${environment}/app-secrets" \
  --query SecretString --output text)

DB_URL=$(echo "$SECRETS" | jq -r '.DB_URL')
DB_USERNAME=$(echo "$SECRETS" | jq -r '.DB_USERNAME')
DB_PASSWORD=$(echo "$SECRETS" | jq -r '.DB_PASSWORD')
CLAUDE_API_KEY=$(echo "$SECRETS" | jq -r '.CLAUDE_API_KEY')
KEYCLOAK_ISSUER_URI=$(echo "$SECRETS" | jq -r '.KEYCLOAK_ISSUER_URI')

# Run new container
docker run -d \
  --name contrato-ia-backend \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /var/log/contrato-ia:/app/logs \
  -e DB_URL="$DB_URL" \
  -e DB_USERNAME="$DB_USERNAME" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e CLAUDE_API_KEY="$CLAUDE_API_KEY" \
  -e KEYCLOAK_ISSUER_URI="$KEYCLOAK_ISSUER_URI" \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e AWS_DEFAULT_REGION="$REGION" \
  -e JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0" \
  "$IMAGE"

# Cleanup old images
docker image prune -f

echo ">>> Deploy complete: $IMAGE"
DEPLOY
chmod +x /opt/contrato-ia/deploy.sh
chown ec2-user:ec2-user /opt/contrato-ia/deploy.sh

# ──────────────────────────────────────────────────────────────────────────────
# 7. Install jq (for deploy script)
# ──────────────────────────────────────────────────────────────────────────────
dnf install -y jq

echo ">>> Bootstrap complete for ${project} (${environment})"

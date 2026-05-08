# ──────────────────────────────────────────────────────────────────────────────
# ContratoIA — Production Variables
# ──────────────────────────────────────────────────────────────────────────────
# IMPORTANT: Sensitive values (db_password, claude_api_key, etc.) should be
# passed via environment variables or a .tfvars file NOT committed to git.
#
# Example:
#   export TF_VAR_db_password="strong-password-here"
#   export TF_VAR_claude_api_key="sk-ant-..."
#   terraform apply
# ──────────────────────────────────────────────────────────────────────────────

project     = "contrato-ia"
environment = "production"
aws_region  = "sa-east-1"

# Compute — EC2 roda backend + PostgreSQL via Docker
ec2_instance_type = "t3.small"

# Networking
cors_origins      = ["https://contrato-ia-frontend.vercel.app"]
ssh_allowed_cidrs = [] # Add your IP: ["YOUR_IP/32"]

# Keycloak (update with actual URL after Keycloak setup)
keycloak_issuer_uri = "https://auth.contrato-ia.com.br/realms/contrato-ia"

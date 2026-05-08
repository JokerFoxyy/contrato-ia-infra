# CLAUDE.md

## Project

ContratoIA infrastructure — Terraform modules for AWS deployment. Manages VPC, EC2 (with Docker for backend + PostgreSQL), S3, SQS FIFO, Secrets Manager, and CloudWatch.

## Commands

```bash
# Navigate to the environment
cd environments/production   # or staging

# Initialize Terraform
terraform init

# Plan changes (always plan first)
terraform plan

# Apply changes
terraform apply

# Destroy (staging only)
terraform destroy
```

Sensitive variables must be passed via environment variables:
```bash
export TF_VAR_db_password="strong-password"
export TF_VAR_claude_api_key="sk-ant-..."
```

## Architecture

Production runs backend + PostgreSQL on the same EC2 via Docker Compose. The RDS module exists for future migration when revenue justifies the cost.

Modular structure:

- **networking/** — VPC, subnets (2 AZs), IGW, route tables, security groups
- **compute/** — EC2 instance with Docker Compose (backend + PostgreSQL), IAM role, Elastic IP, CloudWatch
- **database/** — RDS PostgreSQL 16 (available for future migration, not used in production currently)
- **storage/** — S3 bucket with versioning, encryption, lifecycle rules
- **queue/** — SQS FIFO queue + DLQ for async document generation
- **secrets/** — AWS Secrets Manager for app credentials

## Cost Estimate

| Resource | Production |
|----------|------------|
| EC2 t3.small (backend + PostgreSQL) | ~$15/mo |
| S3 | ~$0 |
| SQS FIFO | ~$0 |
| CloudWatch | ~$0.50/mo |
| Secrets Manager | ~$0.40/mo |
| Elastic IP | $0 (attached) |
| **Total** | **~$16/mo** |

## Security

- PostgreSQL only accessible from localhost (Docker network)
- EC2 uses IMDSv2 (required)
- S3 public access blocked, SSE-S3 encryption
- Secrets in AWS Secrets Manager (never in tfvars committed to git)
- SSH restricted to specific CIDRs
- PostgreSQL data persisted on encrypted EBS volume

## Git workflow

Same as other repos: feature branches → develop → main via PR.

## CI/CD

- **PR to main**: `terraform plan` runs automatically
- **Manual dispatch**: choose environment + action (plan/apply)
- Never auto-apply — always manual approval

## Future migration to RDS

When revenue justifies (~$28/mo extra), migrate PostgreSQL to RDS:
1. Uncomment `module "database"` in production/main.tf
2. Change `db_url` in secrets from `localhost` to RDS endpoint
3. Dump data from Docker PostgreSQL, import into RDS
4. Redeploy backend pointing to RDS

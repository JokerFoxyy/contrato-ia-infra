# CLAUDE.md

## Project

ContratoIA infrastructure — Terraform modules for AWS deployment. Manages VPC, EC2, RDS PostgreSQL, S3, SQS FIFO, Secrets Manager, and CloudWatch for the ContratoIA backend.

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

# Destroy (staging only — production has deletion_protection)
terraform destroy
```

Sensitive variables must be passed via environment variables:
```bash
export TF_VAR_db_password="strong-password"
export TF_VAR_claude_api_key="sk-ant-..."
```

## Architecture

Modular structure with reusable modules:

- **networking/** — VPC, subnets (2 AZs), IGW, route tables, security groups
- **compute/** — EC2 instance with Docker, IAM role, Elastic IP, CloudWatch log group
- **database/** — RDS PostgreSQL 16 (free tier eligible)
- **storage/** — S3 bucket with versioning, encryption, lifecycle rules
- **queue/** — SQS FIFO queue + DLQ for async document generation
- **secrets/** — AWS Secrets Manager for app credentials

Environments (`environments/staging` and `environments/production`) compose these modules with environment-specific configs.

## Cost Estimate

| Resource | Staging | Production |
|----------|---------|------------|
| EC2 | t3.micro (~$8/mo) | t3.small (~$15/mo) |
| RDS | db.t3.micro (~$7/mo) | db.t3.micro (~$7/mo) |
| S3 | ~$0 | ~$0 |
| SQS | ~$0 | ~$0 |
| CloudWatch | ~$0.50/mo | ~$0.50/mo |
| Secrets Manager | ~$0.40/mo | ~$0.40/mo |
| Elastic IP | $0 (attached) | $0 (attached) |
| **Total** | **~$16/mo** | **~$23/mo** |

## Security

- RDS only accessible from EC2 security group (private subnets)
- EC2 uses IMDSv2 (required)
- S3 public access blocked, SSE-S3 encryption
- Secrets in AWS Secrets Manager (never in tfvars committed to git)
- SSH restricted to specific CIDRs

## Git workflow

Same as other repos: feature branches → develop → main via PR.

## CI/CD

- **PR to main**: `terraform plan` runs automatically
- **Manual dispatch**: choose environment + action (plan/apply)
- Never auto-apply — always manual approval

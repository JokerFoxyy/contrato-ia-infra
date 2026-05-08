################################################################################
# ContratoIA — Production Environment
# Setup econômico: EC2 t3.small + PostgreSQL via Docker (~$16/mês)
################################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 para state remoto (criar manualmente antes do primeiro apply)
  # backend "s3" {
  #   bucket         = "contrato-ia-terraform-state"
  #   key            = "production/terraform.tfstate"
  #   region         = "sa-east-1"
  #   dynamodb_table = "contrato-ia-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# Networking
# ──────────────────────────────────────────────────────────────────────────────

module "networking" {
  source = "../../modules/networking"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  vpc_cidr              = "10.0.0.0/16"
  public_subnet_a_cidr  = "10.0.1.0/24"
  public_subnet_b_cidr  = "10.0.2.0/24"
  private_subnet_a_cidr = "10.0.10.0/24"
  private_subnet_b_cidr = "10.0.11.0/24"
  ssh_allowed_cidrs     = var.ssh_allowed_cidrs
}

# ──────────────────────────────────────────────────────────────────────────────
# Storage (S3)
# ──────────────────────────────────────────────────────────────────────────────

module "storage" {
  source = "../../modules/storage"

  project     = var.project
  environment = var.environment
  cors_origins = var.cors_origins
}

# ──────────────────────────────────────────────────────────────────────────────
# Queue (SQS FIFO)
# ──────────────────────────────────────────────────────────────────────────────

module "queue" {
  source = "../../modules/queue"

  project     = var.project
  environment = var.environment
}

# ──────────────────────────────────────────────────────────────────────────────
# Database — PostgreSQL roda via Docker na EC2 (economia ~$28/mês vs RDS)
# O módulo database (RDS) fica disponível para migração futura.
# ──────────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────────
# Secrets Manager
# ──────────────────────────────────────────────────────────────────────────────

module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment

  db_url              = "jdbc:postgresql://localhost:5432/contratoiadb"
  db_username         = var.db_username
  db_password         = var.db_password
  claude_api_key      = var.claude_api_key
  keycloak_issuer_uri = var.keycloak_issuer_uri
  stripe_secret_key   = var.stripe_secret_key
  stripe_webhook_secret = var.stripe_webhook_secret
}

# ──────────────────────────────────────────────────────────────────────────────
# Compute (EC2)
# ──────────────────────────────────────────────────────────────────────────────

module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  instance_type  = var.ec2_instance_type
  subnet_id      = module.networking.public_subnet_ids[0]
  security_group_id = module.networking.ec2_security_group_id
  key_pair_name  = var.ec2_key_pair_name

  s3_bucket_arn  = module.storage.bucket_arn
  sqs_queue_arns = module.queue.all_queue_arns
  secrets_arn    = module.secrets.secret_arn

  cloudwatch_log_group_name = "/${var.project}/${var.environment}/backend"
  log_retention_days        = 30
}

################################################################################
# ContratoIA — Staging Environment
# Mesma arquitetura de production, instâncias menores
################################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "contrato-ia-terraform-state"
  #   key            = "staging/terraform.tfstate"
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

module "networking" {
  source = "../../modules/networking"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  vpc_cidr              = "10.1.0.0/16"
  public_subnet_a_cidr  = "10.1.1.0/24"
  public_subnet_b_cidr  = "10.1.2.0/24"
  private_subnet_a_cidr = "10.1.10.0/24"
  private_subnet_b_cidr = "10.1.11.0/24"
  ssh_allowed_cidrs     = var.ssh_allowed_cidrs
}

module "storage" {
  source = "../../modules/storage"

  project      = var.project
  environment  = var.environment
  cors_origins = var.cors_origins
}

module "queue" {
  source = "../../modules/queue"

  project     = var.project
  environment = var.environment
}

module "database" {
  source = "../../modules/database"

  project     = var.project
  environment = var.environment

  instance_class = "db.t3.micro"
  db_username    = var.db_username
  db_password    = var.db_password
  multi_az       = false

  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.networking.rds_security_group_id
}

module "secrets" {
  source = "../../modules/secrets"

  project     = var.project
  environment = var.environment

  db_url              = module.database.jdbc_url
  db_username         = var.db_username
  db_password         = var.db_password
  claude_api_key      = var.claude_api_key
  keycloak_issuer_uri = var.keycloak_issuer_uri
}

module "compute" {
  source = "../../modules/compute"

  project     = var.project
  environment = var.environment
  aws_region  = var.aws_region

  instance_type     = "t3.micro" # Menor para staging
  subnet_id         = module.networking.public_subnet_ids[0]
  security_group_id = module.networking.ec2_security_group_id
  key_pair_name     = var.ec2_key_pair_name

  s3_bucket_arn  = module.storage.bucket_arn
  sqs_queue_arns = module.queue.all_queue_arns
  secrets_arn    = module.secrets.secret_arn

  cloudwatch_log_group_name = "/${var.project}/${var.environment}/backend"
  log_retention_days        = 7 # Menor retenção em staging
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "contrato-ia"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "sa-east-1"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH into EC2 (your IP)"
  type        = list(string)
  default     = []
}

variable "cors_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["https://contrato-ia-frontend.vercel.app"]
}

# ── Compute ───────────────────────────────────────────────────────────────────

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "ec2_key_pair_name" {
  description = "EC2 key pair name for SSH"
  type        = string
  default     = ""
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

# ── Secrets ───────────────────────────────────────────────────────────────────

variable "claude_api_key" {
  description = "Anthropic Claude API key"
  type        = string
  sensitive   = true
}

variable "keycloak_issuer_uri" {
  description = "Keycloak realm issuer URI"
  type        = string
}

variable "stripe_secret_key" {
  description = "Stripe secret key"
  type        = string
  sensitive   = true
  default     = "PLACEHOLDER"
}

variable "stripe_webhook_secret" {
  description = "Stripe webhook secret"
  type        = string
  sensitive   = true
  default     = "PLACEHOLDER"
}

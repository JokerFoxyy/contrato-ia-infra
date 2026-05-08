variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_url" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "claude_api_key" {
  type      = string
  sensitive = true
  default   = "PLACEHOLDER"
}

variable "keycloak_issuer_uri" {
  type    = string
  default = "PLACEHOLDER"
}

variable "stripe_secret_key" {
  type      = string
  sensitive = true
  default   = "PLACEHOLDER"
}

variable "stripe_webhook_secret" {
  type      = string
  sensitive = true
  default   = "PLACEHOLDER"
}

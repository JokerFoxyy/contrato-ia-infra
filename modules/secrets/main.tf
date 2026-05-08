################################################################################
# AWS Secrets Manager — Application secrets
################################################################################

resource "aws_secretsmanager_secret" "app" {
  name        = "${var.project}/${var.environment}/app-secrets"
  description = "Application secrets for ${var.project} ${var.environment}"

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id

  secret_string = jsonencode({
    DB_URL              = var.db_url
    DB_USERNAME         = var.db_username
    DB_PASSWORD         = var.db_password
    CLAUDE_API_KEY      = var.claude_api_key
    KEYCLOAK_ISSUER_URI = var.keycloak_issuer_uri
    STRIPE_SECRET_KEY   = var.stripe_secret_key
    STRIPE_WEBHOOK_SECRET = var.stripe_webhook_secret
  })
}

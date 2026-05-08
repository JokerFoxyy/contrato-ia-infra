################################################################################
# RDS PostgreSQL — Free Tier eligible (db.t3.micro)
################################################################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project}-${var.environment}-db"

  engine               = "postgres"
  engine_version       = "16.4"
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  vpc_security_group_ids = [var.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  # Economico: sem Multi-AZ em staging
  multi_az = var.multi_az

  # Backup
  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Snapshot final ao destruir
  skip_final_snapshot       = var.environment == "staging"
  final_snapshot_identifier = var.environment == "production" ? "${var.project}-${var.environment}-final-snapshot" : null
  deletion_protection       = var.environment == "production"

  # Performance Insights (free tier: 7 days retention)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Logging
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Auto minor version upgrades
  auto_minor_version_upgrade = true

  tags = {
    Name        = "${var.project}-${var.environment}-postgres"
    Environment = var.environment
    Project     = var.project
  }
}

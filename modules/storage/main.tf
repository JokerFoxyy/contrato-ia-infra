################################################################################
# S3 Bucket — Document storage (PDF/DOCX)
################################################################################

resource "aws_s3_bucket" "documents" {
  bucket = "${var.project}-${var.environment}-docs"

  tags = {
    Name        = "${var.project}-${var.environment}-docs"
    Environment = var.environment
    Project     = var.project
  }
}

# Versionamento para auditoria e recuperação
resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia server-side (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Bloquear acesso público
resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle — mover para IA após 90 dias, expirar após 365
resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    id     = "archive-old-documents"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "cleanup-soft-deleted"
    status = "Enabled"

    filter {
      tag {
        key   = "deleted"
        value = "true"
      }
    }

    expiration {
      days = 30
    }
  }
}

# CORS para presigned URLs
resource "aws_s3_bucket_cors_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT"]
    allowed_origins = var.cors_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

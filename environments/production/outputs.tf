output "backend_public_ip" {
  description = "Backend EC2 public IP (Elastic IP)"
  value       = module.compute.public_ip
}

output "database_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.database.endpoint
}

output "database_jdbc_url" {
  description = "JDBC connection URL"
  value       = module.database.jdbc_url
  sensitive   = true
}

output "s3_bucket_name" {
  description = "S3 documents bucket name"
  value       = module.storage.bucket_name
}

output "sqs_generation_queue_url" {
  description = "SQS generation queue URL"
  value       = module.queue.generation_queue_url
}

output "sqs_dlq_url" {
  description = "SQS DLQ URL"
  value       = module.queue.dlq_queue_url
}

output "secrets_arn" {
  description = "Secrets Manager ARN"
  value       = module.secrets.secret_arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = module.compute.cloudwatch_log_group_name
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the EC2 instance"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = ""
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN for IAM policy"
  type        = string
}

variable "sqs_queue_arns" {
  description = "SQS queue ARNs for IAM policy"
  type        = list(string)
}

variable "secrets_arn" {
  description = "Secrets Manager secret ARN"
  type        = string
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  type        = string
  default     = "/contrato-ia/backend"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

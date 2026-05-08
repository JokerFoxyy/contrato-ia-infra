output "generation_queue_url" {
  description = "SQS generation queue URL"
  value       = aws_sqs_queue.generation.url
}

output "generation_queue_arn" {
  description = "SQS generation queue ARN"
  value       = aws_sqs_queue.generation.arn
}

output "dlq_queue_url" {
  description = "SQS DLQ URL"
  value       = aws_sqs_queue.generation_dlq.url
}

output "dlq_queue_arn" {
  description = "SQS DLQ ARN"
  value       = aws_sqs_queue.generation_dlq.arn
}

output "all_queue_arns" {
  description = "All SQS queue ARNs (for IAM policy)"
  value       = [aws_sqs_queue.generation.arn, aws_sqs_queue.generation_dlq.arn]
}

################################################################################
# SQS FIFO Queue — Async document generation + DLQ
################################################################################

# Dead Letter Queue
resource "aws_sqs_queue" "generation_dlq" {
  name                        = "${var.project}-${var.environment}-generation-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 1209600 # 14 days

  tags = {
    Name        = "${var.project}-${var.environment}-generation-dlq"
    Environment = var.environment
    Project     = var.project
  }
}

# Main Queue
resource "aws_sqs_queue" "generation" {
  name                        = "${var.project}-${var.environment}-generation.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 120
  message_retention_seconds   = 86400  # 1 day
  receive_wait_time_seconds   = 5      # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.generation_dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "${var.project}-${var.environment}-generation"
    Environment = var.environment
    Project     = var.project
  }
}

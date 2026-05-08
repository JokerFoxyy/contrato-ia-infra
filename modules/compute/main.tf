################################################################################
# EC2 Instance — Docker host for backend container
################################################################################

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for EC2 (ECR pull, CloudWatch, S3, SQS, Secrets Manager)
resource "aws_iam_role" "ec2" {
  name = "${var.project}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy" "ec2_permissions" {
  name = "${var.project}-${var.environment}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRPull"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObjectTagging",
          "s3:GetObjectTagging",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = var.sqs_queue_arns
      },
      {
        Sid    = "SecretsManager"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_arn
      },
      {
        Sid    = "CodeDeployS3"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.codedeploy_bucket}",
          "arn:aws:s3:::${var.codedeploy_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ──────────────────────────────────────────────────────────────────────────────
# EC2 Instance
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  key_name               = var.key_pair_name

  user_data = templatefile("${path.module}/../../scripts/user-data.sh", {
    aws_region     = var.aws_region
    environment    = var.environment
    project        = var.project
    log_group_name = var.cloudwatch_log_group_name
  })

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens   = "required" # IMDSv2 only (security best practice)
    http_endpoint = "enabled"
  }

  tags = {
    Name        = "${var.project}-${var.environment}-backend"
    Environment = var.environment
    Project     = var.project
  }
}

# Elastic IP for stable public address
resource "aws_eip" "backend" {
  instance = aws_instance.backend.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project}-${var.environment}-eip"
    Environment = var.environment
  }
}

# ──────────────────────────────────────────────────────────────────────────────
# CloudWatch Log Group
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "backend" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.log_retention_days

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

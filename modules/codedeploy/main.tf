################################################################################
# AWS CodeDeploy — Automated deployment to EC2 (free for EC2)
################################################################################

# IAM Role for CodeDeploy service
resource "aws_iam_role" "codedeploy" {
  name = "${var.project}-${var.environment}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
    }]
  })

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# CodeDeploy Application
resource "aws_codedeploy_app" "backend" {
  name             = "${var.project}-${var.environment}-backend"
  compute_platform = "Server"

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Deployment Group — finds EC2 by tags
resource "aws_codedeploy_deployment_group" "backend" {
  app_name              = aws_codedeploy_app.backend.name
  deployment_group_name = "${var.project}-${var.environment}-backend-dg"
  service_role_arn      = aws_iam_role.codedeploy.arn

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  # Find EC2 instances by tags (no Instance ID needed)
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Project"
      value = var.project
      type  = "KEY_AND_VALUE"
    }

    ec2_tag_filter {
      key   = "Environment"
      value = var.environment
      type  = "KEY_AND_VALUE"
    }
  }

  # Auto rollback on failure
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

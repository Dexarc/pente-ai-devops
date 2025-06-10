# KMS Keys

# KMS Key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "${var.project_name}-${var.environment}-rds-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.environment}-rds-key"
  target_key_id = aws_kms_key.rds.id
}

# KMS Key for S3 encryption
resource "aws_kms_key" "s3" {
  description             = "${var.project_name}-${var.environment}-s3-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.environment}-s3-key"
  target_key_id = aws_kms_key.s3.id
}

# KMS Key for ElastiCache encryption (if supported and enabled)
# Note: ElastiCache encryption at rest uses KMS, but the key is often managed by AWS,
# or you can specify a CMK. Here we'll create one for explicit control.
resource "aws_kms_key" "elasticache" {
  description             = "${var.project_name}-${var.environment}-elasticache-key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_kms_alias" "elasticache" {
  name          = "alias/${var.project_name}-${var.environment}-elasticache-key"
  target_key_id = aws_kms_key.elasticache.id
}


# IAM Roles

# IAM Role for ECS Task Execution (for Fargate to pull ECR images, send logs to CloudWatch)
resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.project_name}-${var.environment}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Tasks (your application's permissions, e.g., SSM Parameter Store, S3 access)
resource "aws_iam_role" "ecs_task" {
  name               = "${var.project_name}-${var.environment}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Example: Policy to allow access to SSM Parameter Store for application config
resource "aws_iam_role_policy" "ecs_task_ssm_access" {
  name   = "${var.project_name}-${var.environment}-ecs-task-ssm-access"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_task_ssm_policy.json
}

data "aws_iam_policy_document" "ecs_task_ssm_policy" {
  statement {
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath"
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
    ]
  }
}

# Data source for current AWS region and account ID, used for ARN construction
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
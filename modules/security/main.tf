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

  statement {
    actions = [
      "kms:Decrypt"
    ]
    # Grant permission on the specific KMS key used for RDS (aws_kms_key.rds)
    resources = [
      aws_kms_key.rds.arn # Reference the ARN of the RDS KMS key whihch encrypts the ssm db credentials
    ]
  }
}

# S3 bucket for AWS Config logs
resource "aws_s3_bucket" "config_bucket" {
  bucket = "${var.project_name}-${var.environment}-aws-config-logs-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags
}

# Separate resource for versioning (required for newer AWS provider)
resource "aws_s3_bucket_versioning" "config_bucket_versioning" {
  bucket = aws_s3_bucket.config_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Separate resource for server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_encryption" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "config_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.config_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for AWS Config
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = data.aws_iam_policy_document.config_bucket_policy.json
}

data "aws_iam_policy_document" "config_bucket_policy" {
  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.config_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.config_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.config_bucket.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# IAM role for AWS Config
resource "aws_iam_role" "config_recorder_role" {
  name = "${var.project_name}-${var.environment}-config-recorder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach the correct AWS managed policy for Config
resource "aws_iam_role_policy_attachment" "config_recorder_policy_attachment" {
  role       = aws_iam_role.config_recorder_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Configuration recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config_recorder_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_s3_bucket_policy.config_bucket_policy]
}

# Delivery channel
resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-config-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.id

  depends_on = [
    aws_config_configuration_recorder.main,
    aws_s3_bucket_policy.config_bucket_policy
  ]
}

# Enable the configuration recorder
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [
    aws_config_delivery_channel.main,
    aws_config_configuration_recorder.main,
  ]
}

# --- AWS GuardDuty Detector ---
resource "aws_guardduty_detector" "main" {
  enable = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-guardduty-detector"
  })
}

# --- AWS Config Rules ---

# 1. Ensure Security Groups do not allow unrestricted incoming TCP traffic to common ports
#    This rule checks for security groups that allow unrestricted incoming TCP traffic to specified ports.
# --- AWS Config Rules ---

# 1. Ensure Security Groups do not allow unrestricted incoming traffic
resource "aws_config_config_rule" "restricted_ports" {
  name        = "${var.project_name}-${var.environment}-sg-no-ingress-from-anywhere"
  description = "Checks if security groups allow unrestricted incoming traffic on ports."
  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }
  tags = var.tags
}

# 2. Ensure S3 buckets have server-side encryption enabled
resource "aws_config_config_rule" "s3_bucket_encrypted" {
  name        = "${var.project_name}-${var.environment}-s3-bucket-encrypted"
  description = "Checks if Amazon S3 buckets are encrypted with server-side encryption."
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }
  tags = var.tags
}

# 3. Ensure RDS instances are encrypted
resource "aws_config_config_rule" "rds_instance_encrypted" {
  name        = "${var.project_name}-${var.environment}-rds-instance-encrypted"
  description = "Checks whether storage encryption is enabled for your RDS DB instance."
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  tags = var.tags
}

# Data source for current AWS region and account ID, used for ARN construction
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
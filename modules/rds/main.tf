# modules/rds_db/main.tf

# IMPORTANT: The aws_db_subnet_group is created by the networking module.
# No need to define it here.

# Generate a strong random password for the database
resource "random_password" "db_master_password" {
  length         = 32
  special        = true
  override_special = "!#$%^&*()-_=+.?[]{}<>" # Valid special characters for RDS
  min_lower      = 1
  min_upper      = 1
  min_numeric    = 1
  min_special    = 1
}

# Store the master username in SSM Parameter Store
resource "aws_ssm_parameter" "db_username" {
  name        = "/${var.project_name}/${var.environment}/rds/username"
  description = "RDS Master Username for ${var.project_name}-${var.environment}"
  type        = "String"
  value       = var.db_master_username_value
  tier        = "Standard"

  tags = var.tags
}

# Store the generated master password in SSM Parameter Store as SecureString
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/${var.environment}/rds/password"
  description = "RDS Master Password for ${var.project_name}-${var.environment}"
  type        = "SecureString"
  value       = random_password.db_master_password.result # Use the generated password
  tier        = "Standard"

  tags = var.tags
}


# RDS DB Parameter Group
resource "aws_db_parameter_group" "main" {
  family = "postgres17"
  # It's good to end name_prefix with a hyphen, so Terraform adds a clean suffix
  name_prefix   = "${var.project_name}-${var.environment}-db-params-"

  parameter {
    name  = "log_statement"
    value = "all"
    apply_method = "immediate"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
    apply_method = "immediate"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-params"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Database Engine Configuration
  engine               = "postgres"
  engine_version       = "17.4"
  instance_class       = var.db_instance_class
  parameter_group_name = aws_db_parameter_group.main.name

  # Storage Configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  storage_encrypted     = true
  kms_key_id           = var.kms_rds_key_arn

  # Database Configuration
  db_name  = var.db_name
  username = aws_ssm_parameter.db_username.value
  password = aws_ssm_parameter.db_password.value
  port     = 5432

  # Networking
  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = var.db_subnet_group_name
  multi_az               = true
  publicly_accessible    = false

  # Backup Configuration
  backup_retention_period   = 7
  backup_window            = "03:00-04:00"
  maintenance_window       = "sun:04:00-sun:05:00"
  auto_minor_version_upgrade = true
  skip_final_snapshot      = true
  deletion_protection      = false

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Enhanced Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Logging
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db"
  })

  # Apply changes immediately (for non-production environments)
  apply_immediately = var.apply_immediately

  lifecycle {
    ignore_changes = [
      password, # Ignore password changes to avoid unnecessary updates
    ]
  }

  depends_on = [
    aws_db_parameter_group.main,
    aws_iam_role.rds_enhanced_monitoring
  ]
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach the AWS managed policy for RDS Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# # CloudWatch Log Group for PostgreSQL logs
# resource "aws_cloudwatch_log_group" "postgresql" {
#   name              = "/aws/rds/instance/${aws_db_instance.main.identifier}/postgresql"
#   retention_in_days = var.log_retention_days

#   tags = var.tags
# }

# RDS Read Replica (optional, for high availability)
resource "aws_db_instance" "read_replica" {
  count = var.create_read_replica ? 1 : 0

  identifier = "${var.project_name}-${var.environment}-db-replica"

  # Read replica configuration
  replicate_source_db = aws_db_instance.main.identifier
  instance_class      = var.replica_instance_class != null ? var.replica_instance_class : var.db_instance_class

  # Override settings for replica
  publicly_accessible    = false
  auto_minor_version_upgrade = true
  skip_final_snapshot    = true

  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 7

  # Enhanced Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-replica"
    Type = "read-replica"
  })

  lifecycle {
    ignore_changes = [
      password,
    ]
  }

  depends_on = [aws_db_instance.main]
}
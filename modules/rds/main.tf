# modules/rds_db/main.tf

# IMPORTANT: The aws_db_subnet_group is created by the VPC module.
# No need to define it here.

# Generate a strong random password for the database
resource "random_password" "db_master_password" {
  length         = 32
  special        = true
  override_special = "!@#$%^&*()-_=+" # Customize if needed
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


# RDS PostgreSQL Instance - Using Official Module
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.12.0"
  identifier = "${var.project_name}-${var.environment}-db"

  # Database Engine Configuration
  engine               = "postgres"
  engine_version       = "15.5"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = var.db_instance_class

  # Storage Configuration
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"

  # Credentials - RDS module will use these to create the DB user
  # The application will retrieve them from SSM at runtime.
  username = aws_ssm_parameter.db_username.value
  password = aws_ssm_parameter.db_password.value

  port = 5432

  # Networking
  vpc_security_group_ids = [var.db_security_group_id]
  db_subnet_group_name   = var.db_subnet_group_name
  multi_az               = true
  publicly_accessible    = false

  # Backup Configuration
  backup_retention_period = 7
  skip_final_snapshot     = true
  deletion_protection     = false

  # Encryption (KMS)
  storage_encrypted    = true
  kms_key_id           = var.kms_rds_key_arn

  tags = var.tags
  apply_immediately = true
}
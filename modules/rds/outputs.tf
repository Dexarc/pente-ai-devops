# =============================================================================
# outputs.tf
# =============================================================================

# Database Instance Outputs
output "db_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "RDS instance hosted zone ID"
  value       = aws_db_instance.main.hosted_zone_id
}

output "db_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "db_instance_name" {
  description = "RDS instance database name"
  value       = aws_db_instance.main.db_name
}

output "db_instance_username" {
  description = "RDS instance master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_instance_engine" {
  description = "RDS instance engine"
  value       = aws_db_instance.main.engine
}

output "db_instance_engine_version" {
  description = "RDS instance engine version"
  value       = aws_db_instance.main.engine_version
}

output "db_instance_class" {
  description = "RDS instance class"
  value       = aws_db_instance.main.instance_class
}

output "db_instance_status" {
  description = "RDS instance status"
  value       = aws_db_instance.main.status
}

# Read Replica Outputs (conditional)
output "db_replica_id" {
  description = "RDS read replica instance ID"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].id : null
}

output "db_replica_endpoint" {
  description = "RDS read replica endpoint"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].endpoint : null
}

output "db_replica_port" {
  description = "RDS read replica port"
  value       = var.create_read_replica ? aws_db_instance.read_replica[0].port : null
}

# Connection Information
output "db_connection_info" {
  description = "Database connection information"
  value       = local.db_connection_info
  sensitive   = true
}

output "db_replica_connection_info" {
  description = "Read replica connection information"
  value       = local.replica_connection_info
  sensitive   = true
}

# SSM Parameter Outputs
output "db_username_ssm_parameter_name" {
  description = "SSM parameter name for database username"
  value       = aws_ssm_parameter.db_username.name
}

output "db_password_ssm_parameter_name" {
  description = "SSM parameter name for database password"
  value       = aws_ssm_parameter.db_password.name
}

output "db_username_ssm_parameter_arn" {
  description = "SSM parameter ARN for database username"
  value       = aws_ssm_parameter.db_username.arn
}

output "db_password_ssm_parameter_arn" {
  description = "SSM parameter ARN for database password"
  value       = aws_ssm_parameter.db_password.arn
}

# Parameter Group
output "db_parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.main.name
}

output "db_parameter_group_arn" {
  description = "ARN of the DB parameter group"
  value       = aws_db_parameter_group.main.arn
}

# CloudWatch and Monitoring
output "db_cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for PostgreSQL logs"
  value       = aws_cloudwatch_log_group.postgresql.name
}

output "db_cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for PostgreSQL logs"
  value       = aws_cloudwatch_log_group.postgresql.arn
}

output "db_enhanced_monitoring_role_arn" {
  description = "ARN of the enhanced monitoring IAM role"
  value       = aws_iam_role.rds_enhanced_monitoring.arn
}

# Security
output "db_kms_key_id" {
  description = "KMS key ID used for RDS encryption"
  value       = aws_db_instance.main.kms_key_id
}
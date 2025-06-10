# modules/rds_db/outputs.tf

output "db_instance_address" {
  description = "The address of the RDS instance."
  value       = module.rds.db_instance_address
}

output "db_instance_port" {
  description = "The port of the RDS instance."
  value       = module.rds.db_instance_port
}

output "db_instance_endpoint" {
  description = "The DNS endpoint of the RDS instance."
  value       = module.rds.db_instance_endpoint
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance."
  value       = module.rds.db_instance_arn
}

output "db_username_ssm_param_name" {
  description = "The SSM Parameter Store name for the RDS master username."
  value       = aws_ssm_parameter.db_username.name
  sensitive   = true
}

output "db_password_ssm_param_name" {
  description = "The SSM Parameter Store name for the RDS master password."
  value       = aws_ssm_parameter.db_password.name
  sensitive   = true
}
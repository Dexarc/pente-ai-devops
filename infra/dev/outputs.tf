# Networking outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.networking.database_subnet_ids
}

# Database outputs
output "db_instance_endpoint" {
  description = "Connection endpoint for the RDS database"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.rds.db_instance_arn
}

output "db_instance_status" {
  description = "Status of the RDS instance"
  value       = module.rds.db_instance_status
}

# ElastiCache outputs
output "elasticache_replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = module.elasticache.redis_replication_group_id
}

output "elasticache_primary_endpoint_address" {
  description = "Primary endpoint address of the ElastiCache cluster"
  value       = module.elasticache.redis_primary_endpoint_address
}

# ECS outputs

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.ecs_service_name
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.ecs_service.ecs_task_definition_arn
}

# Load balancer outputs
output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = module.ecs_service.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the application load balancer"
  value       = module.ecs_service.alb_arn
}

# Security outputs
output "ecs_security_group_id" {
  description = "ID of the ECS service security group"
  value       = module.ecs_service.ecs_security_group_id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = module.networking.db_security_group_id
}

output "elasticache_security_group_id" {
  description = "ID of the ElastiCache security group"
  value       = module.networking.elasticache_security_group_id
}

# CloudWatch outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.ecs_service.cloudwatch_log_group_name
}

# Observability outputs
output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch Dashboard."
  value       = module.observability.dashboard_url # Assumes observability module outputs this
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic used for alerts."
  value       = module.observability.sns_topic_arn # Assumes observability module outputs this
}
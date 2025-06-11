# infra/dev/vars.tf (or infra/dev/variables.tf)

# Common project variables
variable "project_name" {
  description = "Name of the project for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
}

# Networking variables
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets."
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use."
  type        = list(string)
}

variable "networking_common_tags" {
  description = "A map of tags to add to networking resources."
  type        = map(string)
}

# RDS variables
variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
}

variable "db_name" {
  description = "Name of the database to create."
  type        = string
}

variable "apply_immediately" {
  description = "Apply changes immediately for database resources."
  type        = bool
}

variable "create_read_replica" {
  description = "Whether to create a read replica for the RDS instance."
  type        = bool
}

variable "replica_instance_class" {
  description = "RDS read replica instance class."
  type        = string
  # Note: null is a valid type-safe default for optional variables if not provided
  # For a "clean" vars.tf, it means it must be provided if create_read_replica is true.
  # If you always intend to set it, just remove the default line entirely.
}

# ElastiCache variables
variable "elasticache_node_type" {
  description = "ElastiCache node type."
  type        = string
}

variable "elasticache_num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the ElastiCache replication group."
  type        = number
}

variable "elasticache_engine_version" {
  description = "ElastiCache engine version."
  type        = string
}

variable "elasticache_snapshot_retention_limit" {
  description = "Number of days for which ElastiCache snapshots are retained."
  type        = number
}

variable "elasticache_maintenance_window" {
  description = "Weekly maintenance window for ElastiCache."
  type        = string
}

# ECS Service variables
variable "app_docker_image" {
  description = "Docker image URL for the application (e.g., ECR or Docker Hub URL)."
  type        = string
}

variable "app_container_port" {
  description = "Port on which the container listens."
  type        = number
}

variable "ecs_desired_count" {
  description = "Desired count of ECS tasks."
  type        = number
}

variable "ecs_task_cpu" {
  description = "CPU units for the ECS task (256 = 0.25 vCPU)."
  type        = string
}

variable "ecs_task_memory" {
  description = "Memory for the ECS task in MiB."
  type        = string
}

# CloudWatch logs
variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch."
  type        = number
}

variable "ecs_min_capacity" {
  description = "Minimum number of tasks for the ECS service."
  type        = number
}

variable "ecs_max_capacity" {
  description = "Maximum number of tasks for the ECS service."
  type        = number
}

variable "ecs_target_cpu_utilization_percent" {
  description = "Target CPU utilization percentage for ECS service auto-scaling."
  type        = number
}

variable "ecs_target_memory_utilization_percent" {
  description = "Target Memory utilization percentage for ECS service auto-scaling."
  type        = number
}

variable "enable_custom_metric_autoscaling" {
  description = "Flag to enable custom metric-based auto-scaling for ECS service."
  type        = bool
}

variable "custom_scaling_target_value" {
  description = "Target value for custom metric-based auto-scaling."
  type        = number
}

# Observability variables
variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications."
  type        = string
}

variable "ecs_cpu_alarm_threshold_percent" {
  description = "Threshold percentage for ECS CPU utilization alarm."
  type        = number
}

variable "ecs_memory_alarm_threshold_percent" {
  description = "Threshold percentage for ECS Memory utilization alarm."
  type        = number
}

variable "rds_cpu_alarm_threshold_percent" {
  description = "Threshold percentage for RDS CPU utilization alarm."
  type        = number
}

variable "rds_read_replica_lag_threshold" {
  description = "Threshold for RDS read replica lag in seconds."
  type        = number
}

variable "alb_5xx_error_rate_threshold_percent" {
  description = "Threshold percentage for ALB HTTP 5xx error rate alarm."
  type        = number
}

variable "lambda_code_zip_path" {
  description = "Path to the ZIP file containing the PII stripping Lambda function code (relative to terraform root)."
  type        = string
}
# Common project variables
variable "project_name" {
  description = "Name of the project for resource naming."
  type        = string
  default     = "pente"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

# Networking variables
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets."
  type        = list(string)
  default     = ["10.0.100.0/24", "10.0.200.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to use."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "networking_common_tags" {
  description = "A map of tags to add to networking resources."
  type        = map(string)
  default     = {}
}

# RDS variables
variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database to create."
  type        = string
  default     = "app_db"
}

variable "apply_immediately" {
  description = "Apply changes immediately for database resources."
  type        = bool
  default     = false
}

variable "create_read_replica" {
  description = "Whether to create a read replica for the RDS instance."
  type        = bool
  default     = true
}

variable "replica_instance_class" {
  description = "RDS read replica instance class."
  type        = string
  default     = null
}

# ElastiCache variables
variable "elasticache_node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the ElastiCache replication group."
  type        = number
  default     = 2
}

variable "elasticache_engine_version" {
  description = "ElastiCache engine version."
  type        = string
  default     = "7.0"
}

variable "elasticache_snapshot_retention_limit" {
  description = "Number of days for which ElastiCache snapshots are retained."
  type        = number
  default     = 1
}

variable "elasticache_maintenance_window" {
  description = "Weekly maintenance window for ElastiCache."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

# ECS Service variables
variable "app_docker_image" {
  description = "Docker image URL for the application (e.g., ECR or Docker Hub URL)."
  type        = string
  default     = "nginx:latest"
}

variable "app_container_port" {
  description = "Port on which the container listens."
  type        = number
  default     = 80
}

variable "ecs_desired_count" {
  description = "Desired count of ECS tasks."
  type        = number
  default     = 1
}

variable "ecs_task_cpu" {
  description = "CPU units for the ECS task (256 = 0.25 vCPU)."
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "Memory for the ECS task in MiB."
  type        = string
  default     = "512"
}

# CloudWatch logs
variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch."
  type        = number
  default     = 7
}

# Observability variables
variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications."
  type        = string
  default     = "sarenkumar86@gmail.com"
}

variable "ecs_cpu_alarm_threshold_percent" {
  description = "Threshold percentage for ECS CPU utilization alarm."
  type        = number
  default     = 80
}

variable "ecs_memory_alarm_threshold_percent" {
  description = "Threshold percentage for ECS Memory utilization alarm."
  type        = number
  default     = 80
}

variable "rds_cpu_alarm_threshold_percent" {
  description = "Threshold percentage for RDS CPU utilization alarm."
  type        = number
  default     = 70
}

variable "alb_5xx_error_rate_threshold_percent" {
  description = "Threshold percentage for ALB HTTP 5xx error rate alarm."
  type        = number
  default     = 5 # For > 5% error rate
}
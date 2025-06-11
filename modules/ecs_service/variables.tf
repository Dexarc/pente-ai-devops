# modules/ecs_web_service/variables.tf

variable "project_name" {
  description = "Name of the project for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources are deployed (used for CloudWatch Logs configuration)."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the ECS cluster and ALB will be deployed."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS Fargate tasks."
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "List of database subnet CIDR blocks for ECS task egress rules (for DB/Cache access)."
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "The ID or ARN of the ECS cluster where the service will run."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "docker_image" {
  description = "The Docker image URL for the ECS task (e.g., from ECR or Docker Hub)."
  type        = string
}

variable "container_port" {
  description = "The port your application inside the Docker container listens on."
  type        = number
  default     = 80 # Common default for web apps
}

variable "cpu" {
  description = "The CPU units for the Fargate task (e.g., 256, 512, 1024). Corresponds to 0.25, 0.5, 1 vCPU."
  type        = string
  default     = "256" # Smallest Fargate CPU for cost-effectiveness
}

variable "memory" {
  description = "The memory in MiB for the Fargate task (e.g., 512, 1024, 2048). Corresponds to 0.5, 1, 2 GB."
  type        = string
  default     = "512" # Smallest Fargate memory for cost-effectiveness
}

variable "health_check_path" {
  description = "The path for the ALB health check for the microservice (e.g., / or /health)."
  type        = string
  default     = "/"
}

variable "ecs_task_execution_role_arn" {
  description = "The ARN of the existing ECS Task Execution IAM Role."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "The ARN of the existing ECS Task IAM Role (for application permissions, e.g., SSM, S3)."
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs for the ECS service."
  type        = number
  default     = 7
}

variable "ecs_min_capacity" {
  description = "Minimum number of tasks for the ECS service."
  type        = number
  default     = 1 # Start with 1 task
}

variable "ecs_max_capacity" {
  description = "Maximum number of tasks for the ECS service."
  type        = number
  default     = 3 # Allow scaling up to 3 tasks
}

variable "ecs_target_cpu_utilization_percent" {
  description = "Target CPU utilization percentage for ECS service auto-scaling."
  type        = number
  default     = 70 # Scale up if CPU goes above 70%
}

variable "ecs_target_memory_utilization_percent" {
  description = "Target Memory utilization percentage for ECS service auto-scaling."
  type        = number
  default     = 60 # Scale up if Memory goes above 60%
}

variable "ecs_desired_count" {
  description = "Desired count of ECS tasks."
  type        = number
  default     = 1
}

# --- Database Connection Details ---
variable "db_endpoint_address" {
  description = "The endpoint address of the RDS PostgreSQL database."
  type        = string
}

variable "db_port" {
  description = "The port of the RDS PostgreSQL database."
  type        = number
}

variable "db_name" {
  description = "The name of the database within the RDS instance."
  type        = string
}

variable "db_username_ssm_param_name" {
  description = "The SSM Parameter Store name for the RDS master username."
  type        = string
}

variable "db_password_ssm_param_name" {
  description = "The SSM Parameter Store name for the RDS master password."
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "A map of tags to add to all resources created by this module."
  type        = map(string)
  default     = {}
}
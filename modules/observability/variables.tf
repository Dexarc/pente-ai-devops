# modules/observability/variables.tf

variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources are deployed."
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  type        = string
}

variable "ecs_service_name" {
  description = "The name of the ECS service."
  type        = string
}

variable "db_instance_identifier" {
  description = "The DB instance identifier for RDS."
  type        = string
}

variable "alb_arn" {
  description = "The ARN of the Application Load Balancer. Set to null if not using ALB."
  type        = string
  default     = null # Default to null if no ALB
}

variable "alert_email" {
  description = "Email address for receiving alarm notifications."
  type        = string
}

variable "ecs_cpu_alarm_threshold_percent" {
  description = "Threshold for ECS CPU utilization alarm."
  type        = number
  default     = 80
}

variable "ecs_memory_alarm_threshold_percent" {
  description = "Threshold for ECS Memory utilization alarm."
  type        = number
  default     = 80
}

variable "rds_cpu_alarm_threshold_percent" {
  description = "Threshold for RDS CPU utilization alarm."
  type        = number
  default     = 70
}

variable "rds_read_replica_lag_threshold" {
  description = "Threshold for RDS read replica lag in seconds. Only used if read replica is created."
  type        = number
  default     = 100
}

variable "alb_request_count_low_threshold" {
  description = "Threshold for ALB request count low alarm. Only used if ALB ARN is provided."
  type        = number
  default     = 10 # Example: less than 10 requests per minute
}

variable "tags" {
  description = "A map of tags to assign to resources."
  type        = map(string)
  default     = {}
}

variable "alb_5xx_error_rate_threshold_percent" {
  description = "Threshold percentage for ALB HTTP 5xx error rate alarm (e.g., 5 for 5%)."
  type        = number
  default     = 5
}

variable "create_read_replica" {
  description = "Flag to create a read replica for the RDS instance."
  type        = bool
  default     = true
}

variable "rds_read_replica_identifier" {
  description = "The DB instance identifier of the read replica (if created)."
  type        = string
  default     = null # Default to null if no replica is created
}

variable "lambda_code_zip_path" {
  description = "Path to the ZIP file containing the PII stripping Lambda function code."
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch Logs."
  type        = number
  default     = 30
}

variable "ecs_app_log_group_name" {
  description = "The name of the CloudWatch Log Group where ECS application logs are sent."
  type        = string
}

variable "create_alb_alarms" {
  description = "Flag to create ALB alarms. Set to true if ALB ARN is provided."
  type        = bool
  default     = true
}
# =============================================================================
# variables.tf
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "appdb"
}

variable "db_master_username_value" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "dbsqladmin"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "replica_instance_class" {
  description = "RDS read replica instance class (if different from main)"
  type        = string
  default     = null
}

variable "create_read_replica" {
  description = "Whether to create a read replica"
  type        = bool
  default     = false
}

variable "db_security_group_id" {
  description = "Security group ID for the RDS instance"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name of the database subnet group"
  type        = string
}

variable "kms_rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  type        = string
}

variable "apply_immediately" {
  description = "Apply changes immediately (use with caution in production)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log group retention period in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
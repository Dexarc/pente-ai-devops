# modules/rds_db/variables.tf

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "db_security_group_id" {
  description = "The ID of the security group to attach to the RDS instance."
  type        = string
}

variable "db_instance_class" {
  description = "The instance class for the RDS instance."
  type        = string
  default     = "db.t3.micro"
}
# NEW: Variable for the master username value
variable "db_master_username_value" {
  description = "The value for the RDS Master Username to be stored in SSM."
  type        = string
  default     = "admin"
}

variable "kms_rds_key_arn" {
  description = "ARN of the KMS key to use for RDS encryption."
  type        = string
}

variable "db_subnet_group_name" {
  description = "The name of the DB Subnet Group created by the VPC module."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
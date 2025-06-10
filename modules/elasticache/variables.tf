variable "project_name" {
  description = "Name of the project for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "elasticache_node_type" {
  description = "The instance type of the ElastiCache nodes (e.g., cache.t3.micro)."
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (nodes) in the replication group. 2 for primary + 1 replica."
  type        = number
  default     = 2
}

variable "engine_version" {
  description = "The Redis engine version (e.g., 7.0)."
  type        = string
  default     = "7.0"
}

variable "elasticache_subnet_group_name" {
  description = "The name of the ElastiCache subnet group."
  type        = string
}

variable "elasticache_security_group_id" {
  description = "The ID of the security group to associate with the ElastiCache cluster."
  type        = string
}

variable "kms_elasticache_key_arn" {
  description = "The ARN of the KMS key for at-rest encryption of ElastiCache."
  type        = string
}

variable "snapshot_retention_limit" {
  description = "The number of days for which ElastiCache snapshots are retained."
  type        = number
  default     = 1
}

variable "maintenance_window" {
  description = "The weekly maintenance window for ElastiCache (e.g., sun:05:00-sun:06:00)."
  type        = string
  default     = "sun:05:00-sun:06:00"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs for ElastiCache."
  type        = number
  default     = 7
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
# modules/elasticache_redis/variables.tf

variable "project_name" {
  description = "Name of the project for resource naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "elasticache_node_type" {
  description = "The instance type for the ElastiCache cluster."
  type        = string
  default     = "cache.t3.micro"
}

variable "elasticache_subnet_group_name" {
  description = "The name of the ElastiCache Subnet Group created by the VPC module."
  type        = string
}

variable "elasticache_security_group_id" {
  description = "The ID of the security group to attach to the ElastiCache cluster."
  type        = string
}

variable "kms_elasticache_key_arn" {
  description = "ARN of the KMS key to use for ElastiCache at-rest encryption."
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}
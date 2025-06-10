# modules/elasticache_redis/main.tf

module "redis" {
  source  = "terraform-aws-modules/elasticache/aws"
  version = "1.6.0"

  replication_group_id          = "${var.project_name}-${var.environment}-redis"
  description                   = "Redis cluster for ${var.project_name}-${var.environment}"
  engine                        = "redis"
  engine_version                = "7.0" # Stable Redis version
  port                          = 6379 # Default Redis port

  node_type = var.elasticache_node_type

  # Cluster size for replication (2 nodes for demonstrating a "cluster")
  num_cache_clusters         = 2
  automatic_failover_enabled = true

  # Subnet Group (provided by the VPC module)
  subnet_group_name = var.elasticache_subnet_group_name

  # Security Groups
  security_group_ids = [var.elasticache_security_group_id]

  # Encryption (KMS for at-rest, in-transit is default for Redis 6.0+)
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  kms_key_arn                = var.kms_elasticache_key_arn

  # Backup & Maintenance (minimal retention for cost savings)
  snapshot_retention_limit = 1 # 1 day for minimal cost
  maintenance_window       = "sun:05:00-sun:06:00"

  tags = var.tags
}
# NOTE: The aws_elasticache_subnet_group is created by the main VPC raw resources.
# Ensure 'var.elasticache_subnet_group_name' is correctly passed from there.

# --- ElastiCache Replication Group (Redis Cluster) ---
resource "aws_elasticache_replication_group" "main" {
  replication_group_id          = "${var.project_name}-${var.environment}-redis"
  description                   = "Redis cluster for ${var.project_name}-${var.environment}"
  engine                        = "redis"
  engine_version                = var.engine_version # Use variable for version flexibility
  port                          = 6379
  node_type = var.elasticache_node_type

  # num_cache_clusters: Total number of nodes in the cluster (primary + replicas)
  # For a simple replicated cluster (1 primary, 1 replica), this is 2.
  num_cache_clusters         = var.num_cache_clusters # Typically 2 for 1 primary, 1 replica
  automatic_failover_enabled = true

  subnet_group_name = var.elasticache_subnet_group_name
  security_group_ids = [var.elasticache_security_group_id]

  # Encryption
  transit_encryption_enabled = true
  at_rest_encryption_enabled = true
  # kms_key_arn in module maps to kms_key_id in raw resource
  kms_key_id                = var.kms_elasticache_key_arn

  # Backup & Maintenance
  snapshot_retention_limit = var.snapshot_retention_limit
  maintenance_window       = var.maintenance_window

  # CloudWatch Log Exports
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_logs.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redis"
  })
}

# CloudWatch Log Group for Redis Logs 
resource "aws_cloudwatch_log_group" "redis_logs" {
  name              = "/aws/elasticache/redis/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}
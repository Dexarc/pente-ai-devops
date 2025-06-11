# --- ElastiCache Redis Outputs ---
output "redis_replication_group_id" {
  description = "The ID of the ElastiCache Redis replication group."
  value       = aws_elasticache_replication_group.main.replication_group_id
}

output "redis_primary_endpoint_address" {
  description = "The primary endpoint address of the Redis replication group."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_port" {
  description = "The port number of the Redis replication group."
  value       = aws_elasticache_replication_group.main.port
}
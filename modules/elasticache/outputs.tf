# modules/elasticache_redis/outputs.tf

output "redis_endpoint_address" {
  description = "The DNS address of the ElastiCache Redis cluster primary endpoint."
  value       = module.redis.replication_group_primary_endpoint_address
}

output "redis_cluster_arn" {
  description = "The ARN of the ElastiCache Redis replication group."
  value       = module.redis.replication_group_arn
}

output "redis_cluster_id" {
  description = "The ID of the ElastiCache Redis replication group."
  value       = module.redis.replication_group_id
}
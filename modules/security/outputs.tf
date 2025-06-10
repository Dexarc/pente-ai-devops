# outputs.tf

# KMS Key ARNs
output "kms_rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption."
  value       = aws_kms_key.rds.arn
}

output "kms_s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption."
  value       = aws_kms_key.s3.arn
}

output "kms_elasticache_key_arn" {
  description = "ARN of the KMS key for ElastiCache encryption."
  value       = aws_kms_key.elasticache.arn
}

# IAM Role ARNs
output "ecs_task_execution_role_arn" {
  description = "ARN of the IAM role for ECS Task Execution."
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the IAM role for ECS Tasks (application)."
  value       = aws_iam_role.ecs_task.arn
}
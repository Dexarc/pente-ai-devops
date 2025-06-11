# modules/ecs_web_service/outputs.tf

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.application_lb.dns_name
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer."
  value       = aws_lb.application_lb.arn
}

output "ecs_service_name" {
  description = "The name of the ECS Service."
  value       = aws_ecs_service.app_service.name
}

output "ecs_service_arn" {
  description = "The ARN of the ECS Service."
  value       = aws_ecs_service.app_service.id
}

output "ecs_task_definition_arn" {
  description = "The ARN of the ECS Task Definition."
  value       = aws_ecs_task_definition.app_task_definition.arn
}

output "ecs_security_group_id" {
  description = "The ID of the ECS Service security group."
  value       = aws_security_group.ecs_task_sg.id
}

output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch Log Group for ECS Task logs."
  value       = aws_cloudwatch_log_group.ecs_app_log_group.name
}
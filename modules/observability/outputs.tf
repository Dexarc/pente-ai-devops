# modules/observability/outputs.tf

output "sns_topic_arn" {
  description = "The ARN of the SNS topic used for alerts."
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "URL of the CloudWatch Dashboard."
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}
# modules/observability/main.tf

# --- SNS Topic for Alerts ---
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email # Email address for notifications
  # NOTE: You MUST confirm this subscription via email after first terraform apply!
}

# --- CloudWatch Alarms ---

# ECS Service CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = var.ecs_cpu_alarm_threshold_percent
  alarm_description   = "ECS Service CPU utilization is too high"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# ECS Service Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-ecs-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.ecs_memory_alarm_threshold_percent
  alarm_description   = "ECS Service Memory utilization is too high"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# RDS CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.rds_cpu_alarm_threshold_percent
  alarm_description   = "RDS Instance CPU utilization is too high"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# ALB HTTP 5xx Error Rate Alarm (Requirement)
resource "aws_cloudwatch_metric_alarm" "alb_5xx_error_rate_high" {
  count = var.alb_arn != null ? 1 : 0 # Only create if ALB ARN is provided

  alarm_name          = "${var.project_name}-${var.environment}-alb-5xx-error-rate-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = var.alb_5xx_error_rate_threshold_percent
  alarm_description   = "ALB HTTP 5xx error rate is too high (over ${var.alb_5xx_error_rate_threshold_percent}%)"

  metric_query {
    id = "m1"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = "300"
      stat        = "Sum"
      dimensions = {
        LoadBalancer = split("/", var.alb_arn)[1]
      }
    }
    return_data = false
  }

  metric_query {
    id = "m2"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = "300"
      stat        = "Sum"
      dimensions = {
        LoadBalancer = split("/", var.alb_arn)[1]
      }
    }
    return_data = false
  }

  metric_query {
    id          = "e1"
    expression  = "(m1 / m2) * 100"
    label       = "5XX Error Rate"
    return_data = true
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# RDS Replica Lag Alarm (Conditional)
# This alarm will trigger if the replica falls behind the primary by more than 100 milliseconds.
resource "aws_cloudwatch_metric_alarm" "rds_replica_lag_high" {
  count = var.create_read_replica ? 1 : 0 # Only create if a replica is configured to be created

  alarm_name          = "${var.project_name}-${var.environment}-rds-replica-lag-high"
  comparison_operator = "GreaterThanThreshold" # Alarm when lag is GREATER THAN 100ms
  evaluation_periods  = "2"                    # Evaluate over 2 consecutive periods
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = "300"                  # Every 5 minutes
  statistic           = "Average"
  threshold           = 100                    # 100 milliseconds
  alarm_description   = "RDS Read Replica lag is too high (over 100ms)"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier # The identifier of the primary DB instance
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = local.all_widgets
  })
}
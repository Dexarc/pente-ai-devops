# modules/observability/main.tf
data "aws_caller_identity" "current" {}

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

# --- PII Stripping Lambda Resources ---

# 1. IAM Role for Lambda Function
resource "aws_iam_role" "pii_stripper_lambda_role" {
  name = "${var.project_name}-${var.environment}-pii-stripper-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# 2. IAM Policy for Lambda to Read/Write Logs
resource "aws_iam_policy" "pii_stripper_lambda_policy" {
  name        = "${var.project_name}-${var.environment}-pii-stripper-lambda-policy"
  description = "IAM policy for Lambda to read source logs, write sanitized logs."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*" # Consider scoping this down to specific log group ARNs for production
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pii_stripper_lambda_policy_attach" {
  role       = aws_iam_role.pii_stripper_lambda_role.name
  policy_arn = aws_iam_policy.pii_stripper_lambda_policy.arn
}

# 3. New Log Group for Sanitized Logs
resource "aws_cloudwatch_log_group" "sanitized_app_logs" {
  name              = "/ecs/${var.project_name}-${var.environment}-app-sanitized"
  retention_in_days = var.log_retention_days # Use the same retention as main logs

  tags = var.tags
}

# 4. Lambda Function Resource
resource "aws_lambda_function" "pii_stripper" {
  function_name = "${var.project_name}-${var.environment}-pii-stripper"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  role          = aws_iam_role.pii_stripper_lambda_role.arn
  timeout       = 30
  memory_size   = 128

  filename         = var.lambda_code_zip_path
  source_code_hash = filebase64sha256(var.lambda_code_zip_path)

  environment {
    variables = {
      SANITIZED_LOG_GROUP_NAME = aws_cloudwatch_log_group.sanitized_app_logs.name
      #   AWS_REGION               = var.aws_region # AWS region is automatically set by Lambda
    }
  }

  tags = var.tags
}

# 5. Permission for CloudWatch Logs to Invoke Lambda
resource "aws_lambda_permission" "allow_cloudwatch_logs" {
  statement_id  = "AllowExecutionFromCloudWatchLogs"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pii_stripper.function_name
  principal     = "logs.${var.aws_region}.amazonaws.com"
  # Source ARN must be the original application log group
  # The test document mentions "Centralize application logs in CloudWatch Logs" 
  source_arn = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-${var.environment}-app:*"

  depends_on = [
    aws_lambda_function.pii_stripper
  ]
}

# 6. CloudWatch Logs Subscription Filter 
# This links your main app log group to the PII stripping Lambda
resource "aws_cloudwatch_log_subscription_filter" "to_pii_stripper_lambda" {
  name            = "${var.project_name}-${var.environment}-pii-filter"
  log_group_name  = "/ecs/${var.project_name}-${var.environment}-app" # Original application log group
  destination_arn = aws_lambda_function.pii_stripper.arn
  filter_pattern  = "" # An empty filter pattern sends ALL log events.

  depends_on = [
    aws_lambda_permission.allow_cloudwatch_logs
  ]
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
  count = var.create_alb_alarms ? 1 : 0 # Only create if ALB ARN is provided

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
  period              = "300" # Every 5 minutes
  statistic           = "Average"
  threshold           = var.rds_read_replica_lag_threshold
  alarm_description   = "RDS Read Replica lag is too high (over 100ms)"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier # The identifier of the primary DB instance
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# Custom Metric Filter for Application Requests
resource "aws_cloudwatch_log_metric_filter" "app_requests_metric_filter" {
  name           = "${var.project_name}-${var.environment}-app-requests-filter"
  log_group_name = var.ecs_app_log_group_name # Raw logs group

  # This filter pattern matches any log line containing " - GET / - "
  # For Node.js application logs with custom middleware format:
  # Matches: "2025-06-11T14:14:35.000Z - GET / - 10.0.1.182"
  pattern = "GET"

  metric_transformation {
    name          = "Requests"         # Name of the custom metric
    namespace     = "Pente/AppMetrics" # Custom namespace for application metrics
    value         = "1"                # Increment by 1 for each match
    default_value = "0"                # Default value if no matches
    unit          = "Count"            # Unit of the metric
  }

}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = local.all_widgets
  })
}
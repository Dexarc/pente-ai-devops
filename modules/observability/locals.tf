# --- CloudWatch Dashboard ---
locals {
  base_widgets = [
    # ECS Service Metrics
    {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name],
          ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name]
        ]
        view    = "timeSeries"
        stacked = false
        region  = var.aws_region
        title   = "ECS Service Metrics"
        period  = 300
      }
    },
    # RDS Instance Metrics
    {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        metrics = [
          ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_identifier],
          ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.db_instance_identifier]
        ]
        view    = "timeSeries"
        stacked = false
        region  = var.aws_region
        title   = "RDS Instance Metrics"
        period  = 300
      }
    },
    # Application Logs
    {
        type   = "logs"
        x      = 0
        y      = 7
        width  = 24
        height = 8
        properties = {
        query  = "SOURCE '/ecs/${var.project_name}-${var.environment}-app' | fields @timestamp, @message | sort @timestamp desc | limit 20"
        region = var.aws_region
        title  = "Application Logs"
        }
    }
  ]

  alb_widget = var.alb_arn != null ? [
    {
      type   = "metric"
      x      = 0
      y      = 15
      width  = 24
      height = 6
      properties = {
        metrics = [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${split("/", var.alb_arn)[1]}/${split("/", var.alb_arn)[2]}/${split("/", var.alb_arn)[3]}"],
          ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${split("/", var.alb_arn)[1]}/${split("/", var.alb_arn)[2]}/${split("/", var.alb_arn)[3]}"],
          ["AWS/ApplicationELB", "TargetConnectionErrorCount", "LoadBalancer", "${split("/", var.alb_arn)[1]}/${split("/", var.alb_arn)[2]}/${split("/", var.alb_arn)[3]}"]
        ]
        view    = "timeSeries"
        stacked = false
        region  = var.aws_region
        title   = "ALB Metrics"
        period  = 300
      }
    }
  ] : []
  # Conditional RDS Replica Lag Widget
     rds_replica_widget_list = var.create_read_replica ? [
        {
          type   = "metric"
          x      = 0
          y      = 21 # Position below ALB or logs if ALB isn't there
          width  = 12
          height = 6
          properties = {
            metrics = [
              ["AWS/RDS", "ReplicaLag", "DBInstanceIdentifier", var.rds_read_replica_identifier]
            ]
            view       = "timeSeries"
            stacked    = false
            region     = var.aws_region
            title      = "RDS Replica Lag"
            period     = 300
          }
        }
      ] : []

  all_widgets = concat(local.base_widgets, local.alb_widget, local.rds_replica_widget_list)
}
# infra/dev/terraform.tfvars

# Common project variables
project_name = "pente"
environment  = "dev"
aws_region   = "us-east-1"
tags         = {}

# Networking variables
vpc_cidr_block         = "10.0.0.0/16"
public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.10.0/24", "10.0.20.0/24"]
database_subnet_cidrs  = ["10.0.100.0/24", "10.0.200.0/24"]
availability_zones     = ["us-east-1a", "us-east-1b"]
networking_common_tags = {}

# RDS variables
db_instance_class      = "db.t3.micro"
db_name                = "app_db"
apply_immediately      = false
create_read_replica    = true
replica_instance_class = null #same class as primary by default

# ElastiCache variables
elasticache_node_type                = "cache.t3.micro"
elasticache_num_cache_clusters       = 2
elasticache_engine_version           = "7.0"
elasticache_snapshot_retention_limit = 1
elasticache_maintenance_window       = "sun:05:00-sun:06:00"

# ECS Service variables
app_docker_image   = "nginx:latest"
app_container_port = 80
ecs_desired_count  = 1
ecs_task_cpu       = "256"
ecs_task_memory    = "512"

# ECS Auto Scaling variables (for auto-scaling policies)
ecs_min_capacity                      = 1
ecs_max_capacity                      = 3
ecs_target_cpu_utilization_percent    = 70
ecs_target_memory_utilization_percent = 60
enable_custom_metric_autoscaling      = true # Enable custom metric-based auto-scaling
custom_scaling_target_value           = 50   # Target value for custom metric auto-scaling

# CloudWatch logs
log_retention_days = 7

# Observability variables
alert_email                          = "sarenkumar86@gmail.com"
ecs_cpu_alarm_threshold_percent      = 80
ecs_memory_alarm_threshold_percent   = 80
rds_cpu_alarm_threshold_percent      = 70
rds_read_replica_lag_threshold       = 100 #in ms
alb_5xx_error_rate_threshold_percent = 5

# Lambda PII Stripper Path
lambda_code_zip_path = "../../infra/dev/lambda_code/pii_stripper.zip"
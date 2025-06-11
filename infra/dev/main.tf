# --- Data Sources (Used for constructing ARNs, etc.) ---
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# --- Shared ECS Cluster ----------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-ecs-cluster"
  tags = merge(local.common_tags, var.tags)
}

# --- Module Calls ---

# 1. Networking Module (VPC, Subnets, Gateways, Route Tables)
module "networking" {
  source = "../../modules/networking"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr_block
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  availability_zones    = var.availability_zones
  common_tags           = var.networking_common_tags
}

# 2. Security Module (KMS Keys, IAM Roles, SSM Parameters)
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  tags         = merge(local.common_tags, var.tags)
}

# 3. S3 Module (Application Buckets, Terraform State Bucket)
module "s3" {
  source = "../../modules/s3"

  project_name   = var.project_name
  environment    = var.environment
  kms_s3_key_arn = module.security.kms_s3_key_arn # Dependency on Security module
  tags           = merge(local.common_tags, var.tags)
}

# 4. RDS Module (PostgreSQL Database)
module "rds" {
  source = "../../modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  db_subnet_group_name   = module.networking.database_subnet_group_name # Dependency on Networking module
  db_security_group_id   = module.networking.db_security_group_id       # Dependency on Networking module
  db_instance_class      = var.db_instance_class
  db_name                = var.db_name
  kms_rds_key_arn        = module.security.kms_rds_key_arn # Dependency on Security module
  log_retention_days     = var.log_retention_days
  apply_immediately      = var.apply_immediately
  create_read_replica    = var.create_read_replica
  replica_instance_class = var.replica_instance_class
  tags                   = merge(local.common_tags, var.tags)
}

# 5. ElastiCache Module (Redis Cache)
module "elasticache" {
  source = "../../modules/elasticache"

  project_name                  = var.project_name
  environment                   = var.environment
  elasticache_subnet_group_name = module.networking.elasticache_subnet_group_name # Dependency on Networking module
  elasticache_security_group_id = module.networking.elasticache_security_group_id # Dependency on Networking module
  kms_elasticache_key_arn       = module.security.kms_elasticache_key_arn         # Dependency on Security module
  elasticache_node_type         = var.elasticache_node_type
  num_cache_clusters            = var.elasticache_num_cache_clusters
  engine_version                = var.elasticache_engine_version
  snapshot_retention_limit      = var.elasticache_snapshot_retention_limit
  maintenance_window            = var.elasticache_maintenance_window
  tags                          = merge(local.common_tags, var.tags)
}

# 6. ECS Service Module (ALB, Fargate Service, Task Definition, Security Groups)
module "ecs_service" {
  source = "../../modules/ecs_service"

  project_name          = var.project_name
  environment           = var.environment
  aws_region            = data.aws_region.current.name
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  database_subnet_cidrs = var.database_subnet_cidrs # For ECS task egress to DB
  ecs_cluster_id        = aws_ecs_cluster.main.id   # Reference the root-level ECS cluster
  ecs_cluster_name      = aws_ecs_cluster.main.name # Reference the root-level ECS cluster

  docker_image       = var.app_docker_image
  container_port     = var.app_container_port
  cpu                = var.ecs_task_cpu
  memory             = var.ecs_task_memory
  log_retention_days = var.log_retention_days

  ecs_min_capacity                      = var.ecs_min_capacity
  ecs_max_capacity                      = var.ecs_max_capacity
  ecs_target_cpu_utilization_percent    = var.ecs_target_cpu_utilization_percent
  ecs_target_memory_utilization_percent = var.ecs_target_memory_utilization_percent
  ecs_desired_count                     = var.ecs_desired_count

  custom_metric_filter_metric_name = module.observability.app_requests_metric_name
  custom_metric_filter_namespace   = module.observability.app_requests_metric_namespace
  custom_scaling_target_value      = var.custom_scaling_target_value

  # IAM Roles (from Security module)
  ecs_task_execution_role_arn = module.security.ecs_task_execution_role_arn
  ecs_task_role_arn           = module.security.ecs_task_role_arn

  # Database Connection Details (from RDS module outputs and Security module SSM)
  db_endpoint_address        = module.rds.db_instance_address
  db_port                    = module.rds.db_instance_port
  db_name                    = var.db_name
  db_username_ssm_param_name = module.rds.db_username_ssm_parameter_name
  db_password_ssm_param_name = module.rds.db_password_ssm_parameter_name

  tags = merge(local.common_tags, var.tags)
}

module "observability" {
  source = "../../modules/observability"

  project_name                = var.project_name
  environment                 = var.environment
  aws_region                  = data.aws_region.current.name
  ecs_cluster_name            = aws_ecs_cluster.main.name
  ecs_service_name            = module.ecs_service.ecs_service_name
  db_instance_identifier      = module.rds.db_instance_identifier # Assumes rds module outputs 'db_instance_identifier'
  alb_arn                     = module.ecs_service.alb_arn        # Assumes ecs_service module outputs 'alb_arn'
  rds_read_replica_identifier = module.rds.read_replica_identifier

  alert_email                          = var.alert_email
  ecs_cpu_alarm_threshold_percent      = var.ecs_cpu_alarm_threshold_percent
  ecs_memory_alarm_threshold_percent   = var.ecs_memory_alarm_threshold_percent
  rds_cpu_alarm_threshold_percent      = var.rds_cpu_alarm_threshold_percent
  alb_5xx_error_rate_threshold_percent = var.alb_5xx_error_rate_threshold_percent
  rds_read_replica_lag_threshold       = var.rds_read_replica_lag_threshold

  ecs_app_log_group_name = module.ecs_service.ecs_app_log_group_name

  lambda_code_zip_path = var.lambda_code_zip_path
  log_retention_days   = var.log_retention_days

  tags = merge(local.common_tags, var.tags)
}

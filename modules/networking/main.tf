module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${var.project_name}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs              = local.azs
  public_subnets   = var.public_subnet_cidrs
  private_subnets  = var.private_subnet_cidrs
  database_subnets = var.database_subnet_cidrs
  elasticache_subnets = var.database_subnet_cidrs

  # Enable internet gateway and NAT gateway
  create_igw = true

  enable_nat_gateway = true
  enable_vpn_gateway = true
  single_nat_gateway = true

  # DNS
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Database subnet group
  create_database_subnet_group = true
  database_subnet_group_name   = "${var.project_name}-${var.environment}-db-subnet-group"

  # Elasticache subnet group
  create_elasticache_subnet_group = true
  elasticache_subnet_group_name   = "${var.project_name}-${var.environment}-cache-subnet-group"

  # Network ACLs
  manage_default_network_acl = true
  default_network_acl_name   = "${var.project_name}-${var.environment}-default-nacl"
  
  # Custom Network ACL for database subnets (both db and cache remain in same subnet group)
  database_dedicated_network_acl = true

  # VPC Flow Logs
  enable_flow_log                      = var.enable_flow_logs
  create_flow_log_cloudwatch_log_group = var.enable_flow_logs
  create_flow_log_cloudwatch_iam_role  = var.enable_flow_logs
  flow_log_max_aggregation_interval    = var.flow_logs_retention_days


  # Database Network ACL rules - restrict to private subnets only
  database_inbound_acl_rules = [
    {
      rule_number = 100
      protocol    = "tcp" 
      rule_action = "allow"
      cidr_block  = var.vpc_cidr  # Use the entire VPC CIDR - 
      from_port   = 5432 #PostgreSQL default port
      to_port     = 5432
    },
    {
      rule_number = 110
      protocol    = "tcp"
      rule_action = "allow" 
      cidr_block  = var.vpc_cidr  # Use the entire VPC CIDR
      from_port   = 6379 #Redis/ ElastiCache default port
      to_port     = 6379
    },
    {
      rule_number = 120
      protocol    = "tcp"
      rule_action = "allow"
      cidr_block  = var.vpc_cidr  # Ephemeral ports for return traffic
      from_port   = 1024
      to_port     = 65535
    }
  ]

  # Tagging
  tags = local.common_tags
  
  vpc_tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }

  public_subnet_tags = {
    Type = "public"
    Tier = "public"
    Purpose = "load-balancer"  # For ALB/NLB
  }

  private_subnet_tags = {
    Type = "private"
    Tier = "application"
    Purpose = "ecs-fargate"  # For ECS Fargate tasks
  }

  database_subnet_tags = {
    Type = "private"
    Tier = "database"
  }

  elasticache_subnet_tags = {
    Type = "private"
    Tier = "cache"
  }

  igw_tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }

  nat_gateway_tags = {
    Name = "${var.project_name}-${var.environment}-nat-gateway"
  }

  nat_eip_tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }

}
# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}


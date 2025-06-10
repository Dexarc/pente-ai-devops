# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

# Subnet Outputs
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.vpc.database_subnets
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = var.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = var.private_subnet_cidrs
}

output "database_subnet_cidrs" {
  description = "List of CIDR blocks of database subnets"
  value       = var.database_subnet_cidrs
}

# Availability Zone Outputs
output "availability_zones" {
  description = "List of availability zones used"
  value       = local.azs
}

# Gateway Outputs
output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = module.vpc.igw_id
}

output "nat_gateway_ids" {
  description = "List of IDs of the NAT Gateways"
  value       = module.vpc.natgw_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_public_ips
}

# Route Table Outputs
output "public_route_table_ids" {
  description = "List of IDs of the public route tables"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "List of IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "database_route_table_ids" {
  description = "List of IDs of the database route tables"
  value       = module.vpc.database_route_table_ids
}

# Subnet Group Outputs
output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = module.vpc.database_subnet_group
}

output "elasticache_subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = module.vpc.database_subnet_group_name
}

output "elasticache_subnet_group_id" {
  description = "ID of the ElastiCache subnet group"
  value       = module.vpc.database_subnet_group
}

# VPC Flow Logs
output "vpc_flow_log_id" {
  description = "The ID of the Flow Log resource"
  value       = module.vpc.vpc_flow_log_id
}

# Useful for other modules
output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.vpc.default_security_group_id
}
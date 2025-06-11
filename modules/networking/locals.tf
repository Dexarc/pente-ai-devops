locals {
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      Module      = "networking"
      ManagedBy   = "Terraform"
    }
  )

  azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)


  #Creating maps for subnets

  public_subnet_map = {
    for idx, subnet in aws_subnet.public :
    local.azs[idx] => subnet.id
  }

  private_subnet_map = {
    for idx, subnet in aws_subnet.private :
    local.azs[idx] => subnet.id
  }

  database_subnet_map = {
    for idx, subnet in aws_subnet.database :
    local.azs[idx] => subnet.id
  }

}
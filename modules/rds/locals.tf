# =============================================================================
# locals.tf
# =============================================================================

locals {
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "rds"
    }
  )

  # Database connection information
  db_connection_info = {
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
    username = aws_db_instance.main.username
  }

  # Read replica connection info (if created)
  replica_connection_info = var.create_read_replica ? {
    endpoint = aws_db_instance.read_replica[0].endpoint
    port     = aws_db_instance.read_replica[0].port
    database = aws_db_instance.read_replica[0].db_name
  } : null
}

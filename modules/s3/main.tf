# main.tf

# S3 Bucket for Static Assets
module "static_assets_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.10.0"

  bucket_prefix = "${var.project_name}-${var.environment}-static-assets-"
  acl           = "private"

  # Enable Versioning 
  versioning = {
    enabled = true
  }

  # Server-side encryption with KMS, using the passed KMS key ARN 
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.kms_s3_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # Block all public access for security best practices
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = var.tags
}

# S3 Bucket for Terraform State
module "terraform_state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.10.0" 

  bucket = "${var.project_name}-${var.environment}-terraform-state"
  acl    = "private" # Terraform state should always be private

  # Enable Versioning for state file rollback 
  versioning = {
    enabled = true
  }

  # Server-side encryption with KMS, using the passed KMS key ARN 
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = var.kms_s3_key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # Block all public access - EXTREMELY important for Terraform state security
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  tags = var.tags

  # Optional: Lifecycle rule to manage old state versions
  # This helps manage storage costs by transitioning or expiring non-current versions.
  lifecycle_rule = [{
    id = "delete-old-noncurrent-versions"
    enabled = true
    noncurrent_version_expiration = {
      days = 90 # Expire non-current versions after 90 days
    }
    noncurrent_version_transition = [{
      days          = 30
      storage_class = "GLACIER_IR" # Or "STANDARD_IA"
    }]
  }]
}
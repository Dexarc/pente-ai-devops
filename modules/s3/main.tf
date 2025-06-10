# --- Random ID for Unique Bucket Name Suffix (mimics module's bucket_prefix behavior) ---
resource "random_id" "static_assets_suffix" {
  byte_length = 8
}

# --------------------------------------------------S3 Bucket for Static Assets --------------------------------------------------------------------------------------
resource "aws_s3_bucket" "static_assets" {
  # Using bucket_prefix like functionality by appending a random suffix
  bucket = "${var.project_name}-${var.environment}-static-assets-${random_id.static_assets_suffix.hex}"

  tags = merge(local.common_tags, var.tags, {
    Name = "${var.project_name}-${var.environment}-static-assets"
  })
}

# --- S3 Bucket ACL for Static Assets ---
# Setting ACL to private explicitly
resource "aws_s3_bucket_acl" "static_assets_acl" {
  bucket = aws_s3_bucket.static_assets.id
  acl    = "private"
}

# --- S3 Bucket Versioning for Static Assets ---
resource "aws_s3_bucket_versioning" "static_assets_versioning" {
  bucket = aws_s3_bucket.static_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- S3 Bucket Server-Side Encryption for Static Assets (with KMS) ---
resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets_sse" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_s3_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# --- S3 Bucket Public Access Block for Static Assets (CRITICAL for security) ---
resource "aws_s3_bucket_public_access_block" "static_assets_public_access_block" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------- S3 Bucket for Terraform State -----------------------------------------------
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-${var.environment}-terraform-state"

  tags = merge(local.common_tags, var.tags, {
    Name = "${var.project_name}-${var.environment}-terraform-state"
  })
}

# --- S3 Bucket ACL for Terraform State ---
# Setting ACL to private explicitly
resource "aws_s3_bucket_acl" "terraform_state_acl" {
  bucket = aws_s3_bucket.terraform_state.id
  acl    = "private"
}

# --- S3 Bucket Versioning for Terraform State ---
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --- S3 Bucket Server-Side Encryption for Terraform State (with KMS) ---
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_sse" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_s3_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# --- S3 Bucket Public Access Block for Terraform State (CRITICAL for security) ---
resource "aws_s3_bucket_public_access_block" "terraform_state_public_access_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- S3 Bucket Lifecycle Configuration for Terraform State ---
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_lifecycle" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "delete-old-noncurrent-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days          = 30
      storage_class = "GLACIER_IR"
    }
  }
}

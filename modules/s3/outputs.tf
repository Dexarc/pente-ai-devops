output "static_assets_bucket_id" {
  description = "The ID of the S3 bucket for static assets."
  value       = aws_s3_bucket.static_assets.id
}

# output "terraform_state_bucket_id" {
#   description = "The ID of the S3 bucket for Terraform state."
#   value       = aws_s3_bucket.terraform_state.id
# }
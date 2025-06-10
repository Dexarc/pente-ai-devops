# outputs.tf

output "static_assets_bucket_id" {
  description = "The ID (name) of the S3 bucket for static assets."
  value       = module.static_assets_bucket.s3_bucket_id
}

output "static_assets_bucket_arn" {
  description = "The ARN of the S3 bucket for static assets."
  value       = module.static_assets_bucket.s3_bucket_arn
}

output "terraform_state_bucket_id" {
  description = "The ID (name) of the S3 bucket for Terraform state."
  value       = module.terraform_state_bucket.s3_bucket_id
}

output "terraform_state_bucket_arn" {
  description = "The ARN of the S3 bucket for Terraform state."
  value       = module.terraform_state_bucket.s3_bucket_arn
}
output "app_storage_bucket_name" {
  description = "S3 bucket name for application storage"
  value       = aws_s3_bucket.app_storage.id
}

output "app_storage_bucket_arn" {
  description = "S3 bucket ARN for application storage"
  value       = aws_s3_bucket.app_storage.arn
}

output "app_storage_bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.app_storage.region
}

output "logs_bucket_name" {
  description = "S3 bucket name for logs"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "S3 bucket ARN for logs"
  value       = aws_s3_bucket.logs.arn
}

output "kms_key_id" {
  description = "KMS key ID for S3 encryption"
  value       = aws_kms_key.s3.id
}

output "kms_key_arn" {
  description = "KMS key ARN for S3 encryption"
  value       = aws_kms_key.s3.arn
}

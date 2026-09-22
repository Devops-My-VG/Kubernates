output "backend_repository_url" {
  description = "Backend ECR repository URL"
  value       = aws_ecr_repository.backend.repository_url
}

output "backend_repository_name" {
  description = "Backend ECR repository name"
  value       = aws_ecr_repository.backend.name
}

output "backend_repository_arn" {
  description = "Backend ECR repository ARN"
  value       = aws_ecr_repository.backend.arn
}

output "frontend_repository_url" {
  description = "Frontend ECR repository URL"
  value       = aws_ecr_repository.frontend.repository_url
}

output "frontend_repository_name" {
  description = "Frontend ECR repository name"
  value       = aws_ecr_repository.frontend.name
}

output "frontend_repository_arn" {
  description = "Frontend ECR repository ARN"
  value       = aws_ecr_repository.frontend.arn
}

output "ecr_registry_id" {
  description = "ECR registry ID (AWS account ID)"
  value       = aws_ecr_repository.backend.registry_id
}

output "kms_key_id" {
  description = "KMS key ID for ECR encryption"
  value       = aws_kms_key.ecr.id
}

output "kms_key_arn" {
  description = "KMS key ARN for ECR encryption"
  value       = aws_kms_key.ecr.arn
}

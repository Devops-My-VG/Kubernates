output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "Private subnet IDs (if enabled)"
  value       = var.enable_private_subnets ? aws_subnet.private[*].id : []
}

output "security_group_id" {
  value = aws_security_group.ecs_sg.id
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  value       = aws_security_group.ecs_sg.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS database"
  value       = aws_security_group.rds_sg.id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis cache"
  value       = aws_security_group.redis_sg.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID (if enabled)"
  value       = try(aws_nat_gateway.main[0].id, null)
}

output "nat_gateway_eip" {
  description = "Elastic IP for NAT Gateway (if enabled)"
  value       = try(aws_eip.nat[0].public_ip, null)
}

output "private_route_table_id" {
  description = "Private route table ID (if enabled)"
  value       = try(aws_route_table.private[0].id, null)
}

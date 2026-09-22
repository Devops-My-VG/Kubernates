output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_asg.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_asg.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.ecs_lt.id
}

output "launch_template_latest_version" {
  description = "Latest version number of the launch template"
  value       = aws_launch_template.ecs_lt.latest_version
}

output "instance_role_arn" {
  description = "ARN of the ECS instance role"
  value       = aws_iam_role.ecs_instance_role.arn
}

output "instance_profile_name" {
  description = "Name of the ECS instance profile"
  value       = aws_iam_instance_profile.ecs_instance_profile.name
}

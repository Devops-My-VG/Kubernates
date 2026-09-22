data "aws_ami" "al2_ecs_optimized" {
  most_recent = true

  owners = ["591542846629"] # Official Amazon Linux account

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

output "ecs_optimized_ami_id" {
  description = "Latest ECS-Optimized Amazon Linux 2 AMI ID"
  value       = data.aws_ami.al2_ecs_optimized.id
}

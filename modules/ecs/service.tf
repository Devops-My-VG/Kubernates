# Task Definition for HTTPD
resource "aws_ecs_task_definition" "httpd" {
  family                   = "${var.cluster_name}-httpd-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_instance_role.arn

  container_definitions = jsonencode([
    {
      name      = "httpd"
      image     = "httpd:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Allow HTTP access to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-alb-sg"
  }
}

# ALB
resource "aws_lb" "ecs_alb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnets

  tags = {
    Name = "${var.cluster_name}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "ecs_tg" {
  name     = "${var.cluster_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.cluster_name}-tg"
  }
}

# Listener
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# ECS Service
resource "aws_ecs_service" "httpd_service" {
  name            = "${var.cluster_name}-httpd-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.httpd.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "httpd"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.ecs_listener]

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = "${var.cluster_name}-httpd-service"
  }
}

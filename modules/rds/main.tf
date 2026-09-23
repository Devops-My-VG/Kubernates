# RDS PostgreSQL Database Module for Ecommerce Application

# DB Subnet Group (for Multi-AZ deployment)
resource "aws_db_subnet_group" "ecommerce" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = var.database_subnets

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-db-subnet-group"
    }
  )
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "ecommerce" {
  identifier     = "${var.cluster_name}-postgres-db"
  engine         = "postgres"
  engine_version = var.postgres_version
  instance_class = var.instance_class

  # Storage configuration
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # Database configuration
  db_name  = var.database_name
  username = var.master_username
  password = random_password.db_password.result
  port     = var.database_port

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.ecommerce.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false

  # Multi-AZ and backup configuration
  multi_az                = false
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"
  copy_tags_to_snapshot   = true

  # Performance and monitoring
  enabled_cloudwatch_logs_exports       = ["postgresql"]
  performance_insights_enabled          = false
  monitoring_interval                   = 0

  # Deletion protection
  skip_final_snapshot = true
  # final_snapshot_identifier = "${var.cluster_name}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-postgres-db"
    }
  )

  depends_on = [aws_iam_role_policy_attachment.rds_monitoring]
  lifecycle {
    ignore_changes = [monitoring_role_arn]
  }
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS database encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-rds-key"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.cluster_name}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# Remove Secrets Manager for password storage to reduce costs
# Password will be stored in plain text for Free Tier compatibility

# Random password for RDS master user
resource "random_password" "db_password" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.cluster_name}/rds/master-password"
  recovery_window_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-rds-password"
    }
  )
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.ecommerce.endpoint
    port     = var.database_port
    dbname   = var.database_name
  })
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.cluster_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-rds-monitoring-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Log Group for RDS
resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/aws/rds/instance/${var.cluster_name}-postgres-db"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-rds-logs"
    }
  )
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.cluster_name}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when RDS CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ecommerce.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-rds-cpu-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.cluster_name}-rds-storage-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  alarm_description   = "Alert when RDS storage is below 10GB"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ecommerce.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-rds-storage-alarm"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "rds_database_connections" {
  alarm_name          = "${var.cluster_name}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when database connections exceed 80"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.ecommerce.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-rds-connections-alarm"
    }
  )
}

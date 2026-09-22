terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  # Uncomment below to use S3 remote backend
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "ecs-cluster/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   use_lockfile   = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "ECS-Cluster"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

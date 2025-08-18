terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud { 
    organization = "tim-krebs-org" 
    workspaces { 
      name = "golftracker-analytics-dev" 
    } 
  } 
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  
  availability_zones = data.aws_availability_zones.available.names
  
  tags = var.tags
}

# RDS Module
module "rds" {
  source = "./modules/rds"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  tags = var.tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  environment  = var.environment
  
  tags = var.tags
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  
  tags = var.tags
}

# ECS Fargate Module
module "ecs" {
  source = "./modules/ecs"
  
  project_name = var.project_name
  environment  = var.environment
  
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  ecr_repository_url = module.ecr.repository_url
  target_group_arn   = module.alb.target_group_arn
  
  # Database configuration
  db_host     = module.rds.db_host
  db_port     = module.rds.db_port
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
  
  tags = var.tags
}

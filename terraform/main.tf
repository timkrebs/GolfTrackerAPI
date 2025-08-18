# Main Terraform Configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Local values
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  
  # Generate names based on project and environment
  cluster_name = var.ecs_cluster_name != "" ? var.ecs_cluster_name : "${var.project_name}-${var.environment}"
  service_name = var.ecs_service_name != "" ? var.ecs_service_name : "${var.project_name}-service-${var.environment}"
  
  # Common tags
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
  })
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  vpc_cidr          = var.vpc_cidr
  availability_zones = var.availability_zones
  
  tags = local.common_tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  environment  = var.environment
  
  tags = local.common_tags
}

# ALB Module
module "alb" {
  source = "./modules/alb"
  
  project_name    = var.project_name
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  certificate_arn = var.certificate_arn
  
  tags = local.common_tags
}

# ECS Module
module "ecs" {
  source = "./modules/ecs-fargate"
  
  project_name     = var.project_name
  environment      = var.environment
  cluster_name     = local.cluster_name
  service_name     = local.service_name
  
  # VPC Configuration
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  
  # Container Configuration
  container_image     = var.container_image
  container_port      = var.container_port
  task_cpu           = var.ecs_task_cpu
  task_memory        = var.ecs_task_memory
  desired_count      = var.ecs_desired_count
  
  # Load Balancer
  target_group_arn   = module.alb.target_group_arn
  
  # Environment Variables
  environment_variables = [
    {
      name  = "SUPABASE_URL"
      value = var.supabase_url
    },
    {
      name  = "SUPABASE_ANON_KEY"
      value = var.supabase_anon_key
    },
    {
      name  = "SUPABASE_SERVICE_ROLE_KEY"
      value = var.supabase_service_role_key
    },
    {
      name  = "DATABASE_URL"
      value = var.database_url
    },
    {
      name  = "PROJECT_NAME"
      value = "Golf Tracker Analytics API"
    },
    {
      name  = "API_V1_STR"
      value = "/api/v1"
    },
    {
      name  = "DEBUG"
      value = "false"
    },
    {
      name  = "HOST"
      value = "0.0.0.0"
    },
    {
      name  = "PORT"
      value = tostring(var.container_port)
    }
  ]
  
  tags = local.common_tags
  
  depends_on = [module.alb]
}

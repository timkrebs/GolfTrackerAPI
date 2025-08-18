# Development Environment Configuration
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "your-terraform-state-bucket-dev"
    key            = "golf-api/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

# Call the main module
module "golf_api" {
  source = "../.."
  
  # Environment Configuration
  environment = "dev"
  project_name = "golf-api"
  aws_region = var.aws_region
  
  # VPC Configuration
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  
  # ECS Configuration
  ecs_task_cpu = 256
  ecs_task_memory = 512
  ecs_desired_count = 1
  container_image = var.container_image
  
  # Database Configuration
  supabase_url = var.supabase_url
  supabase_anon_key = var.supabase_anon_key
  supabase_service_role_key = var.supabase_service_role_key
  database_url = var.database_url
  
  # SSL Certificate (optional for dev)
  certificate_arn = var.certificate_arn
  
  # Tags
  tags = {
    Environment = "development"
    Project     = "Golf API"
    Terraform   = "true"
    Owner       = "Development Team"
  }
}

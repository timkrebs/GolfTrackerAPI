terraform {
  required_version = ">= 1.0"

  cloud {
    organization = "golftracker-analytics"
    workspaces {
      name = "golftracker-infrastructure"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "golftracker-team"
    }
  }
}

# Note: Kubernetes and Helm providers are not configured here to avoid
# dependency issues during initial deployment. The Vault Secrets Operator
# will be installed using kubectl commands in a null_resource after the
# EKS cluster is created and accessible.

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  cluster_name = "${var.project_name}-${var.environment}-eks-cluster"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr              = var.vpc_cidr
  availability_zones    = data.aws_availability_zones.available.names
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = local.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "./modules/security"

  vpc_id              = module.vpc.vpc_id
  vpc_cidr            = var.vpc_cidr
  project_name        = var.project_name
  environment         = var.environment
  private_subnet_ids  = module.vpc.private_subnet_ids
  database_subnet_ids = module.vpc.database_subnet_ids

  tags = local.common_tags
}

# KMS Module
module "kms" {
  source = "./modules/kms"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  cluster_name    = local.cluster_name
  cluster_version = var.eks_cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnet_ids
  control_plane_subnet_ids = module.vpc.private_subnet_ids

  cluster_security_group_id = module.security_groups.eks_cluster_security_group_id
  node_security_group_id    = module.security_groups.eks_node_security_group_id

  kms_key_id = module.kms.eks_kms_key_id

  # Node Groups
  node_groups = var.eks_node_groups

  # Add-ons
  cluster_addons = var.eks_cluster_addons

  # Cost optimization
  enable_spot_instances = var.enable_spot_instances

  tags = local.common_tags
}

# HashiCorp Vault Module
module "vault" {
  source = "./modules/vault"

  project_name = var.project_name
  environment  = var.environment

  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_groups.vault_security_group_id
  kms_key_id        = module.kms.vault_kms_key_id

  instance_type = var.vault_instance_type

  # Backup configuration
  backup_bucket_name = module.s3.backup_bucket_name

  tags = local.common_tags
}

# S3 Module
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment

  kms_key_id = module.kms.s3_kms_key_id

  # Video storage configuration
  video_bucket_lifecycle_rules = var.s3_lifecycle_rules

  tags = local.common_tags
}

# RDS Module
module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  environment  = var.environment

  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  security_group_id   = module.security_groups.rds_security_group_id
  kms_key_id          = module.kms.rds_kms_key_id

  # Database configuration
  engine_version    = var.rds_engine_version
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_allocated_storage

  # Database credentials (stored in Vault)
  database_name = var.rds_database_name
  username      = var.rds_username

  # Backup and maintenance
  backup_retention_period = var.rds_backup_retention_period
  backup_window           = var.rds_backup_window
  maintenance_window      = var.rds_maintenance_window

  # Multi-AZ for production
  multi_az = var.environment == "production" ? true : false

  tags = local.common_tags
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"

  project_name = var.project_name
  environment  = var.environment

  # EKS cluster name for log groups
  cluster_name = module.eks.cluster_name

  # SNS topic for alerts
  alert_email = var.alert_email

  tags = local.common_tags
}

# Vault Secrets Operator Module
module "vault_secrets_operator" {
  source = "./modules/vault-secrets-operator"

  depends_on = [module.eks, module.vault]

  cluster_name = module.eks.cluster_name
  vault_url    = "http://${module.vault.private_ip}:8200"

  # Vault authentication
  vault_role = "golftracker-backend"

  tags = local.common_tags
}

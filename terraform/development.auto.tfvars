# Development Environment Configuration for GolfTracker Analytics

# Environment Settings
environment = "development"
aws_region  = "us-west-2"

# VPC Configuration
vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
database_subnet_cidrs = ["10.0.100.0/24", "10.0.200.0/24"]

# EKS Configuration - Minimal for development
eks_cluster_version   = "1.28"
enable_spot_instances = true

eks_node_groups = {
  general = {
    instance_types = ["t3.small", "t3.medium"]
    capacity_type  = "SPOT"
    min_size       = 1
    max_size       = 3
    desired_size   = 1
    disk_size      = 20
    labels = {
      role        = "general"
      environment = "development"
    }
    taints = []
  }
}

# Vault Configuration - Smaller instance for dev
vault_instance_type = "t3.micro"

# RDS Configuration - Minimal for development
rds_engine_version          = "15.4"
rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_backup_retention_period = 1 # Minimal backup retention for dev

# S3 Lifecycle Configuration - Faster transitions for dev
s3_lifecycle_rules = [
  {
    id     = "dev_video_lifecycle"
    status = "Enabled"
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 60
        storage_class = "GLACIER"
      }
    ]
    expiration = {
      days = 180 # Short retention for development
    }
  }
]

# Cost Optimization - Aggressive for development
auto_scaling_enabled = true
scheduled_scaling    = true
development_mode     = true

# Security - Same as production
enable_encryption = true
enable_logging    = true
enable_monitoring = false # Reduced monitoring for dev

# Monitoring
alert_email = "dev-alerts@golftracker.com"

# Development specific settings
eks_cluster_addons = {
  "vpc-cni" = {
    version = "v1.15.0-eksbuild.2"
  }
  "coredns" = {
    version = "v1.10.1-eksbuild.4"
  }
  "kube-proxy" = {
    version = "v1.28.1-eksbuild.1"
  }
}

# Network settings
enable_nat_gateway = true # Still needed for private subnets
enable_vpn_gateway = false

# Database settings
rds_database_name      = "golftracker_dev"
rds_username           = "golftracker_dev_admin"
rds_backup_window      = "03:00-04:00"
rds_maintenance_window = "sun:04:00-sun:05:00"
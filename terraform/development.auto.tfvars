# Development Environment Configuration for GolfTracker Analytics

# Environment Settings
environment = "production"
aws_region  = "us-west-2"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
database_subnet_cidrs = ["10.0.100.0/24", "10.0.200.0/24", "10.0.300.0/24"]

# EKS Configuration
eks_cluster_version = "1.28"
enable_spot_instances = true

eks_node_groups = {
  general = {
    instance_types = ["t3.medium", "t3.large"]
    capacity_type  = "ON_DEMAND"
    min_size      = 2
    max_size      = 10
    desired_size  = 3
    disk_size     = 50
    labels = {
      role = "general"
      environment = "production"
    }
    taints = []
  }
  spot = {
    instance_types = ["t3.medium", "t3.large", "t3.xlarge"]
    capacity_type  = "SPOT"
    min_size      = 0
    max_size      = 15
    desired_size  = 2
    disk_size     = 50
    labels = {
      role = "spot"
      environment = "production"
    }
    taints = [{
      key    = "spot"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
  }
  gpu = {
    instance_types = ["g4dn.xlarge"]
    capacity_type  = "SPOT"
    min_size      = 0
    max_size      = 5
    desired_size  = 0
    disk_size     = 100
    labels = {
      role = "gpu"
      workload = "ai-processing"
    }
    taints = [{
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NO_SCHEDULE"
    }]
  }
}

# Vault Configuration
vault_instance_type = "t3.medium"

# RDS Configuration
rds_engine_version = "15.4"
rds_instance_class = "db.t3.small"
rds_allocated_storage = 100
rds_backup_retention_period = 7

# S3 Lifecycle Configuration
s3_lifecycle_rules = [
  {
    id     = "video_lifecycle"
    status = "Enabled"
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      },
      {
        days          = 365
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    expiration = {
      days = 2555  # 7 years for compliance
    }
  }
]

# Cost Optimization
auto_scaling_enabled = true
scheduled_scaling = true

# Security
enable_encryption = true
enable_logging = true
enable_monitoring = true

# Monitoring
alert_email = "alerts@golftracker.com"

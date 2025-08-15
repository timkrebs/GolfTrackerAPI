output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = module.vpc.database_subnet_ids
}

# EKS Cluster Outputs
output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = module.eks.cluster_iam_role_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_version" {
  description = "The Kubernetes version for the EKS cluster"
  value       = module.eks.cluster_version
}

output "node_groups" {
  description = "EKS node groups"
  value       = module.eks.node_groups
}

# HashiCorp Vault Outputs
output "vault_instance_id" {
  description = "EC2 instance ID for HashiCorp Vault"
  value       = module.vault.instance_id
}

output "vault_public_ip" {
  description = "Public IP address of Vault instance"
  value       = module.vault.public_ip
}

output "vault_private_ip" {
  description = "Private IP address of Vault instance"
  value       = module.vault.private_ip
}

output "vault_security_group_id" {
  description = "Security group ID for Vault instance"
  value       = module.vault.security_group_id
}

output "vault_url" {
  description = "URL to access HashiCorp Vault"
  value       = "https://${module.vault.public_ip}:8200"
}

# RDS Outputs
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = module.rds.db_instance_id
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = module.rds.db_instance_arn
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = module.rds.db_instance_name
}

# S3 Outputs
output "video_storage_bucket_name" {
  description = "Name of the S3 bucket for video storage"
  value       = module.s3.video_bucket_name
}

output "video_storage_bucket_arn" {
  description = "ARN of the S3 bucket for video storage"
  value       = module.s3.video_bucket_arn
}

output "backup_bucket_name" {
  description = "Name of the S3 bucket for backups"
  value       = module.s3.backup_bucket_name
}

output "backup_bucket_arn" {
  description = "ARN of the S3 bucket for backups"
  value       = module.s3.backup_bucket_arn
}

# KMS Outputs
output "kms_key_ids" {
  description = "KMS key IDs for encryption"
  value = {
    eks   = module.kms.eks_kms_key_id
    rds   = module.kms.rds_kms_key_id
    s3    = module.kms.s3_kms_key_id
    vault = module.kms.vault_kms_key_id
  }
}

# CloudWatch Outputs
output "cloudwatch_log_groups" {
  description = "CloudWatch log groups"
  value       = module.cloudwatch.log_groups
}

output "cloudwatch_dashboard_url" {
  description = "URL to CloudWatch dashboard"
  value       = module.cloudwatch.dashboard_url
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = module.cloudwatch.sns_topic_arn
}

# Security Groups Outputs
output "security_group_ids" {
  description = "Security group IDs"
  value = {
    eks_cluster = module.security_groups.eks_cluster_security_group_id
    eks_node    = module.security_groups.eks_node_security_group_id
    rds         = module.security_groups.rds_security_group_id
    vault       = module.security_groups.vault_security_group_id
    alb         = module.security_groups.alb_security_group_id
  }
}

# Kubectl Configuration
output "kubectl_config" {
  description = "kubectl configuration command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# Connection Information
output "connection_info" {
  description = "Connection information for services"
  value = {
    eks_cluster = {
      name     = module.eks.cluster_name
      endpoint = module.eks.cluster_endpoint
      region   = var.aws_region
    }
    vault = {
      url        = "https://${module.vault.public_ip}:8200"
      private_ip = module.vault.private_ip
      instance_id = module.vault.instance_id
    }
    rds = {
      endpoint = module.rds.db_instance_endpoint
      port     = module.rds.db_instance_port
      database = module.rds.db_instance_name
    }
    s3 = {
      video_bucket  = module.s3.video_bucket_name
      backup_bucket = module.s3.backup_bucket_name
    }
  }
}

# Cost Information
output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    eks_cluster      = "~$73/month (control plane)"
    eks_nodes        = "~$60-300/month (depending on usage)"
    vault_ec2        = "~$25/month (t3.medium)"
    rds_instance     = "~$15/month (db.t3.micro)"
    nat_gateway      = "~$45/month"
    data_transfer    = "Variable based on usage"
    storage          = "Variable based on video storage"
    total_minimum    = "~$200/month (minimal usage)"
    total_production = "~$500-1000/month (production usage)"
  }
}

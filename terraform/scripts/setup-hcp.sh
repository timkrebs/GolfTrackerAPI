#!/bin/bash

# HCP Terraform Setup Script for GolfTracker Analytics
# This script helps configure HCP Terraform for automated deployments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏗️  HCP Terraform Setup for GolfTracker Analytics${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# Function to log steps
log_step() {
    echo -e "${BLUE}🔄 $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if terraform CLI is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform CLI is not installed${NC}"
    echo "Please install Terraform: https://www.terraform.io/downloads"
    exit 1
fi

# Check Terraform version
TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
log_info "Terraform version: $TERRAFORM_VERSION"

echo ""
echo -e "${YELLOW}📋 HCP Terraform Configuration${NC}"
echo -e "${YELLOW}==============================${NC}"
echo ""

# Collect configuration details
read -p "Enter your HCP Terraform organization name: " HCP_ORG
read -p "Enter workspace name [golftracker-infrastructure]: " HCP_WORKSPACE
HCP_WORKSPACE=${HCP_WORKSPACE:-golftracker-infrastructure}

read -p "Enter your AWS region [us-west-2]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-west-2}

read -p "Enter environment [production]: " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-production}

echo ""
log_step "Creating HCP Terraform configuration..."

# Create the main configuration with HCP backend
cat > main.tf << EOF
terraform {
  required_version = ">= 1.0"
  
  cloud {
    organization = "$HCP_ORG"
    workspaces {
      name = "$HCP_WORKSPACE"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.21"
    }
  }
}

# Include the main infrastructure configuration
module "infrastructure" {
  source = "./modules/main"
  
  # Pass variables to the module
  aws_region   = var.aws_region
  environment  = var.environment
  project_name = var.project_name
}
EOF

# Create variables file for HCP
cat > terraform.auto.tfvars << EOF
# HCP Terraform Auto Variables
aws_region   = "$AWS_REGION"
environment  = "$ENVIRONMENT"
project_name = "golftracker-analytics"
EOF

log_success "HCP Terraform configuration created"

echo ""
log_step "Logging into HCP Terraform..."

# Login to HCP Terraform
terraform login

log_step "Initializing Terraform with HCP backend..."
terraform init

log_success "HCP Terraform setup complete!"

echo ""
echo -e "${GREEN}🎉 HCP Terraform Configuration Complete!${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo -e "${BLUE}📊 Next Steps:${NC}"
echo ""
echo -e "1. ${YELLOW}Configure Environment Variables in HCP Terraform:${NC}"
echo -e "   Go to: https://app.terraform.io/app/$HCP_ORG/workspaces/$HCP_WORKSPACE/variables"
echo ""
echo -e "   ${BLUE}Add these Environment Variables (mark as sensitive):${NC}"
echo -e "   • AWS_ACCESS_KEY_ID"
echo -e "   • AWS_SECRET_ACCESS_KEY"
echo ""
echo -e "   ${BLUE}Add these Terraform Variables:${NC}"
echo -e "   • aws_region = \"$AWS_REGION\""
echo -e "   • environment = \"$ENVIRONMENT\""
echo -e "   • project_name = \"golftracker-analytics\""
echo -e "   • alert_email = \"your-email@domain.com\""
echo ""
echo -e "2. ${YELLOW}Configure VCS Integration:${NC}"
echo -e "   • Connect your Git repository"
echo -e "   • Enable automatic planning for pull requests"
echo -e "   • Set up auto-apply for main branch (optional)"
echo ""
echo -e "3. ${YELLOW}Set up Notifications:${NC}"
echo -e "   • Configure Slack/email notifications"
echo -e "   • Set up run notifications"
echo -e "   • Configure cost estimation alerts"
echo ""
echo -e "4. ${YELLOW}Deploy Infrastructure:${NC}"
echo -e "   • Push code to your repository"
echo -e "   • Review the plan in HCP Terraform"
echo -e "   • Apply the infrastructure"
echo ""
echo -e "${BLUE}🔧 HCP Terraform Features Enabled:${NC}"
echo -e "  ✅ Remote state management"
echo -e "  ✅ Team collaboration"
echo -e "  ✅ Policy as code (Sentinel)"
echo -e "  ✅ Cost estimation"
echo -e "  ✅ VCS integration"
echo -e "  ✅ Private module registry"
echo ""
echo -e "${BLUE}💡 Pro Tips:${NC}"
echo -e "  • Use cost estimation to predict infrastructure costs"
echo -e "  • Set up Sentinel policies for governance"
echo -e "  • Use workspaces for different environments"
echo -e "  • Enable notifications for team awareness"
echo ""
echo -e "${GREEN}Happy Infrastructure as Code! 🚀${NC}"

# Create a sample sentinel policy
log_step "Creating sample Sentinel policy..."
mkdir -p policies

cat > policies/cost-control.sentinel << 'EOF'
# Cost Control Policy for GolfTracker Analytics
# This policy ensures infrastructure costs stay within budget

import "tfplan/v2" as tfplan
import "decimal"

# Maximum monthly cost threshold (in USD)
cost_threshold = 1000

# Calculate estimated monthly cost
monthly_cost = decimal.new(tfplan.planned_values.outputs.estimated_monthly_cost.value.total_production)

# Main rule
main = rule {
    monthly_cost.lte(decimal.new(cost_threshold))
}

# Print cost information
print("Estimated monthly cost:", monthly_cost)
print("Cost threshold:", cost_threshold)

if monthly_cost.gt(decimal.new(cost_threshold)) {
    print("❌ Infrastructure cost exceeds budget threshold!")
} else {
    print("✅ Infrastructure cost is within budget")
}
EOF

cat > policies/security-requirements.sentinel << 'EOF'
# Security Requirements Policy
# Ensures all resources follow security best practices

import "tfplan/v2" as tfplan

# Ensure all S3 buckets have encryption
s3_buckets_encrypted = rule {
    all tfplan.resource_changes as _, rc {
        rc.type is not "aws_s3_bucket" or
        rc.change.after.server_side_encryption_configuration is not null
    }
}

# Ensure all EBS volumes are encrypted
ebs_volumes_encrypted = rule {
    all tfplan.resource_changes as _, rc {
        rc.type is not "aws_ebs_volume" or
        rc.change.after.encrypted is true
    }
}

# Main rule combining all security requirements
main = rule {
    s3_buckets_encrypted and
    ebs_volumes_encrypted
}
EOF

log_success "Sample Sentinel policies created in ./policies/"

echo ""
echo -e "${BLUE}📚 Additional Resources:${NC}"
echo -e "  • HCP Terraform Documentation: https://developer.hashicorp.com/terraform/cloud-docs"
echo -e "  • Sentinel Documentation: https://docs.hashicorp.com/sentinel"
echo -e "  • Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs"
echo ""

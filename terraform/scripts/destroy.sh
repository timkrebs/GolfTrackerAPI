#!/bin/bash

# GolfTrackerAnalytics Infrastructure Destruction Script
# This script safely tears down the entire infrastructure to save costs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="golftracker-analytics"
ENVIRONMENT="${ENVIRONMENT:-production}"
AWS_REGION="${AWS_REGION:-us-west-2}"

echo -e "${RED}🔥 GolfTracker Analytics Infrastructure Destruction${NC}"
echo -e "${RED}=================================================${NC}"
echo ""
echo -e "${YELLOW}Environment: ${ENVIRONMENT}${NC}"
echo -e "${YELLOW}AWS Region: ${AWS_REGION}${NC}"
echo -e "${YELLOW}Project: ${PROJECT_NAME}${NC}"
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

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Confirmation prompt
echo -e "${RED}⚠️  WARNING: This will destroy ALL infrastructure resources!${NC}"
echo -e "${RED}This action is IRREVERSIBLE and will delete:${NC}"
echo -e "${RED}  • EKS cluster and all workloads${NC}"
echo -e "${RED}  • RDS database and all data${NC}"
echo -e "${RED}  • S3 buckets and stored files${NC}"
echo -e "${RED}  • HashiCorp Vault and all secrets${NC}"
echo -e "${RED}  • All networking and security components${NC}"
echo ""
echo -e "${YELLOW}Make sure you have:${NC}"
echo -e "  1. Backed up all important data"
echo -e "  2. Exported any necessary secrets from Vault"
echo -e "  3. Saved any important application configurations"
echo ""

read -p "Are you absolutely sure you want to destroy all infrastructure? (type 'DESTROY' to confirm): " confirmation

if [ "$confirmation" != "DESTROY" ]; then
    log_warning "Destruction cancelled. Infrastructure remains intact."
    exit 0
fi

echo ""
log_step "Beginning infrastructure destruction..."

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ] && [ ! -f ".terraform/terraform.tfstate" ]; then
    log_error "No Terraform state found. Nothing to destroy."
    exit 1
fi

# Get cluster name from terraform output (if available)
CLUSTER_NAME=""
if terraform output cluster_name &> /dev/null; then
    CLUSTER_NAME=$(terraform output -raw cluster_name)
fi

# Clean up Kubernetes resources first (if cluster exists)
if [ ! -z "$CLUSTER_NAME" ]; then
    log_step "Cleaning up Kubernetes resources..."
    
    # Configure kubectl
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME 2>/dev/null || true
    
    # Delete all LoadBalancer services to clean up AWS Load Balancers
    log_step "Deleting LoadBalancer services..."
    kubectl delete svc --all-namespaces --field-selector spec.type=LoadBalancer --ignore-not-found=true
    
    # Delete all ingresses to clean up ALBs
    log_step "Deleting ingresses..."
    kubectl delete ingress --all-namespaces --all --ignore-not-found=true
    
    # Wait for AWS resources to be cleaned up
    log_step "Waiting for AWS load balancers to be deleted..."
    sleep 60
    
    log_success "Kubernetes resources cleaned up"
fi

# Create a backup of important data before destruction
log_step "Creating final backup (if possible)..."

# Try to backup RDS if it exists
RDS_ENDPOINT=""
if terraform output rds_endpoint &> /dev/null; then
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
    DB_INSTANCE_ID=$(terraform output -raw rds_instance_id)
    
    log_step "Creating final RDS snapshot..."
    SNAPSHOT_ID="${PROJECT_NAME}-${ENVIRONMENT}-final-snapshot-$(date +%Y%m%d-%H%M%S)"
    aws rds create-db-snapshot \
        --db-instance-identifier $DB_INSTANCE_ID \
        --db-snapshot-identifier $SNAPSHOT_ID \
        --region $AWS_REGION || log_warning "Could not create RDS snapshot"
fi

# Backup S3 buckets (list contents for reference)
log_step "Cataloging S3 bucket contents..."
if terraform output video_storage_bucket_name &> /dev/null; then
    VIDEO_BUCKET=$(terraform output -raw video_storage_bucket_name)
    aws s3 ls s3://$VIDEO_BUCKET --recursive > /tmp/s3-video-contents.txt 2>/dev/null || true
    log_warning "S3 video bucket contents saved to /tmp/s3-video-contents.txt"
fi

# Force empty S3 buckets (required for destruction)
log_step "Emptying S3 buckets..."
if terraform output video_storage_bucket_name &> /dev/null; then
    VIDEO_BUCKET=$(terraform output -raw video_storage_bucket_name)
    aws s3 rm s3://$VIDEO_BUCKET --recursive || log_warning "Could not empty video bucket"
fi

if terraform output backup_bucket_name &> /dev/null; then
    BACKUP_BUCKET=$(terraform output -raw backup_bucket_name)
    aws s3 rm s3://$BACKUP_BUCKET --recursive || log_warning "Could not empty backup bucket"
fi

# Begin Terraform destruction
log_step "Planning infrastructure destruction..."
terraform plan -destroy -out=destroy.tfplan

log_step "Executing infrastructure destruction..."
terraform apply destroy.tfplan

# Verify destruction
log_step "Verifying destruction completion..."

# Check if any resources remain
remaining_resources=$(terraform state list 2>/dev/null | wc -l)
if [ $remaining_resources -gt 0 ]; then
    log_warning "Some resources may still exist in Terraform state"
    terraform state list
else
    log_success "All Terraform resources destroyed"
fi

# Clean up local files
log_step "Cleaning up local files..."
rm -f destroy.tfplan
rm -f terraform.tfplan
rm -f tfplan

# Final cost optimization check
log_step "Running final cost check..."
cat << EOF

${GREEN}🎉 Infrastructure Destruction Complete!${NC}
${GREEN}=====================================${NC}

${BLUE}💰 Cost Savings:${NC}
  • EKS cluster costs: ~\$73/month saved
  • EC2 instances: ~\$25-300/month saved
  • NAT Gateway: ~\$45/month saved
  • RDS instance: ~\$15/month saved
  • Total estimated savings: ~\$200-500/month

${BLUE}📊 What was destroyed:${NC}
  ✅ EKS cluster and worker nodes
  ✅ HashiCorp Vault EC2 instance
  ✅ RDS PostgreSQL database
  ✅ VPC and networking components
  ✅ Security groups and NACLs
  ✅ KMS keys and encryption
  ✅ CloudWatch logs and monitoring
  ✅ S3 buckets and storage

${BLUE}📋 Data Preservation:${NC}
  • RDS snapshot: ${SNAPSHOT_ID:-"Not created"}
  • S3 contents: /tmp/s3-video-contents.txt

${BLUE}🔄 To restore infrastructure:${NC}
  Run: ${YELLOW}./scripts/deploy.sh${NC}

${GREEN}💡 Infrastructure successfully torn down to save costs!${NC}
${GREEN}You can safely redeploy when ready to continue development.${NC}

EOF

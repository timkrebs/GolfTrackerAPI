#!/bin/bash
# Deployment script for Golf API infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
SKIP_BUILD=false
SKIP_PUSH=false

# Function to print colored output
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -e, --environment ENVIRONMENT    Environment (dev, staging, prod) [default: dev]"
    echo "  -r, --region REGION             AWS region [default: us-east-1]"
    echo "  -s, --skip-build                Skip Docker build"
    echo "  -p, --skip-push                 Skip Docker push"
    echo "  -h, --help                      Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -p|--skip-push)
            SKIP_PUSH=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            print_error "Unknown option $1"
            usage
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
    exit 1
fi

print_message "Starting deployment for environment: $ENVIRONMENT"

# Check if required tools are installed
command -v aws >/dev/null 2>&1 || { print_error "AWS CLI is required but not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { print_error "Docker is required but not installed."; exit 1; }
command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed."; exit 1; }

# Set working directory to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

print_message "Project root: $PROJECT_ROOT"

# Check if .env file exists
if [[ ! -f ".env" ]]; then
    print_warning ".env file not found. Make sure to set environment variables."
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ $? -ne 0 ]]; then
    print_error "Failed to get AWS account ID. Make sure AWS CLI is configured."
    exit 1
fi

print_message "AWS Account ID: $AWS_ACCOUNT_ID"

# Set ECR repository URL
ECR_REPO="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/golf-api-$ENVIRONMENT"
IMAGE_TAG="latest"
FULL_IMAGE_NAME="$ECR_REPO:$IMAGE_TAG"

print_message "ECR Repository: $ECR_REPO"

# Step 1: Build Docker image (if not skipped)
if [[ "$SKIP_BUILD" == false ]]; then
    print_message "Building Docker image..."
    docker build -t golf-api:$IMAGE_TAG .
    if [[ $? -ne 0 ]]; then
        print_error "Docker build failed"
        exit 1
    fi
    
    # Tag for ECR
    docker tag golf-api:$IMAGE_TAG $FULL_IMAGE_NAME
    print_message "Docker image built and tagged: $FULL_IMAGE_NAME"
else
    print_warning "Skipping Docker build"
fi

# Step 2: Push to ECR (if not skipped)
if [[ "$SKIP_PUSH" == false ]]; then
    print_message "Logging in to ECR..."
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Check if ECR repository exists, create if not
    aws ecr describe-repositories --repository-names golf-api-$ENVIRONMENT --region $AWS_REGION >/dev/null 2>&1 || {
        print_message "Creating ECR repository..."
        aws ecr create-repository --repository-name golf-api-$ENVIRONMENT --region $AWS_REGION
    }
    
    print_message "Pushing Docker image to ECR..."
    docker push $FULL_IMAGE_NAME
    if [[ $? -ne 0 ]]; then
        print_error "Docker push failed"
        exit 1
    fi
    print_message "Docker image pushed successfully"
else
    print_warning "Skipping Docker push"
fi

# Step 3: Deploy infrastructure with Terraform
print_message "Deploying infrastructure with Terraform..."

cd "terraform/environments/$ENVIRONMENT"

# Initialize Terraform
print_message "Initializing Terraform..."
terraform init

# Create terraform.tfvars if it doesn't exist
if [[ ! -f "terraform.tfvars" ]]; then
    print_warning "terraform.tfvars not found. Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    print_warning "Please edit terraform.tfvars with your actual values before continuing."
    read -p "Press enter to continue after editing terraform.tfvars..."
fi

# Update container image in terraform.tfvars
print_message "Updating container image in terraform.tfvars..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|container_image = \".*\"|container_image = \"$FULL_IMAGE_NAME\"|" terraform.tfvars
else
    # Linux
    sed -i "s|container_image = \".*\"|container_image = \"$FULL_IMAGE_NAME\"|" terraform.tfvars
fi

# Plan
print_message "Running Terraform plan..."
terraform plan -out=tfplan

# Apply
print_message "Applying Terraform changes..."
terraform apply tfplan

if [[ $? -eq 0 ]]; then
    print_message "Deployment completed successfully!"
    
    # Get outputs
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "Not available")
    API_URL=$(terraform output -raw api_url 2>/dev/null || echo "Not available")
    
    echo
    print_message "Deployment Summary:"
    echo "  Environment: $ENVIRONMENT"
    echo "  AWS Region: $AWS_REGION"
    echo "  Image: $FULL_IMAGE_NAME"
    echo "  ALB DNS: $ALB_DNS"
    echo "  API URL: $API_URL"
    echo
    print_message "API Documentation will be available at: ${API_URL}/docs"
else
    print_error "Terraform apply failed"
    exit 1
fi

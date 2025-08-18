#!/bin/bash

# Golf Course API Deployment Script
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install it first."
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install it first."
    exit 1
fi

# Variables
PROJECT_NAME="golf-course-api"
ENVIRONMENT=${1:-dev}
AWS_REGION=${2:-us-east-1}

print_status "Starting deployment for environment: $ENVIRONMENT"
print_status "AWS Region: $AWS_REGION"

# Step 1: Initialize Terraform
print_status "Initializing Terraform..."
cd terraform
terraform init

# Step 2: Plan Terraform deployment
print_status "Planning Terraform deployment..."
terraform plan -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION"

# Ask for confirmation
read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled."
    exit 0
fi

# Step 3: Apply Terraform
print_status "Applying Terraform configuration..."
terraform apply -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION" -auto-approve

# Step 4: Get outputs
print_status "Getting deployment outputs..."
ECR_URL=$(terraform output -raw ecr_repository_url)
DB_ENDPOINT=$(terraform output -raw database_endpoint)
ALB_URL=$(terraform output -raw load_balancer_url)

print_success "Infrastructure deployed successfully!"
print_status "ECR Repository: $ECR_URL"
print_status "Database Endpoint: $DB_ENDPOINT"
print_status "Load Balancer URL: $ALB_URL"

# Step 5: Build and push Docker image
print_status "Building Docker image..."
cd ..
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URL

docker build -t $PROJECT_NAME-$ENVIRONMENT .
docker tag $PROJECT_NAME-$ENVIRONMENT:latest $ECR_URL:latest

print_status "Pushing Docker image to ECR..."
docker push $ECR_URL:latest

# Step 6: Update ECS service to use new image
print_status "Updating ECS service..."
aws ecs update-service \
    --cluster $PROJECT_NAME-$ENVIRONMENT-cluster \
    --service $PROJECT_NAME-$ENVIRONMENT-service \
    --force-new-deployment \
    --region $AWS_REGION

print_success "Deployment completed successfully!"
print_status "Your API will be available at: $ALB_URL"
print_status "API Documentation: $ALB_URL/docs"
print_warning "Note: It may take a few minutes for the service to be fully available."

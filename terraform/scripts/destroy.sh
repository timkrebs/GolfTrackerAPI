#!/bin/bash
# Destroy script for Golf API infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
FORCE=false

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
    echo "  -f, --force                      Skip confirmation prompt"
    echo "  -h, --help                       Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
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

print_warning "This will destroy ALL infrastructure for environment: $ENVIRONMENT"

# Confirmation prompt (unless forced)
if [[ "$FORCE" == false ]]; then
    echo
    print_warning "This action cannot be undone!"
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    if [[ "$confirm" != "yes" ]]; then
        print_message "Destruction cancelled."
        exit 0
    fi
fi

# Check if required tools are installed
command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed."; exit 1; }

# Set working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"

print_message "Working directory: $(pwd)"

# Check if terraform.tfvars exists
if [[ ! -f "terraform.tfvars" ]]; then
    print_error "terraform.tfvars not found. Cannot proceed with destruction."
    exit 1
fi

# Initialize Terraform
print_message "Initializing Terraform..."
terraform init

# Plan destruction
print_message "Planning destruction..."
terraform plan -destroy -out=destroy.tfplan

# Show what will be destroyed
print_warning "The following resources will be destroyed:"
terraform show destroy.tfplan

# Final confirmation for production
if [[ "$ENVIRONMENT" == "prod" && "$FORCE" == false ]]; then
    echo
    print_warning "You are about to destroy PRODUCTION infrastructure!"
    read -p "Type 'DESTROY PRODUCTION' to confirm: " prod_confirm
    if [[ "$prod_confirm" != "DESTROY PRODUCTION" ]]; then
        print_message "Production destruction cancelled."
        exit 0
    fi
fi

# Apply destruction
print_message "Destroying infrastructure..."
terraform apply destroy.tfplan

if [[ $? -eq 0 ]]; then
    print_message "Infrastructure destroyed successfully!"
    
    # Clean up plan file
    rm -f destroy.tfplan
    
    echo
    print_message "Destruction Summary:"
    echo "  Environment: $ENVIRONMENT"
    echo "  Status: Completed"
    echo
    print_warning "Note: ECR repositories may still contain images."
    print_warning "Use 'aws ecr list-images' and 'aws ecr batch-delete-image' to clean up if needed."
else
    print_error "Terraform destroy failed"
    exit 1
fi

#!/bin/bash

# Setup CI/CD for Golf Course API
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🚀 Setting up CI/CD for Golf Course API"
echo "======================================"

# Get AWS account ID
print_status "Getting AWS account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ $? -eq 0 ]]; then
    print_success "AWS Account ID: $AWS_ACCOUNT_ID"
else
    print_error "Failed to get AWS account ID. Please ensure AWS CLI is configured."
    exit 1
fi

# Instructions for GitHub setup
echo ""
print_status "GitHub Repository Setup Required:"
echo "=================================="
echo ""
echo "1. Create a new GitHub repository for this project"
echo "2. Push your code to the repository:"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo "   git branch -M main"
echo "   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
echo "   git push -u origin main"
echo ""

print_status "GitHub Secrets Configuration Required:"
echo "====================================="
echo ""
echo "Go to your GitHub repository → Settings → Secrets and variables → Actions"
echo "Add the following secrets:"
echo ""
echo "🔐 Required Secrets:"
echo "-------------------"
echo "AWS_ACCESS_KEY_ID       = Your AWS Access Key ID"
echo "AWS_SECRET_ACCESS_KEY   = Your AWS Secret Access Key"
echo "AWS_ACCOUNT_ID          = $AWS_ACCOUNT_ID"
echo "DB_PASSWORD             = Your database password (same as in terraform.tfvars)"
echo ""

print_warning "Optional (for Terraform Cloud):"
echo "TF_API_TOKEN            = Your Terraform Cloud API token"
echo ""

print_status "IAM Policy for GitHub Actions:"
echo "=============================="
echo ""
echo "Create an IAM user with the following policy for GitHub Actions:"
echo ""

cat << 'EOF'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer",
                "ecr:GetAuthorizationToken",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecs:UpdateService",
                "ecs:DescribeServices",
                "ecs:DescribeTasks",
                "ecs:ListTasks",
                "ecs:DescribeTaskDefinition"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elbv2:DescribeLoadBalancers"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams"
            ],
            "Resource": "*"
        }
    ]
}
EOF

echo ""
print_status "Testing Setup:"
echo "============="
echo ""
echo "After setting up GitHub secrets, you can test the pipeline by:"
echo "1. Making a commit to the 'develop' branch (deploys to dev environment)"
echo "2. Making a commit to the 'main' branch (deploys to prod environment)"
echo "3. Creating a pull request (runs tests and security scans)"
echo ""

print_status "Manual Deployment Commands:"
echo "=========================="
echo ""
echo "For manual deployments, you can use:"
echo ""
echo "# Deploy to development:"
echo "git checkout develop"
echo "git push origin develop"
echo ""
echo "# Deploy to production:"
echo "git checkout main"
echo "git push origin main"
echo ""

print_status "Infrastructure Deployment:"
echo "========================="
echo ""
echo "To deploy infrastructure changes:"
echo "1. Push changes to terraform/ directory on main branch (auto-plans)"
echo "2. Use GitHub Actions manual trigger for apply/destroy"
echo "3. Go to Actions → Deploy Infrastructure → Run workflow"
echo ""

print_success "CI/CD setup instructions complete!"
echo ""
print_warning "Remember to:"
echo "• Configure GitHub secrets"
echo "• Create IAM user with proper permissions"
echo "• Push code to GitHub repository"
echo "• Test the pipeline with a sample commit"
echo ""
echo "📚 For more details, see CICD_GUIDE.md"

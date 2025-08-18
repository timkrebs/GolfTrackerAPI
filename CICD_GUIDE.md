# CI/CD Pipeline Guide

This guide explains how to set up and use the automated CI/CD pipeline for the Golf Course API.

## 🚀 Overview

The CI/CD pipeline provides:

- **Automated Testing**: Runs tests on every pull request
- **Security Scanning**: Vulnerability scanning with Trivy
- **Multi-Environment Deployment**: Separate dev and prod environments
- **Infrastructure as Code**: Terraform deployment automation
- **Docker Building**: Automatic containerization and ECR deployment
- **Health Checks**: Post-deployment verification

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   GitHub        │    │   GitHub     │    │   AWS           │
│   Repository    │───▶│   Actions    │───▶│   Infrastructure│
│                 │    │   Runners    │    │                 │
└─────────────────┘    └──────────────┘    └─────────────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │   Deployment Flow    │
                    │                      │
                    │  1. Test             │
                    │  2. Build Docker     │
                    │  3. Push to ECR      │
                    │  4. Deploy to ECS    │
                    │  5. Health Check     │
                    └──────────────────────┘
```

## 📋 Prerequisites

### 1. AWS Account Setup
- AWS CLI configured with appropriate credentials
- IAM user with necessary permissions (see IAM Policy below)
- Existing AWS infrastructure (VPC, ECS, RDS, etc.)

### 2. GitHub Repository
- Code pushed to GitHub repository
- GitHub Actions enabled
- Required secrets configured

## 🔧 Setup Instructions

### Step 1: Run Setup Script
```bash
./scripts/setup-cicd.sh
```

### Step 2: Configure GitHub Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key for GitHub Actions | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `abc123...` |
| `AWS_ACCOUNT_ID` | Your AWS Account ID | `123456789012` |
| `DB_PASSWORD` | Database password (same as terraform.tfvars) | `SecurePassword123!` |
| `TF_API_TOKEN` | Terraform Cloud API token (optional) | `xxx.atlasv1.xxx` |

### Step 3: IAM Policy

Create an IAM user with this policy for GitHub Actions:

```json
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
```

## 🔄 Workflow Triggers

### Application Deployment (`.github/workflows/deploy.yml`)

| Trigger | Environment | Action |
|---------|-------------|---------|
| Push to `develop` branch | Development | Deploy to dev environment |
| Push to `main` branch | Production | Deploy to prod environment |
| Pull Request to `main` | - | Run tests + security scan |

### Infrastructure Deployment (`.github/workflows/infrastructure.yml`)

| Trigger | Action |
|---------|---------|
| Push to `main` with `terraform/**` changes | Run terraform plan |
| Manual workflow dispatch | Plan/Apply/Destroy infrastructure |

## 🚀 Deployment Process

### Automatic Deployment

1. **Push to develop branch**:
   ```bash
   git checkout develop
   git add .
   git commit -m "Add new feature"
   git push origin develop
   ```

2. **Push to main branch**:
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```

### Manual Infrastructure Deployment

1. Go to GitHub **Actions** tab
2. Select **Deploy Infrastructure** workflow
3. Click **Run workflow**
4. Choose action (plan/apply/destroy) and environment
5. Click **Run workflow**

## 🧪 Testing

### Local Testing
```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest tests/

# Test specific file
pytest tests/test_api.py -v
```

### CI Testing
Tests run automatically on:
- Every pull request
- Every push to main/develop branches

## 📊 Monitoring Deployment

### GitHub Actions
- View workflow runs in the **Actions** tab
- Check logs for each step
- Monitor deployment status

### AWS Console
- **ECS**: Check service status and task health
- **CloudWatch**: View application logs
- **Load Balancer**: Monitor target group health

### Health Checks
The pipeline automatically runs health checks:
```bash
# Manual health check
curl https://your-alb-url.amazonaws.com/health
```

## 🔍 Troubleshooting

### Common Issues

1. **AWS Credentials Invalid**
   - Check GitHub secrets are correct
   - Verify IAM user permissions
   - Ensure AWS account ID is correct

2. **Docker Build Fails**
   - Check Dockerfile syntax
   - Verify requirements.txt is up to date
   - Check for missing dependencies

3. **ECS Deployment Fails**
   - Check ECS service exists
   - Verify cluster name matches
   - Check security groups allow traffic

4. **Health Check Fails**
   - Verify application starts correctly
   - Check database connectivity
   - Verify load balancer configuration

### Debug Commands

```bash
# Check ECS service status
aws ecs describe-services \
  --cluster golf-course-api-dev-cluster \
  --services golf-course-api-dev-service

# Check ECS tasks
aws ecs list-tasks \
  --cluster golf-course-api-dev-cluster

# View CloudWatch logs
aws logs tail /ecs/golf-course-api-dev --follow
```

## 🔄 Rollback Strategy

### Automatic Rollback
- ECS automatically maintains previous task definitions
- Failed deployments can be rolled back manually

### Manual Rollback
```bash
# List task definitions
aws ecs list-task-definitions \
  --family-prefix golf-course-api-dev

# Update service to previous version
aws ecs update-service \
  --cluster golf-course-api-dev-cluster \
  --service golf-course-api-dev-service \
  --task-definition golf-course-api-dev:PREVIOUS_REVISION
```

## 📈 Environment Management

### Development Environment
- **Branch**: `develop`
- **URL**: Check GitHub Actions output
- **Database**: Separate dev RDS instance
- **Purpose**: Testing and development

### Production Environment
- **Branch**: `main`
- **URL**: Check GitHub Actions output
- **Database**: Production RDS instance
- **Purpose**: Live application

## 🔐 Security Features

### Security Scanning
- **Trivy**: Vulnerability scanning on pull requests
- **SARIF**: Results uploaded to GitHub Security tab
- **Dependencies**: Automated dependency scanning

### Access Control
- **IAM**: Minimal required permissions
- **Secrets**: Stored securely in GitHub
- **VPC**: Private subnets for database and applications

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 🚨 Emergency Procedures

### Stop All Deployments
1. Go to GitHub Actions
2. Cancel running workflows
3. Disable Actions temporarily if needed

### Emergency Rollback
```bash
# Scale down service
aws ecs update-service \
  --cluster golf-course-api-dev-cluster \
  --service golf-course-api-dev-service \
  --desired-count 0

# Scale back up with previous image
aws ecs update-service \
  --cluster golf-course-api-dev-cluster \
  --service golf-course-api-dev-service \
  --desired-count 1 \
  --task-definition golf-course-api-dev:PREVIOUS_REVISION
```

## 📞 Support

For issues with the CI/CD pipeline:
1. Check GitHub Actions logs
2. Review AWS CloudWatch logs
3. Verify AWS service status
4. Check this documentation
5. Contact your DevOps team

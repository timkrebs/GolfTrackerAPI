# AWS Deployment Guide

This guide will help you deploy the Golf Course API to AWS using Terraform and ECS Fargate.

## Architecture Overview

The deployment creates the following AWS resources:

- **VPC**: Virtual Private Cloud with public and private subnets
- **RDS**: PostgreSQL database in private subnets
- **ECR**: Elastic Container Registry for Docker images
- **ECS**: Fargate cluster running the API containers
- **ALB**: Application Load Balancer for traffic distribution
- **CloudWatch**: Logging and monitoring

## Prerequisites

### 1. AWS CLI Setup
```bash
# Install AWS CLI (if not already installed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS credentials
aws configure
```

### 2. Terraform Installation
```bash
# Install Terraform (if not already installed)
# Visit: https://developer.hashicorp.com/terraform/downloads
# Or use package manager:
brew install terraform  # macOS
```

### 3. Docker Installation
Ensure Docker is installed and running on your machine.

## Quick Deployment

### 1. Clone and Setup
```bash
git clone <your-repo>
cd GolfTrackerAnalytics
```

### 2. Configure Variables
```bash
# Copy and customize Terraform variables
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the terraform.tfvars file with your values
nano terraform/terraform.tfvars
```

**Important**: Change the `db_password` in `terraform.tfvars` to a secure password!

### 3. Deploy Infrastructure
```bash
# Make script executable (if not already)
chmod +x scripts/deploy.sh

# Run deployment script
./scripts/deploy.sh dev us-east-1
```

## Manual Deployment Steps

If you prefer to deploy manually:

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Plan Deployment
```bash
terraform plan -var-file="terraform.tfvars"
```

### 3. Apply Infrastructure
```bash
terraform apply -var-file="terraform.tfvars"
```

### 4. Build and Push Docker Image
```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr-url>

# Build and tag image
docker build -t golf-course-api .
docker tag golf-course-api:latest <ecr-url>:latest

# Push to ECR
docker push <ecr-url>:latest
```

### 5. Update ECS Service
```bash
aws ecs update-service \
    --cluster golf-course-api-dev-cluster \
    --service golf-course-api-dev-service \
    --force-new-deployment \
    --region us-east-1
```

## Configuration

### Environment Variables

The application automatically detects the environment and configures itself accordingly:

- **Development**: Uses SQLite database
- **Production**: Uses PostgreSQL RDS

### Database Configuration

The RDS instance is configured with:
- Engine: PostgreSQL 15.4
- Instance: db.t3.micro (suitable for development)
- Storage: 20GB with auto-scaling up to 100GB
- Backup: 7-day retention
- Monitoring: Performance Insights enabled

### Security

- RDS is placed in private subnets (not publicly accessible)
- ECS tasks run in private subnets with NAT gateway for internet access
- Security groups restrict traffic to necessary ports only
- Application Load Balancer handles public internet traffic

## Accessing Your API

After deployment, you'll get outputs including:

- **Load Balancer URL**: Your API endpoint
- **API Documentation**: `<load-balancer-url>/docs`
- **Health Check**: `<load-balancer-url>/health`

Example:
```bash
# Test the API
curl http://your-alb-url.us-east-1.elb.amazonaws.com/golf-courses

# View documentation
open http://your-alb-url.us-east-1.elb.amazonaws.com/docs
```

## Monitoring and Logs

### CloudWatch Logs
```bash
# View ECS logs
aws logs describe-log-groups --log-group-name-prefix "/ecs/golf-course-api"

# Stream logs
aws logs tail /ecs/golf-course-api-dev --follow
```

### ECS Service Status
```bash
# Check service status
aws ecs describe-services \
    --cluster golf-course-api-dev-cluster \
    --services golf-course-api-dev-service
```

## Scaling

### Auto Scaling (Optional)
To add auto-scaling, you can create additional resources:

```hcl
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}
```

### Manual Scaling
```bash
aws ecs update-service \
    --cluster golf-course-api-dev-cluster \
    --service golf-course-api-dev-service \
    --desired-count 2
```

## Cost Optimization

### Development Environment
- RDS: db.t3.micro (~$13/month)
- ECS Fargate: 0.25 vCPU, 0.5GB RAM (~$7/month)
- ALB: ~$16/month
- Data transfer and storage: Variable

**Total estimated cost**: ~$40-50/month for development

### Production Considerations
- Use larger RDS instance (db.t3.small or larger)
- Enable Multi-AZ for RDS
- Use reserved instances for cost savings
- Implement auto-scaling
- Add SSL certificate (AWS Certificate Manager)

## SSL/HTTPS Setup

To add HTTPS:

1. Request SSL certificate in AWS Certificate Manager
2. Update ALB listener to use HTTPS (port 443)
3. Redirect HTTP to HTTPS

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

## Troubleshooting

### Common Issues

1. **ECS Service not starting**
   - Check CloudWatch logs for container errors
   - Verify environment variables
   - Check security group rules

2. **Database connection issues**
   - Verify RDS is in running state
   - Check security group allows port 5432
   - Verify database credentials

3. **Load balancer health checks failing**
   - Ensure `/health` endpoint is accessible
   - Check container port configuration
   - Verify target group health check settings

### Useful Commands

```bash
# Check ECS task status
aws ecs list-tasks --cluster golf-course-api-dev-cluster

# Describe failing tasks
aws ecs describe-tasks --cluster golf-course-api-dev-cluster --tasks <task-arn>

# Check RDS status
aws rds describe-db-instances --db-instance-identifier golf-course-api-dev-postgres
```

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy -var-file="terraform.tfvars"
```

**Warning**: This will permanently delete all data including the database!

## Next Steps

1. Set up CI/CD pipeline (GitHub Actions, AWS CodePipeline)
2. Add monitoring and alerting (CloudWatch Alarms)
3. Implement backup strategy
4. Add custom domain name and SSL
5. Set up staging environment
6. Configure auto-scaling policies

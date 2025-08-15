# Cost Optimization Guide

## Overview

The GolfTracker Analytics infrastructure is designed with cost optimization as a primary concern. This guide outlines the strategies implemented and provides guidance on managing costs effectively.

## Cost Optimization Strategies

### 1. Infrastructure Automation

**Automated Scaling**
- EKS cluster autoscaling based on workload demand
- Scheduled scaling for predictable usage patterns
- Spot instances for non-critical workloads (up to 70% cost savings)

**Lifecycle Management**
- Complete infrastructure destruction when not in use
- Quick deployment for development sessions
- Estimated monthly savings: $200-500 when destroyed

### 2. Compute Optimization

**EKS Node Groups**
- Mixed instance types for cost efficiency
- Spot instances for batch processing workloads
- On-demand instances only for critical services

**Instance Sizing**
- Right-sized instances based on workload requirements
- Automatic scaling policies to prevent over-provisioning
- GPU instances only provisioned when needed for AI processing

### 3. Storage Optimization

**S3 Lifecycle Policies**
- Automatic transition to cheaper storage classes
- Standard → Standard-IA (30 days)
- Standard-IA → Glacier (90 days)
- Glacier → Deep Archive (365 days)

**EBS Optimization**
- GP3 volumes for better price/performance
- Encryption enabled by default
- Automatic cleanup of unused volumes

### 4. Network Cost Management

**VPC Endpoints**
- S3 Gateway endpoint to avoid NAT Gateway costs
- Interface endpoints for ECR to reduce data transfer
- Regional deployment to minimize cross-AZ charges

**Data Transfer Optimization**
- CloudFront CDN for static content delivery
- Regional replication strategy
- Compression for video uploads

## Cost Monitoring

### Real-time Monitoring

**CloudWatch Dashboards**
- Real-time cost tracking
- Resource utilization metrics
- Automated cost alerts

**Budget Alerts**
- Monthly budget thresholds
- Email notifications for cost overruns
- Automatic scaling policies based on spend

### Cost Analysis Tools

```bash
# Check current AWS costs
aws ce get-cost-and-usage \
    --time-period Start=2024-01-01,End=2024-01-31 \
    --granularity MONTHLY \
    --metrics BlendedCost

# Analyze by service
aws ce get-dimension-values \
    --dimension SERVICE \
    --time-period Start=2024-01-01,End=2024-01-31
```

## Development vs Production Costs

### Development Environment
- **EKS**: 1 node, t3.small instances
- **RDS**: db.t3.micro, no Multi-AZ
- **Vault**: t3.micro instance
- **Estimated Monthly Cost**: ~$100-150

### Production Environment
- **EKS**: 3+ nodes, mixed instance types
- **RDS**: db.t3.small, Multi-AZ enabled
- **Vault**: t3.medium for performance
- **Estimated Monthly Cost**: ~$300-600

## Cost Optimization Commands

### Daily Operations

```bash
# Check resource utilization
kubectl top nodes
kubectl top pods --all-namespaces

# Scale down non-essential services
kubectl scale deployment backend-api --replicas=1 -n golftracker
kubectl scale deployment ai-processor --replicas=0 -n golftracker

# Check spot instance status
aws ec2 describe-spot-instance-requests

# Monitor S3 storage costs
aws s3api get-bucket-location --bucket your-video-bucket
aws s3 ls s3://your-video-bucket --recursive --summarize
```

### Weekly Optimization

```bash
# Clean up unused EBS volumes
aws ec2 describe-volumes --filters Name=status,Values=available

# Review and clean up old AMIs
aws ec2 describe-images --owners self --filters Name=state,Values=available

# Analyze cost and usage reports
aws ce get-cost-and-usage --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity DAILY --metrics BlendedCost
```

## Scheduled Scaling

### Business Hours Scaling
```yaml
# Example CronJob for scaling
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-up-business-hours
spec:
  schedule: "0 8 * * 1-5"  # 8 AM Monday-Friday
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scaler
            image: bitnami/kubectl
            command:
            - /bin/sh
            - -c
            - |
              kubectl scale deployment backend-api --replicas=3
              kubectl scale deployment ai-processor --replicas=2
```

### After Hours Scaling
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-down-after-hours
spec:
  schedule: "0 18 * * 1-5"  # 6 PM Monday-Friday
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scaler
            image: bitnami/kubectl
            command:
            - /bin/sh
            - -c
            - |
              kubectl scale deployment backend-api --replicas=1
              kubectl scale deployment ai-processor --replicas=0
```

## Emergency Cost Controls

### Immediate Cost Reduction
```bash
# Stop all non-essential workloads
kubectl scale deployment --replicas=0 --all -n golftracker

# Reduce node group to minimum
aws eks update-nodegroup-config \
    --cluster-name golftracker-analytics-production-eks-cluster \
    --nodegroup-name general \
    --scaling-config minSize=1,maxSize=1,desiredSize=1
```

### Complete Shutdown
```bash
# Destroy entire infrastructure
cd terraform
./scripts/destroy.sh
```

## Cost Estimation Tools

### Terraform Cost Estimation
```bash
# Use infracost for cost estimation
infracost breakdown --path .
infracost diff --path .
```

### AWS Cost Calculator
Use the AWS Pricing Calculator for detailed cost estimates:
- [AWS Pricing Calculator](https://calculator.aws/)

## Best Practices

### Development Workflow
1. **Use development environment** for testing
2. **Destroy infrastructure** when not actively developing
3. **Use spot instances** for non-critical testing
4. **Monitor costs daily** during active development

### Production Deployment
1. **Start with minimal resources** and scale as needed
2. **Use reserved instances** for predictable workloads
3. **Implement comprehensive monitoring** for cost tracking
4. **Regular cost reviews** and optimization

### Long-term Optimization
1. **Reserved Instance planning** for stable workloads
2. **Savings Plans** for compute costs
3. **Regular architecture reviews** for efficiency
4. **Automated cost optimization** policies

## Cost Alerts Configuration

```yaml
# CloudFormation template for cost alerts
AWSTemplateFormatVersion: '2010-09-09'
Resources:
  CostAlert:
    Type: AWS::Budgets::Budget
    Properties:
      Budget:
        BudgetName: GolfTracker-Monthly-Budget
        BudgetLimit:
          Amount: 500
          Unit: USD
        TimeUnit: MONTHLY
        BudgetType: COST
      NotificationsWithSubscribers:
        - Notification:
            NotificationType: ACTUAL
            ComparisonOperator: GREATER_THAN
            Threshold: 80
          Subscribers:
            - SubscriptionType: EMAIL
              Address: alerts@golftracker.com
```

## Conclusion

By following these cost optimization strategies, you can:
- Reduce infrastructure costs by 60-80% during development
- Maintain production performance while optimizing spend
- Automatically scale resources based on demand
- Monitor and control costs proactively

Remember: The key to cost optimization is automation and monitoring. Set up alerts, automate scaling, and regularly review your usage patterns.

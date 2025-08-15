# GolfTrackerAnalytics Deployment Guide

## Prerequisites

### 1. Required Accounts & Services
- AWS Account with administrative access
- HashiCorp Cloud Platform (HCP) account
- GitHub account for version control

### 2. Local Development Tools
```bash
# Install required tools
brew install terraform
brew install kubectl
brew install awscli
brew install vault
```

### 3. AWS IAM Permissions
Create an IAM user with the following managed policies:
- `AmazonEKSClusterPolicy`
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`
- `AmazonS3FullAccess`
- `AmazonRDSFullAccess`
- `CloudWatchFullAccess`

Custom policy for additional permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kms:*",
                "iam:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "logs:*",
                "ssm:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## HCP Terraform Setup

### 1. Create Organization
1. Log into [HCP Terraform](https://app.terraform.io)
2. Create new organization: `golftracker-analytics`
3. Configure organization settings

### 2. Create Workspace
```bash
# Create workspace configuration
cat > terraform-workspace.tf << EOF
terraform {
  cloud {
    organization = "golftracker-analytics"
    workspaces {
      name = "golftracker-infrastructure"
    }
  }
}
EOF
```

### 3. Environment Variables
Set the following environment variables in HCP Terraform workspace:

**AWS Credentials (Sensitive)**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

**Infrastructure Variables**
- `aws_region` = "us-west-2"
- `environment` = "production"
- `project_name` = "golftracker-analytics"

## Quick Deployment

### 1. Clone and Initialize
```bash
git clone <your-repo>
cd GolfTrackerAnalytics
terraform init
```

### 2. Deploy Infrastructure
```bash
# Plan deployment
terraform plan

# Apply infrastructure
terraform apply
```

### 3. Configure kubectl
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-west-2 --name golftracker-eks-cluster

# Verify connection
kubectl get nodes
```

### 4. Deploy Applications
```bash
# Apply Kubernetes manifests
kubectl apply -f kubernetes/
```

## Step-by-Step Deployment

### Phase 1: Core Infrastructure
```bash
# Deploy VPC and networking
terraform apply -target=module.vpc

# Deploy security groups
terraform apply -target=module.security_groups

# Deploy KMS keys
terraform apply -target=module.kms
```

### Phase 2: Data Layer
```bash
# Deploy RDS database
terraform apply -target=module.rds

# Deploy S3 buckets
terraform apply -target=module.s3
```

### Phase 3: Compute Layer
```bash
# Deploy EKS cluster
terraform apply -target=module.eks

# Deploy Vault EC2 instance
terraform apply -target=module.vault
```

### Phase 4: Monitoring & Security
```bash
# Deploy CloudWatch resources
terraform apply -target=module.cloudwatch

# Deploy Vault Secrets Operator
terraform apply -target=module.vault_secrets_operator
```

## Post-Deployment Configuration

### 1. Initialize HashiCorp Vault
```bash
# SSH to Vault instance
aws ssm start-session --target <vault-instance-id>

# Initialize Vault
vault operator init -key-shares=3 -key-threshold=2

# Unseal Vault (repeat with 2 keys)
vault operator unseal <key-1>
vault operator unseal <key-2>

# Login with root token
vault auth <root-token>
```

### 2. Configure Vault Policies
```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://kubernetes.default.svc:443" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```

### 3. Deploy Application Services
```bash
# Create namespace
kubectl create namespace golftracker

# Deploy backend services
kubectl apply -f kubernetes/backend/ -n golftracker

# Deploy AI processing service
kubectl apply -f kubernetes/ai-service/ -n golftracker
```

### 4. Configure Monitoring
```bash
# Deploy Prometheus
kubectl apply -f monitoring/prometheus/

# Deploy Grafana
kubectl apply -f monitoring/grafana/

# Import dashboards
kubectl apply -f monitoring/dashboards/
```

## Verification Steps

### 1. Infrastructure Health Checks
```bash
# Check EKS cluster status
aws eks describe-cluster --name golftracker-eks-cluster

# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

### 2. Application Health Checks
```bash
# Check application pods
kubectl get pods -n golftracker

# Check services
kubectl get svc -n golftracker

# Check ingress
kubectl get ingress -n golftracker
```

### 3. Vault Health Check
```bash
# Check Vault status
vault status

# Test secret creation
vault kv put secret/test key=value

# Test secret retrieval
vault kv get secret/test
```

## Cost Optimization Deployment

### 1. Development Environment
```bash
# Deploy minimal infrastructure
terraform apply -var="environment=development" -var="instance_types=[\"t3.small\"]"
```

### 2. Scheduled Scaling
```bash
# Apply scheduled scaling policies
kubectl apply -f kubernetes/scaling/
```

### 3. Spot Instance Configuration
```bash
# Enable spot instances for worker nodes
terraform apply -var="use_spot_instances=true"
```

## Troubleshooting

### Common Issues

#### EKS Node Group Issues
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name golftracker-eks-cluster --nodegroup-name <nodegroup-name>

# Check CloudFormation stack
aws cloudformation describe-stacks --stack-name <stack-name>
```

#### Vault Connection Issues
```bash
# Check Vault logs
sudo journalctl -u vault -f

# Check security group rules
aws ec2 describe-security-groups --group-ids <vault-sg-id>
```

#### Application Deployment Issues
```bash
# Check pod logs
kubectl logs -f <pod-name> -n golftracker

# Check events
kubectl get events -n golftracker --sort-by='.lastTimestamp'
```

### Recovery Procedures

#### RDS Recovery
```bash
# List available snapshots
aws rds describe-db-snapshots --db-instance-identifier golftracker-db

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier golftracker-db-restored \
    --db-snapshot-identifier <snapshot-id>
```

#### Vault Recovery
```bash
# Restore Vault from backup
vault operator raft snapshot restore /tmp/vault-backup.snap
```

## Maintenance

### Regular Updates
```bash
# Update EKS cluster
aws eks update-cluster-version --name golftracker-eks-cluster --version <new-version>

# Update node groups
aws eks update-nodegroup-version --cluster-name golftracker-eks-cluster --nodegroup-name <nodegroup-name>
```

### Security Updates
```bash
# Update Vault
sudo yum update vault -y
sudo systemctl restart vault

# Update application images
kubectl set image deployment/backend-api backend-api=new-image:tag -n golftracker
```

## Automation Scripts

### Infrastructure Lifecycle
```bash
# Spin up infrastructure
./scripts/deploy.sh

# Destroy infrastructure
./scripts/destroy.sh

# Scale infrastructure
./scripts/scale.sh <scale-factor>
```

### Backup & Restore
```bash
# Create backup
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh <backup-date>
```

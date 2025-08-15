# GolfTrackerAnalytics

Backend infrastructure for the GolfTracker iOS application with AI Golf Pro integration.

## Overview

GolfTrackerAnalytics is the backend service for a premium golf application that provides AI-powered golf swing analysis and recommendations. The infrastructure is designed for cost optimization with automated deployment and destruction capabilities.

## Features

- **AI Golf Pro Integration**: Video analysis and personalized recommendations
- **Cost-Optimized Infrastructure**: Automated scaling and destruction when not in use
- **Secure Secrets Management**: HashiCorp Vault integration
- **Comprehensive Monitoring**: AWS CloudWatch logging and monitoring
- **Container Orchestration**: Amazon EKS for scalable application deployment

## Quick Start

1. Configure HCP Terraform workspace
2. Set up AWS credentials and permissions
3. Deploy infrastructure: `terraform apply`
4. Configure application services
5. Destroy when not needed: `terraform destroy`

## Documentation

See the [docs](./docs/) directory for detailed architecture and deployment guides.

## Project Structure

```
├── terraform/              # Infrastructure as Code
│   ├── modules/            # Reusable Terraform modules
│   ├── environments/       # Environment-specific configurations
│   └── scripts/           # Automation scripts
├── kubernetes/             # Kubernetes manifests
├── vault/                 # Vault configurations
├── docs/                  # Documentation
└── monitoring/            # Monitoring configurations
```

## Technologies

- **Infrastructure**: Terraform, AWS EKS, EC2
- **Secrets Management**: HashiCorp Vault, Vault Secrets Operator
- **Monitoring**: AWS CloudWatch, Prometheus, Grafana
- **Orchestration**: HCP Terraform
- **Container Platform**: Amazon EKS

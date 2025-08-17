# HCP Terraform Setup Guide

## Variable Sets für Secrets Management

HCP Terraform bietet verschiedene Möglichkeiten zur sicheren Verwaltung von Secrets:

### 1. Environment Variables (Recommended)

In HCP Terraform Workspace → Variables:

```bash
# Terraform Variables (Environment Variables)
TF_VAR_supabase_url = "https://your-project.supabase.co"        # SENSITIVE
TF_VAR_supabase_key = "your-anon-key"                           # SENSITIVE  
TF_VAR_database_url = "postgresql://user:pass@host:port/db"     # SENSITIVE
TF_VAR_container_image = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/golf-tracker:latest"
TF_VAR_aws_region = "eu-central-1"
TF_VAR_environment = "prod"
```

### 2. Variable Sets (Global)

Erstelle Variable Sets für wiederverwendbare Secrets:

#### Production Variable Set
```bash
# Name: "golf-tracker-production"
TF_VAR_environment = "prod"
TF_VAR_aws_region = "eu-central-1"
TF_VAR_enable_container_insights = true
TF_VAR_desired_capacity = 2
TF_VAR_min_capacity = 1
TF_VAR_max_capacity = 10
```

#### Development Variable Set
```bash
# Name: "golf-tracker-development"
TF_VAR_environment = "dev"
TF_VAR_aws_region = "eu-central-1"
TF_VAR_enable_container_insights = false
TF_VAR_desired_capacity = 1
TF_VAR_min_capacity = 1
TF_VAR_max_capacity = 3
```

### 3. Workspace-Specific Secrets

Für sensible Daten pro Workspace:

```bash
# Production Workspace
TF_VAR_supabase_url = "https://prod-project.supabase.co"        # SENSITIVE
TF_VAR_supabase_key = "prod-anon-key"                           # SENSITIVE
TF_VAR_database_url = "postgresql://prod-user:pass@host/db"     # SENSITIVE

# Development Workspace  
TF_VAR_supabase_url = "https://dev-project.supabase.co"         # SENSITIVE
TF_VAR_supabase_key = "dev-anon-key"                            # SENSITIVE
TF_VAR_database_url = "postgresql://dev-user:pass@host/db"      # SENSITIVE
```

## Setup-Schritte

### 1. Organisation erstellen
```bash
# In HCP Terraform
1. Gehe zu https://app.terraform.io
2. Erstelle neue Organisation
3. Notiere Organisation Name für main.tf
```

### 2. Workspace konfigurieren
```bash
# Workspace Settings
Name: golf-tracker-analytics
Execution Mode: Remote
Terraform Version: ~> 1.6.0
Working Directory: terraform/
```

### 3. VCS Integration
```bash
# GitHub Integration
1. Connect GitHub Repository
2. Branch: main
3. Trigger: Auto apply
4. Include submodules: No
```

### 4. Variable Sets zuweisen
```bash
# Zuweisen von Variable Sets
1. Gehe zu Settings → Variable Sets
2. Erstelle neue Variable Sets (siehe oben)
3. Weise sie dem Workspace zu
```

### 5. Notifications einrichten (Optional)
```bash
# Slack/Email Notifications
1. Settings → Notifications
2. Webhook URL: your-slack-webhook
3. Triggers: Run: Completed, Run: Errored
```

## Security Best Practices

### 1. Sensitive Variables
- Markiere alle Secrets als "Sensitive"
- Verwende Environment Variables für Secrets
- Nutze separate Workspaces für Environments

### 2. Access Control
```bash
# Team Permissions
- Developers: Plan
- DevOps: Plan & Apply  
- Admins: Manage
```

### 3. Run Triggers
```bash
# Auto-apply nur für:
- Production: Manual approval
- Development: Auto-apply
- Staging: Auto-apply
```

### 4. State File Security
```bash
# Automatic:
- State encryption at rest
- State locking
- State versioning
- Access logs
```

## CLI Setup (Optional)

```bash
# Terraform CLI Configuration
terraform login

# Verify connection
terraform workspace list
```

## Troubleshooting

### Common Issues:

1. **Variable not found**
   - Check variable naming (TF_VAR_ prefix)
   - Verify sensitive flag
   - Check workspace assignment

2. **Permission denied**
   - Verify team permissions
   - Check workspace access
   - Validate API token

3. **Plan failures**
   - Check variable values
   - Verify AWS credentials in GitHub
   - Check Terraform version compatibility

## Monitoring & Alerts

### CloudWatch Integration
```bash
# Set up alerts for:
- Failed Terraform runs
- Infrastructure changes  
- Cost anomalies
- Security violations
```

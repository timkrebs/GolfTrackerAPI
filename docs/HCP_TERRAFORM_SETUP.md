# HCP Terraform Setup Guide

Diese Anleitung beschreibt die Einrichtung von HCP Terraform (ehemals Terraform Cloud) für das Golf API Projekt.

## 🏗️ Überblick

HCP Terraform bietet:
- Remote State Management
- Workspace-basierte Umgebungen
- VCS-Integration (GitHub/GitLab)
- Automated Planning und Apply
- Secure Variables Management
- Team Collaboration Features

## 📋 Voraussetzungen

1. **HCP Terraform Account**: Kostenloser Account auf [app.terraform.io](https://app.terraform.io)
2. **GitHub/GitLab Repository**: Verbunden mit HCP Terraform
3. **AWS Credentials**: Für Infrastructure Deployment
4. **Supabase Account**: Für Datenbank-Services

## 🚀 Setup Schritte

### 1. HCP Terraform Organization erstellen

1. Melde dich bei [app.terraform.io](https://app.terraform.io) an
2. Erstelle eine neue Organization: `golf-api-org` (oder gewünschter Name)
3. Wähle den "Free" Plan für den Anfang

### 2. Workspaces einrichten

Erstelle separate Workspaces für jede Umgebung:

#### Development Workspace
```
Name: golf-api-dev
Working Directory: terraform/environments/dev
VCS Branch: develop (oder main)
```

#### Staging Workspace (Optional)
```
Name: golf-api-staging  
Working Directory: terraform/environments/staging
VCS Branch: staging
```

#### Production Workspace
```
Name: golf-api-prod
Working Directory: terraform/environments/prod
VCS Branch: main
```

### 3. VCS Connection konfigurieren

1. **GitHub Integration**:
   - Gehe zu Settings → VCS Providers
   - Wähle "GitHub.com"
   - Autorisiere HCP Terraform
   - Wähle dein Repository

2. **Workspace VCS Settings**:
   ```
   Repository: your-username/GolfTrackerAnalytics
   Branch: entsprechend der Umgebung
   Working Directory: terraform/environments/{env}/
   ```

### 4. Environment Variables konfigurieren

#### AWS Credentials (für alle Workspaces)
```bash
# Environment Variables
AWS_ACCESS_KEY_ID = "your-access-key"          # Sensitive
AWS_SECRET_ACCESS_KEY = "your-secret-key"      # Sensitive  
AWS_DEFAULT_REGION = "us-east-1"
```

#### Terraform Variables

**Development Workspace**:
```hcl
# Terraform Variables
aws_region = "us-east-1"
container_image = "your-account.dkr.ecr.us-east-1.amazonaws.com/golf-api-dev:latest"

# Sensitive Variables
supabase_url = "https://your-project.supabase.co"                    # Sensitive
supabase_anon_key = "eyJ..."                                         # Sensitive
supabase_service_role_key = "eyJ..."                                 # Sensitive
database_url = "postgresql+asyncpg://user:pass@host:port/db"         # Sensitive
```

**Production Workspace**:
```hcl
# Terraform Variables  
aws_region = "us-east-1"
container_image = "your-account.dkr.ecr.us-east-1.amazonaws.com/golf-api-prod:latest"
certificate_arn = "arn:aws:acm:us-east-1:account:certificate/cert-id"

# Sensitive Variables (separate prod values)
supabase_url = "https://your-prod-project.supabase.co"               # Sensitive
supabase_anon_key = "eyJ..."                                         # Sensitive
supabase_service_role_key = "eyJ..."                                 # Sensitive
database_url = "postgresql+asyncpg://user:pass@prod-host:port/db"    # Sensitive
```

### 5. Workspace Settings konfigurieren

#### Execution Mode
```
Execution Mode: Remote
Terraform Version: 1.6.x (Latest)
```

#### Auto Apply Settings
```
Development: Auto Apply nach successful plan
Production: Manual Apply (für Review)
```

#### Notifications
```
Slack/Email Notifications für:
- Plan Erfolg/Fehler
- Apply Erfolg/Fehler
- Policy Violations
```

## 🔄 Workflow Integration

### 1. Backend Configuration aktualisieren

Aktualisiere die `backend.tf` in jedem Environment:

```hcl
# terraform/environments/dev/backend.tf
terraform {
  cloud {
    organization = "golf-api-org"
    
    workspaces {
      name = "golf-api-dev"
    }
  }
}
```

### 2. GitHub Actions anpassen

Beispiel für HCP Terraform Integration:

```yaml
# .github/workflows/terraform.yml
name: Terraform

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}

      - name: Terraform Format
        run: terraform fmt -check

      - name: Terraform Init
        run: terraform init

      - name: Terraform Validate
        run: terraform validate

      - name: Terraform Plan
        run: terraform plan
```

### 3. Lokale CLI Konfiguration

```bash
# Terraform Cloud Token setzen
terraform login

# Oder manuell in ~/.terraformrc
credentials "app.terraform.io" {
  token = "your-api-token"
}
```

## 🛡️ Security Best Practices

### 1. Variable Sets erstellen

Erstelle Variable Sets für wiederverwendbare Konfigurationen:

```
Variable Set: aws-credentials
Variables:
- AWS_ACCESS_KEY_ID (sensitive)
- AWS_SECRET_ACCESS_KEY (sensitive)
- AWS_DEFAULT_REGION

Applied to: All workspaces
```

### 2. Sentinel Policies (Optional)

Beispiel Policy für Cost Control:

```hcl
# policies/cost-control.sentinel
import "tfplan/v2" as tfplan
import "decimal"

# Maximum cost threshold
max_monthly_cost = 100

# Calculate total cost
monthly_cost = decimal.new(tfplan.planned_values.total_cost.monthly)

# Policy rule
main = rule {
    monthly_cost.less_than_or_equal_to(decimal.new(max_monthly_cost))
}
```

### 3. Team Permissions

```
Team: developers
Permissions:
- Read access to all workspaces
- Plan access to dev workspace
- No apply access to prod

Team: devops
Permissions:
- Admin access to all workspaces
- Apply access to all environments
```

## 📊 Monitoring und Notifications

### 1. Slack Integration

```bash
# Slack Webhook URL in HCP Terraform
Webhook URL: https://hooks.slack.com/services/...
Channel: #deployments
```

### 2. Email Notifications

```
Recipients: team@company.com
Events:
- Run Completed
- Run Errored
- Policy Failed
```

## 🔧 Troubleshooting

### Häufige Probleme

1. **VCS Connection Issues**:
   ```bash
   # Prüfe Repository Permissions
   # Stelle sicher, dass HCP Terraform App installiert ist
   ```

2. **Authentication Errors**:
   ```bash
   # Überprüfe AWS Credentials
   # Validiere Terraform Cloud Token
   ```

3. **State Lock Issues**:
   ```bash
   # State unlocks über HCP Terraform UI
   # Oder via CLI: terraform force-unlock
   ```

## 📚 Nützliche Befehle

```bash
# Lokaler Terraform mit HCP Backend
terraform init
terraform plan
terraform apply

# Remote Execution prüfen
terraform show
terraform output

# Workspace wechseln (bei mehreren)
terraform workspace select golf-api-dev
```

## 🔗 Weiterführende Links

- [HCP Terraform Documentation](https://developer.hashicorp.com/terraform/cloud-docs)
- [VCS Integration](https://developer.hashicorp.com/terraform/cloud-docs/vcs)
- [Workspace Management](https://developer.hashicorp.com/terraform/cloud-docs/workspaces)
- [Variable Management](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/variables)

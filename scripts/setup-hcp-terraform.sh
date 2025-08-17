#!/bin/bash

# HCP Terraform Setup Script
# This script helps you configure the required variables in HCP Terraform

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 HCP Terraform Setup für Golf Tracker Analytics${NC}"
echo ""

echo -e "${YELLOW}📋 Sie müssen folgende Variablen in HCP Terraform konfigurieren:${NC}"
echo ""

echo -e "${GREEN}1. Gehen Sie zu: https://app.terraform.io${NC}"
echo -e "${GREEN}2. Navigieren Sie zu Ihrem Workspace: golf-tracker-analytics${NC}" 
echo -e "${GREEN}3. Klicken Sie auf 'Variables' Tab${NC}"
echo -e "${GREEN}4. Fügen Sie folgende Terraform Variables hinzu:${NC}"
echo ""

echo -e "${BLUE}=== ERFORDERLICHE VARIABLEN ===${NC}"
echo ""

echo -e "${YELLOW}Variable Name:${NC} container_image"
echo -e "${YELLOW}Value:${NC} your-account-id.dkr.ecr.eu-central-1.amazonaws.com/golf-tracker:latest"
echo -e "${YELLOW}Sensitive:${NC} No"
echo -e "${YELLOW}Description:${NC} Docker Container Image URI"
echo ""

echo -e "${YELLOW}Variable Name:${NC} supabase_url"
echo -e "${YELLOW}Value:${NC} https://your-project-id.supabase.co"
echo -e "${YELLOW}Sensitive:${NC} Yes ✅"
echo -e "${YELLOW}Description:${NC} Supabase Project URL"
echo ""

echo -e "${YELLOW}Variable Name:${NC} supabase_key"
echo -e "${YELLOW}Value:${NC} your-supabase-anon-or-service-key"
echo -e "${YELLOW}Sensitive:${NC} Yes ✅"
echo -e "${YELLOW}Description:${NC} Supabase API Key"
echo ""

echo -e "${YELLOW}Variable Name:${NC} database_url"
echo -e "${YELLOW}Value:${NC} postgresql://postgres:password@db.your-project.supabase.co:5432/postgres"
echo -e "${YELLOW}Sensitive:${NC} Yes ✅"
echo -e "${YELLOW}Description:${NC} Database Connection String"
echo ""

echo -e "${BLUE}=== OPTIONALE VARIABLEN ===${NC}"
echo ""

echo -e "${YELLOW}Variable Name:${NC} aws_region"
echo -e "${YELLOW}Value:${NC} eu-central-1"
echo -e "${YELLOW}Sensitive:${NC} No"
echo ""

echo -e "${YELLOW}Variable Name:${NC} environment"
echo -e "${YELLOW}Value:${NC} prod (oder dev/staging)"
echo -e "${YELLOW}Sensitive:${NC} No"
echo ""

echo -e "${YELLOW}Variable Name:${NC} desired_capacity"
echo -e "${YELLOW}Value:${NC} 2"
echo -e "${YELLOW}Sensitive:${NC} No"
echo ""

echo -e "${GREEN}=== SCHRITTE IN HCP TERRAFORM ===${NC}"
echo ""
echo "1. Klicken Sie 'Add variable'"
echo "2. Wählen Sie 'Terraform variable' (nicht Environment variable)"
echo "3. Geben Sie Variable Name ein"
echo "4. Geben Sie Value ein"
echo "5. Markieren Sie 'Sensitive' für Secrets"
echo "6. Klicken Sie 'Save variable'"
echo "7. Wiederholen Sie für alle Variablen"
echo ""

echo -e "${GREEN}=== NACH DER KONFIGURATION ===${NC}"
echo ""
echo "1. Gehen Sie zu 'Actions' → 'Start new plan'"
echo "2. Terraform sollte jetzt erfolgreich planen"
echo "3. Wenn der Plan erfolgreich ist, klicken Sie 'Confirm & Apply'"
echo ""

echo -e "${RED}⚠️  WICHTIGE HINWEISE:${NC}"
echo ""
echo "• Verwenden Sie verschiedene Credentials für dev/staging/prod"
echo "• Markieren Sie alle Secrets als 'Sensitive'"
echo "• Rotieren Sie Credentials regelmäßig"
echo "• Überprüfen Sie die Supabase-Dokumentation für korrekte URLs"
echo ""

echo -e "${BLUE}🔗 NÜTZLICHE LINKS:${NC}"
echo ""
echo "• HCP Terraform: https://app.terraform.io"
echo "• Supabase Dashboard: https://app.supabase.com"
echo "• AWS ECR Console: https://console.aws.amazon.com/ecr"
echo ""

# Check if user wants to create a .tfvars file
echo -e "${YELLOW}Möchten Sie eine lokale terraform.tfvars Datei erstellen? (y/n)${NC}"
read -r create_tfvars

if [[ $create_tfvars =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}📝 Erstelle terraform.tfvars Template...${NC}"
    
    cd terraform/
    cp terraform.tfvars.example terraform.tfvars
    
    echo -e "${GREEN}✅ terraform.tfvars erstellt!${NC}"
    echo -e "${YELLOW}Bearbeiten Sie terraform/terraform.tfvars mit Ihren Werten.${NC}"
    echo -e "${RED}⚠️  Committen Sie terraform.tfvars NIEMALS zu Git!${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup-Anleitung abgeschlossen!${NC}"

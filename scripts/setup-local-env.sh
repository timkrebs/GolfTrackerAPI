#!/bin/bash

# Setup script for local development environment
# This script helps securely manage local development credentials

set -euo pipefail

echo "🔧 Setting up Golf Tracker Analytics local development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to prompt for secure input
prompt_secret() {
    local var_name="$1"
    local description="$2"
    local value=""
    
    echo -e "${YELLOW}Enter $description:${NC}"
    read -s value
    echo "export $var_name=\"$value\"" >> .env
    echo -e "${GREEN}✓ $var_name configured${NC}"
}

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp env.example .env
else
    echo -e "${YELLOW}⚠️  .env file already exists. Creating backup...${NC}"
    cp .env .env.backup
fi

echo ""
echo "🔐 Please provide your Supabase credentials:"
echo "   (Input will be hidden for security)"
echo ""

# Prompt for each secret
prompt_secret "SUPABASE_URL" "Supabase Project URL"
prompt_secret "SUPABASE_KEY" "Supabase Anon Key"
prompt_secret "DATABASE_URL" "Database Connection String"

echo ""
echo -e "${GREEN}✅ Local environment setup complete!${NC}"
echo ""
echo "📋 Next steps:"
echo "   1. Verify your .env file: cat .env"
echo "   2. Start the development server: docker-compose up --build"
echo "   3. Access API docs: http://localhost:8000/docs"
echo ""
echo -e "${YELLOW}🔒 Security reminders:${NC}"
echo "   - Never commit .env files to git"
echo "   - Use different credentials for each environment"
echo "   - Rotate credentials regularly"
echo ""

#!/bin/bash
set -e

echo "🔧 Installing Vault Secrets Operator..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ helm is not installed or not in PATH"
    exit 1
fi

# Add HashiCorp Helm repository
echo "📦 Adding HashiCorp Helm repository..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Install Vault Secrets Operator
echo "🚀 Installing Vault Secrets Operator..."
helm upgrade --install vault-secrets-operator hashicorp/vault-secrets-operator \
  --namespace vault-secrets-operator-system \
  --create-namespace \
  --version 0.4.0 \
  --set "defaultVaultConnection.enabled=true" \
  --set "defaultVaultConnection.address=${vault_url}" \
  --set "defaultVaultConnection.skipTLSVerify=true" \
  --wait

# Wait for the operator to be ready
echo "⏳ Waiting for Vault Secrets Operator to be ready..."
kubectl wait --for=condition=Available deployment/vault-secrets-operator-controller-manager \
  -n vault-secrets-operator-system \
  --timeout=300s

# Create service account for Vault authentication
echo "🔑 Creating Vault authentication service account..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: default
EOF

echo "✅ Vault Secrets Operator installation completed!"
echo ""
echo "📋 Next steps:"
echo "1. Initialize and configure Vault"
echo "2. Enable Kubernetes authentication in Vault"
echo "3. Create Vault policies and roles"
echo "4. Apply VaultConnection and VaultAuth resources"
echo ""
echo "🔧 To apply Vault resources after Vault is configured:"
echo "kubectl apply -f - <<EOF"
echo "apiVersion: secrets.hashicorp.com/v1beta1"
echo "kind: VaultConnection"
echo "metadata:"
echo "  name: default"
echo "  namespace: vault-secrets-operator-system"
echo "spec:"
echo "  address: ${vault_url}"
echo "  skipTLSVerify: true"
echo "---"
echo "apiVersion: secrets.hashicorp.com/v1beta1"
echo "kind: VaultAuth"
echo "metadata:"
echo "  name: default"
echo "  namespace: vault-secrets-operator-system"
echo "spec:"
echo "  vaultConnectionRef: default"
echo "  method: kubernetes"
echo "  mount: kubernetes"
echo "  kubernetes:"
echo "    role: ${vault_role}"
echo "    serviceAccount: vault-auth"
echo "    audiences: [\"vault\"]"
echo "---"
echo "apiVersion: secrets.hashicorp.com/v1beta1"
echo "kind: VaultStaticSecret"
echo "metadata:"
echo "  name: database-credentials"
echo "  namespace: default"
echo "spec:"
echo "  vaultAuthRef: default"
echo "  mount: secret"
echo "  type: kv-v2"
echo "  path: database/credentials"
echo "  destination:"
echo "    name: database-credentials"
echo "    create: true"
echo "  refreshAfter: 30s"
echo "EOF"

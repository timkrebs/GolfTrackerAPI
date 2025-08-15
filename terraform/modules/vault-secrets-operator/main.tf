# Helm release for Vault Secrets Operator
resource "helm_release" "vault_secrets_operator" {
  name             = "vault-secrets-operator"
  repository       = "https://helm.releases.hashicorp.com"
  chart            = "vault-secrets-operator"
  version          = "0.4.0"
  namespace        = "vault-secrets-operator-system"
  create_namespace = true

  values = [
    yamlencode({
      defaultVaultConnection = {
        enabled       = true
        address       = var.vault_url
        skipTLSVerify = true
      }
      controller = {
        manager = {
          image = {
            repository = "hashicorp/vault-secrets-operator"
            tag        = "0.4.0"
          }
          resources = {
            limits = {
              cpu    = "500m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "10m"
              memory = "64Mi"
            }
          }
        }
      }
    })
  ]

  depends_on = [
    data.kubernetes_namespace.kube_system
  ]
}

# Data source to ensure Kubernetes is available
data "kubernetes_namespace" "kube_system" {
  metadata {
    name = "kube-system"
  }
}

# Kubernetes service account for Vault authentication
resource "kubernetes_service_account" "vault_auth" {
  metadata {
    name      = "vault-auth"
    namespace = "default"
  }
}

resource "kubernetes_cluster_role_binding" "vault_auth" {
  metadata {
    name = "vault-auth"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vault_auth.metadata[0].name
    namespace = kubernetes_service_account.vault_auth.metadata[0].namespace
  }
}

# VaultConnection resource
resource "kubernetes_manifest" "vault_connection" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultConnection"
    metadata = {
      name      = "default"
      namespace = "vault-secrets-operator-system"
    }
    spec = {
      address       = var.vault_url
      skipTLSVerify = true
    }
  }

  depends_on = [helm_release.vault_secrets_operator]
}

# VaultAuth resource for Kubernetes authentication
resource "kubernetes_manifest" "vault_auth" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultAuth"
    metadata = {
      name      = "default"
      namespace = "vault-secrets-operator-system"
    }
    spec = {
      vaultConnectionRef = kubernetes_manifest.vault_connection.manifest.metadata.name
      method             = "kubernetes"
      mount              = "kubernetes"
      kubernetes = {
        role           = var.vault_role
        serviceAccount = kubernetes_service_account.vault_auth.metadata[0].name
        audiences      = ["vault"]
      }
    }
  }

  depends_on = [
    kubernetes_manifest.vault_connection,
    kubernetes_service_account.vault_auth
  ]
}

# Example VaultStaticSecret for database credentials
resource "kubernetes_manifest" "database_secret" {
  manifest = {
    apiVersion = "secrets.hashicorp.com/v1beta1"
    kind       = "VaultStaticSecret"
    metadata = {
      name      = "database-credentials"
      namespace = "default"
    }
    spec = {
      vaultAuthRef = kubernetes_manifest.vault_auth.manifest.metadata.name
      mount        = "secret"
      type         = "kv-v2"
      path         = "database/credentials"
      destination = {
        name   = "database-credentials"
        create = true
      }
      refreshAfter = "30s"
    }
  }

  depends_on = [kubernetes_manifest.vault_auth]
}

# ConfigMap with Vault initialization instructions
resource "kubernetes_config_map" "vault_init_instructions" {
  metadata {
    name      = "vault-init-instructions"
    namespace = "default"
  }

  data = {
    "init-vault.sh" = <<-EOF
      #!/bin/bash
      set -e
      
      echo "Vault Initialization Instructions"
      echo "================================="
      echo ""
      echo "1. SSH to Vault instance:"
      echo "   aws ssm start-session --target <vault-instance-id>"
      echo ""
      echo "2. Initialize Vault:"
      echo "   export VAULT_ADDR='http://127.0.0.1:8200'"
      echo "   vault operator init -key-shares=3 -key-threshold=2"
      echo ""
      echo "3. Unseal Vault (use 2 of the 3 keys):"
      echo "   vault operator unseal <key1>"
      echo "   vault operator unseal <key2>"
      echo ""
      echo "4. Login with root token:"
      echo "   vault auth <root-token>"
      echo ""
      echo "5. Enable Kubernetes authentication:"
      echo "   vault auth enable kubernetes"
      echo ""
      echo "6. Configure Kubernetes auth:"
      echo "   vault write auth/kubernetes/config \\"
      echo "     token_reviewer_jwt=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) \\"
      echo "     kubernetes_host=https://kubernetes.default.svc:443 \\"
      echo "     kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
      echo ""
      echo "7. Create policy for GolfTracker backend:"
      echo "   vault policy write ${var.vault_role} - <<EOL"
      echo "   path \"secret/data/database/*\" {"
      echo "     capabilities = [\"read\"]"
      echo "   }"
      echo "   path \"secret/data/api/*\" {"
      echo "     capabilities = [\"read\"]"
      echo "   }"
      echo "   EOL"
      echo ""
      echo "8. Create Kubernetes role:"
      echo "   vault write auth/kubernetes/role/${var.vault_role} \\"
      echo "     bound_service_account_names=vault-auth \\"
      echo "     bound_service_account_namespaces=default \\"
      echo "     policies=${var.vault_role} \\"
      echo "     ttl=24h"
      echo ""
      echo "9. Store database credentials:"
      echo "   vault kv put secret/database/credentials \\"
      echo "     username=golftracker_admin \\"
      echo "     password=<your-secure-password> \\"
      echo "     host=<rds-endpoint> \\"
      echo "     port=5432 \\"
      echo "     database=golftracker"
      echo ""
    EOF

    "test-secret-access.sh" = <<-EOF
      #!/bin/bash
      set -e
      
      echo "Testing Vault Secrets Operator..."
      echo ""
      
      # Check if the secret was created
      if kubectl get secret database-credentials -n default >/dev/null 2>&1; then
        echo "✅ Secret 'database-credentials' found"
        echo ""
        echo "Secret contents:"
        kubectl get secret database-credentials -n default -o yaml
      else
        echo "❌ Secret 'database-credentials' not found"
        echo ""
        echo "Check Vault Secrets Operator logs:"
        echo "kubectl logs -n vault-secrets-operator-system -l app.kubernetes.io/name=vault-secrets-operator"
      fi
    EOF
  }
}

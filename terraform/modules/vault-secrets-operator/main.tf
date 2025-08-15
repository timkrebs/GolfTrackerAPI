# Local file for Vault Secrets Operator installation script
resource "local_file" "install_vso_script" {
  filename = "${path.module}/install-vso.sh"
  content = templatefile("${path.module}/install-vso.sh.tpl", {
    vault_url  = var.vault_url
    vault_role = var.vault_role
  })

  file_permission = "0755"
}

# Null resource to install Vault Secrets Operator using kubectl
resource "null_resource" "install_vault_secrets_operator" {
  depends_on = [local_file.install_vso_script]

  provisioner "local-exec" {
    command = "${path.module}/install-vso.sh"
    environment = {
      CLUSTER_NAME = var.cluster_name
      VAULT_URL    = var.vault_url
      VAULT_ROLE   = var.vault_role
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete namespace vault-secrets-operator-system --ignore-not-found=true"
  }

  triggers = {
    cluster_name = var.cluster_name
    vault_url    = var.vault_url
    vault_role   = var.vault_role
    script_hash  = local_file.install_vso_script.content_md5
  }
}

# ConfigMap with Vault initialization instructions (created after EKS is ready)
resource "local_file" "vault_init_instructions" {
  filename = "${path.module}/vault-init-instructions.yaml"
  content = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
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
  })
}

# Null resource to apply the ConfigMap after EKS is ready
resource "null_resource" "apply_vault_instructions" {
  depends_on = [local_file.vault_init_instructions, null_resource.install_vault_secrets_operator]

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.vault_init_instructions.filename}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete configmap vault-init-instructions -n default --ignore-not-found=true"
  }

  triggers = {
    config_hash = local_file.vault_init_instructions.content_md5
  }
}
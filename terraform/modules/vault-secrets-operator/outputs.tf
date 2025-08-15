output "vault_secrets_operator_namespace" {
  description = "Namespace where Vault Secrets Operator is deployed"
  value       = "vault-secrets-operator-system"
}

output "service_account_name" {
  description = "Name of the Kubernetes service account for Vault authentication"
  value       = "vault-auth"
}

output "init_instructions_file" {
  description = "Path to the Vault initialization instructions file"
  value       = local_file.vault_init_instructions.filename
}

output "installation_script" {
  description = "Path to the VSO installation script"
  value       = local_file.install_vso_script.filename
}

output "vault_connection_manifest" {
  description = "Example VaultConnection manifest for manual application"
  value       = <<-EOF
    apiVersion: secrets.hashicorp.com/v1beta1
    kind: VaultConnection
    metadata:
      name: default
      namespace: vault-secrets-operator-system
    spec:
      address: ${var.vault_url}
      skipTLSVerify: true
  EOF
}

output "vault_auth_manifest" {
  description = "Example VaultAuth manifest for manual application"
  value       = <<-EOF
    apiVersion: secrets.hashicorp.com/v1beta1
    kind: VaultAuth
    metadata:
      name: default
      namespace: vault-secrets-operator-system
    spec:
      vaultConnectionRef: default
      method: kubernetes
      mount: kubernetes
      kubernetes:
        role: ${var.vault_role}
        serviceAccount: vault-auth
        audiences: ["vault"]
  EOF
}
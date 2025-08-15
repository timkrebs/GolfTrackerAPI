output "vault_secrets_operator_namespace" {
  description = "Namespace where Vault Secrets Operator is deployed"
  value       = "vault-secrets-operator-system"
}

output "vault_connection_name" {
  description = "Name of the VaultConnection resource"
  value       = kubernetes_manifest.vault_connection.manifest.metadata.name
}

output "vault_auth_name" {
  description = "Name of the VaultAuth resource"
  value       = kubernetes_manifest.vault_auth.manifest.metadata.name
}

output "service_account_name" {
  description = "Name of the Kubernetes service account for Vault authentication"
  value       = kubernetes_service_account.vault_auth.metadata[0].name
}

output "init_instructions_configmap" {
  description = "Name of the ConfigMap containing Vault initialization instructions"
  value       = kubernetes_config_map.vault_init_instructions.metadata[0].name
}

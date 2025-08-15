output "instance_id" {
  description = "EC2 instance ID for Vault"
  value       = aws_instance.vault.id
}

output "public_ip" {
  description = "Public IP address of Vault instance"
  value       = aws_eip.vault.public_ip
}

output "private_ip" {
  description = "Private IP address of Vault instance"
  value       = aws_instance.vault.private_ip
}

output "security_group_id" {
  description = "Security group ID for Vault instance"
  value       = var.security_group_id
}

output "vault_url" {
  description = "URL to access Vault"
  value       = "http://${aws_eip.vault.public_ip}:8200"
}

output "vault_internal_url" {
  description = "Internal URL to access Vault"
  value       = "http://${aws_instance.vault.private_ip}:8200"
}

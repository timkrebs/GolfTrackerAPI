output "eks_kms_key_id" {
  description = "KMS key ID for EKS"
  value       = aws_kms_key.eks.key_id
}

output "eks_kms_key_arn" {
  description = "KMS key ARN for EKS"
  value       = aws_kms_key.eks.arn
}

output "rds_kms_key_id" {
  description = "KMS key ID for RDS"
  value       = aws_kms_key.rds.key_id
}

output "rds_kms_key_arn" {
  description = "KMS key ARN for RDS"
  value       = aws_kms_key.rds.arn
}

output "s3_kms_key_id" {
  description = "KMS key ID for S3"
  value       = aws_kms_key.s3.key_id
}

output "s3_kms_key_arn" {
  description = "KMS key ARN for S3"
  value       = aws_kms_key.s3.arn
}

output "vault_kms_key_id" {
  description = "KMS key ID for Vault"
  value       = aws_kms_key.vault.key_id
}

output "vault_kms_key_arn" {
  description = "KMS key ARN for Vault"
  value       = aws_kms_key.vault.arn
}

output "cloudwatch_logs_kms_key_id" {
  description = "KMS key ID for CloudWatch Logs"
  value       = aws_kms_key.cloudwatch_logs.key_id
}

output "cloudwatch_logs_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Logs"
  value       = aws_kms_key.cloudwatch_logs.arn
}

output "ebs_kms_key_id" {
  description = "KMS key ID for EBS"
  value       = aws_kms_key.ebs.key_id
}

output "ebs_kms_key_arn" {
  description = "KMS key ARN for EBS"
  value       = aws_kms_key.ebs.arn
}

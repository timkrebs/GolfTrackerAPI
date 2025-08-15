variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Vault instance"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Vault instance"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for Vault auto-unseal"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Vault"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = null
}

variable "backup_bucket_name" {
  description = "S3 bucket name for Vault backups"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

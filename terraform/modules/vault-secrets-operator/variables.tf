variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vault_url" {
  description = "URL to access Vault"
  type        = string
}

variable "vault_role" {
  description = "Vault role name for authentication"
  type        = string
  default     = "golftracker-backend"
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

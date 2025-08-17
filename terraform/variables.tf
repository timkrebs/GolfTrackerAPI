variable "aws_region" {
  description = "AWS Region für die Infrastruktur"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment muss dev, staging oder prod sein."
  }
}

variable "project_name" {
  description = "Projektname"
  type        = string
  default     = "golf-tracker"
}

variable "container_image" {
  description = "Docker Container Image URI"
  type        = string
}

variable "container_port" {
  description = "Port auf dem der Container läuft"
  type        = number
  default     = 8000
}

variable "desired_capacity" {
  description = "Gewünschte Anzahl von ECS Tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimale Anzahl von ECS Tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximale Anzahl von ECS Tasks"
  type        = number
  default     = 10
}

variable "cpu" {
  description = "CPU Units für ECS Task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory (MB) für ECS Task"
  type        = number
  default     = 512
}

variable "supabase_url" {
  description = "Supabase URL"
  type        = string
  sensitive   = true
}

variable "supabase_key" {
  description = "Supabase API Key"
  type        = string
  sensitive   = true
}

variable "database_url" {
  description = "Database URL"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Domain Name für die API (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM Certificate ARN für HTTPS (optional)"
  type        = string
  default     = ""
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs Retention in Tagen"
  type        = number
  default     = 30
}

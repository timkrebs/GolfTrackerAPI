# Development Environment Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.golf_api.alb_dns_name
}

output "api_url" {
  description = "API URL"
  value       = "http://${module.golf_api.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.golf_api.ecr_repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.golf_api.ecs_cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.golf_api.ecs_service_name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_host
}

output "database_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "load_balancer_url" {
  description = "URL of the load balancer"
  value       = "http://${module.alb.dns_name}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.ecs.service_name
}

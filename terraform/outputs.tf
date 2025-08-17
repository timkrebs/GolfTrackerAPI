output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.app.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID"
  value       = aws_lb.app.zone_id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.app.arn
}

output "ecs_cluster_name" {
  description = "ECS Cluster Name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS Service Name"
  value       = aws_ecs_service.app.name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group Name"
  value       = aws_cloudwatch_log_group.app.name
}

output "api_url" {
  description = "API URL"
  value       = var.certificate_arn != "" ? "https://${aws_lb.app.dns_name}" : "http://${aws_lb.app.dns_name}"
}

output "api_health_check_url" {
  description = "API Health Check URL"
  value       = "${var.certificate_arn != "" ? "https" : "http"}://${aws_lb.app.dns_name}/health"
}

output "api_docs_url" {
  description = "API Documentation URL"
  value       = "${var.certificate_arn != "" ? "https" : "http"}://${aws_lb.app.dns_name}/docs"
}

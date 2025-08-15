output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "log_groups" {
  description = "CloudWatch log group information"
  value = {
    application = aws_cloudwatch_log_group.application.name
    eks_cluster = aws_cloudwatch_log_group.eks_cluster.name
  }
}

output "budget_name" {
  description = "Name of the cost budget"
  value       = aws_budgets_budget.monthly.name
}

# Alternative: AWS Secrets Manager (more features than SSM Parameter Store)
# Uncomment this file if you prefer Secrets Manager over SSM Parameter Store

# Supabase Credentials Secret
resource "aws_secretsmanager_secret" "supabase_credentials" {
  name                    = "${local.name_prefix}/supabase"
  description             = "Supabase credentials for Golf Tracker API"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "supabase_credentials" {
  secret_id = aws_secretsmanager_secret.supabase_credentials.id
  secret_string = jsonencode({
    supabase_url = var.supabase_url
    supabase_key = var.supabase_key
    database_url = var.database_url
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Database Credentials Secret (if you want separate database credentials)
resource "aws_secretsmanager_secret" "database_credentials" {
  name                    = "${local.name_prefix}/database"
  description             = "Database credentials for Golf Tracker API"
  recovery_window_in_days = 7

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    database_url = var.database_url
    db_host      = split("@", split("://", var.database_url)[1])[1]
    db_name      = split("/", var.database_url)[length(split("/", var.database_url)) - 1]
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# IAM Role Policy for Secrets Manager Access
resource "aws_iam_role_policy" "ecs_task_secrets_manager" {
  name = "${local.name_prefix}-ecs-task-secrets-manager"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.supabase_credentials.arn,
          aws_secretsmanager_secret.database_credentials.arn
        ]
      }
    ]
  })
}

# Output secret ARNs
output "supabase_secret_arn" {
  description = "ARN of Supabase credentials secret"
  value       = aws_secretsmanager_secret.supabase_credentials.arn
}

output "database_secret_arn" {
  description = "ARN of Database credentials secret"
  value       = aws_secretsmanager_secret.database_credentials.arn
}

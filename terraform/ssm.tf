# SSM Parameter für Supabase URL
resource "aws_ssm_parameter" "supabase_url" {
  name  = "/${var.project_name}/${var.environment}/supabase_url"
  type  = "SecureString"
  value = var.supabase_url

  tags = local.common_tags
}

# SSM Parameter für Supabase Key
resource "aws_ssm_parameter" "supabase_key" {
  name  = "/${var.project_name}/${var.environment}/supabase_key"
  type  = "SecureString"
  value = var.supabase_key

  tags = local.common_tags
}

# SSM Parameter für Database URL
resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.project_name}/${var.environment}/database_url"
  type  = "SecureString"
  value = var.database_url

  tags = local.common_tags
}

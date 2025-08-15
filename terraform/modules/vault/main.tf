# Data sources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# IAM Role for Vault Instance
resource "aws_iam_role" "vault" {
  name = "${var.project_name}-${var.environment}-vault-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for Vault KMS access
resource "aws_iam_policy" "vault_kms" {
  name = "${var.project_name}-${var.environment}-vault-kms-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = var.kms_key_id
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.backup_bucket_name}",
          "arn:aws:s3:::${var.backup_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vault_kms" {
  policy_arn = aws_iam_policy.vault_kms.arn
  role       = aws_iam_role.vault.name
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "vault" {
  name = "${var.project_name}-${var.environment}-vault-profile"
  role = aws_iam_role.vault.name
}

# User data script for Vault installation
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    kms_key_id         = var.kms_key_id
    backup_bucket_name = var.backup_bucket_name
    project_name       = var.project_name
    environment        = var.environment
  }))
}

# Vault EC2 Instance
resource "aws_instance" "vault" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.vault.name

  user_data = local.user_data

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vault"
    Type = "vault-server"
  })
}

# Elastic IP for Vault
resource "aws_eip" "vault" {
  instance = aws_instance.vault.id
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vault-eip"
  })
}

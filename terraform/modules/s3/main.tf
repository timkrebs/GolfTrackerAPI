# S3 Bucket for Video Storage
resource "aws_s3_bucket" "video_storage" {
  bucket = "${var.project_name}-${var.environment}-video-storage"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-video-storage"
    Purpose = "Video file storage for AI processing"
  })
}

resource "aws_s3_bucket_encryption_configuration" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "video_storage" {
  bucket = aws_s3_bucket.video_storage.id

  dynamic "rule" {
    for_each = var.video_bucket_lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      expiration {
        days = rule.value.expiration.days
      }
    }
  }
}

# S3 Bucket for Backups
resource "aws_s3_bucket" "backup" {
  bucket = "${var.project_name}-${var.environment}-backup"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-backup"
    Purpose = "Backup storage for Vault and application data"
  })
}

resource "aws_s3_bucket_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

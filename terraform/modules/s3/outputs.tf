output "video_bucket_name" {
  description = "Name of the video storage bucket"
  value       = aws_s3_bucket.video_storage.bucket
}

output "video_bucket_arn" {
  description = "ARN of the video storage bucket"
  value       = aws_s3_bucket.video_storage.arn
}

output "backup_bucket_name" {
  description = "Name of the backup bucket"
  value       = aws_s3_bucket.backup.bucket
}

output "backup_bucket_arn" {
  description = "ARN of the backup bucket"
  value       = aws_s3_bucket.backup.arn
}

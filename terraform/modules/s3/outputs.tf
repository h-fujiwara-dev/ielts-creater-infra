output "bucket_name" {
  description = "S3バケット名（backendの app.storage.s3.bucket-name に設定）"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "S3バケットARN（ECSタスクロールのIAMポリシーで参照）"
  value       = aws_s3_bucket.this.arn
}

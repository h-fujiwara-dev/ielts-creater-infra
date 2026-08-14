data "aws_caller_identity" "current" {}

locals {
  bucket_name = coalesce(var.bucket_name, "ielts-creater-listening-audio-${var.environment}-${data.aws_caller_identity.current.account_id}")
}

# Listening音声（S3StorageService、backend実装規約.md 2章）用の非公開バケット
resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

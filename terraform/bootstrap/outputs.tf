output "state_bucket_name" {
  description = "tfstateを保管するS3バケット名"
  value       = aws_s3_bucket.tfstate.bucket
}

output "lock_table_name" {
  description = "tfstateロック用DynamoDBテーブル名"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "aws_region" {
  description = "バックエンドを構築したAWSリージョン"
  value       = var.aws_region
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC IDプロバイダのARN（各envのCI/CD用IAM Roleが参照する）"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

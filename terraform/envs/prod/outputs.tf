output "user_pool_id" {
  description = "Cognito User Pool ID（backendの app.auth.cognito.user-pool-id に設定）"
  value       = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  description = "App Client ID（backendの app.auth.cognito.client-id / frontendの COGNITO_CLIENT_ID に設定）"
  value       = module.cognito.user_pool_client_id
}

output "user_pool_client_secret" {
  description = "App Clientシークレット（frontendの COGNITO_CLIENT_SECRET に設定）"
  value       = module.cognito.user_pool_client_secret
  sensitive   = true
}

output "issuer_url" {
  description = "OIDC issuer URL（frontendの COGNITO_ISSUER に設定）"
  value       = module.cognito.issuer_url
}

output "hosted_ui_domain" {
  description = "Hosted UIドメイン"
  value       = module.cognito.hosted_ui_domain
}

output "api_endpoint" {
  description = "backend APIのエンドポイント（frontendの本番 BACKEND_API_ORIGIN に設定）"
  value       = module.api-gateway.api_endpoint
}

output "ecr_repository_url" {
  description = "backendイメージのpush先ECRリポジトリURL"
  value       = module.ecr.repository_url
}

output "storage_bucket_name" {
  description = "Listening音声用S3バケット名"
  value       = module.s3.bucket_name
}

output "ecs_cluster_name" {
  description = "ECSクラスタ名（CI/CDワークフローのaws ecs update-serviceで使用）"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECSサービス名（CI/CDワークフローのaws ecs update-serviceで使用）"
  value       = module.ecs.service_name
}

output "github_actions_deploy_role_arn" {
  description = "backend CI/CDワークフローがOIDCで引き受けるIAM RoleのARN"
  value       = aws_iam_role.github_actions_deploy.arn
}

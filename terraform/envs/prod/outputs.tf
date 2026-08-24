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

output "cognito_custom_domain_acm_validation_records" {
  description = "auth.band-eight.com用ACM証明書のDNS検証レコード（DNSプロバイダに追加した後にterraform applyで検証を待つ）"
  value = [
    for o in aws_acm_certificate.cognito_custom_domain.domain_validation_options : {
      name  = o.resource_record_name
      type  = o.resource_record_type
      value = o.resource_record_value
    }
  ]
}

output "cognito_custom_domain_cloudfront_target" {
  description = "auth.band-eight.comのCNAME先（Cognitoカスタムドメイン用CloudFrontディストリビューション）"
  value       = module.cognito.custom_domain_cloudfront_distribution
}

output "ses_domain_verification_record" {
  description = "band-eight.comのSESドメイン所有権検証用TXTレコード（_amazonses.band-eight.com）"
  value = {
    name  = "_amazonses.${aws_ses_domain_identity.this.domain}"
    type  = "TXT"
    value = aws_ses_domain_identity.this.verification_token
  }
}

output "ses_dkim_records" {
  description = "band-eight.comのSES DKIM検証用CNAMEレコード（3件）"
  value = [
    for token in aws_ses_domain_dkim.this.dkim_tokens : {
      name  = "${token}._domainkey.${aws_ses_domain_identity.this.domain}"
      type  = "CNAME"
      value = "${token}.dkim.amazonses.com"
    }
  ]
}

output "guest_user_pool_client_id" {
  description = "ゲスト用App Client ID（backendの app.guest.cognito.client-id に設定、#00056/#00058。実際の注入はECS環境変数 GUEST_COGNITO_CLIENT_ID 経由で自動化済み）"
  value       = module.cognito.guest_user_pool_client_id
}

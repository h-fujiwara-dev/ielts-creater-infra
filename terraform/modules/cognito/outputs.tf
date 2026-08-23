output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_client_id" {
  description = "App Client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "user_pool_client_secret" {
  description = "App Clientシークレット"
  value       = aws_cognito_user_pool_client.web.client_secret
  sensitive   = true
}

output "issuer_url" {
  description = "OIDC issuer URL（backendのJWT検証・frontendのNextAuth Cognitoプロバイダで使用）"
  value       = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"
}

output "hosted_ui_domain" {
  description = "Hosted UIのドメイン（custom_domain指定時はそのドメイン、未指定時は<domain>.auth.<region>.amazoncognito.com）"
  value       = coalesce(var.custom_domain, "${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com")
}

output "custom_domain_cloudfront_distribution" {
  description = "custom_domain使用時、DNSにCNAMEで向ける先のCloudFrontディストリビューションドメイン名（custom_domain未指定時はnull）"
  value       = var.custom_domain != null ? aws_cognito_user_pool_domain.this.cloudfront_distribution : null
}

output "guest_user_pool_client_id" {
  description = "ゲスト用App Client ID（backendの app.guest.cognito.client-id に設定、#00056）"
  value       = aws_cognito_user_pool_client.guest.id
}

output "guest_username" {
  description = "ゲスト共有デモアカウントのユーザー名（backendの GUEST_COGNITO_USERNAME に設定）"
  value       = aws_cognito_user.guest.username
}

output "guest_password" {
  description = "ゲスト共有デモアカウントのパスワード（backendの GUEST_COGNITO_PASSWORD に設定、Secrets Manager経由で注入）"
  value       = random_password.guest_user.result
  sensitive   = true
}

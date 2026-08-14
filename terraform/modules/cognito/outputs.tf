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
  description = "Hosted UIのドメイン（<domain>.auth.<region>.amazoncognito.com）"
  value       = "${aws_cognito_user_pool_domain.this.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
}

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

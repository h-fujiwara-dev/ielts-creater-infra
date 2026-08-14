locals {
  user_pool_name = coalesce(var.user_pool_name, "ielts-creater-${var.environment}")
}

data "aws_region" "current" {}

resource "aws_cognito_user_pool" "this" {
  name = local.user_pool_name

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  mfa_configuration = "OFF"

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # 未指定時はCognitoデフォルトの送信（no-reply@verificationemail.com、到達率が低い）のまま（#00053）
  dynamic "email_configuration" {
    for_each = var.ses_source_arn != null ? [1] : []
    content {
      email_sending_account = "DEVELOPER"
      source_arn            = var.ses_source_arn
      from_email_address    = var.email_from_address
    }
  }
}

resource "aws_cognito_user_pool_domain" "this" {
  domain          = coalesce(var.custom_domain, "${var.domain_prefix}-${var.environment}")
  certificate_arn = var.custom_domain != null ? var.certificate_arn : null
  user_pool_id    = aws_cognito_user_pool.this.id
}

# NextAuth.js（Authorization Code + PKCE）が使うApp Client。
# aws.cognito.signin.user.admin スコープは backend の UserProvisioningService が
# GetUser API でプロフィール属性（email等）を取得するために必須（ielts-creater-backend側の実装と対）。
resource "aws_cognito_user_pool_client" "web" {
  name         = "ielts-creater-web-${var.environment}"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = true

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile", "aws.cognito.signin.user.admin"]

  supported_identity_providers = ["COGNITO"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  prevent_user_existence_errors = "ENABLED"

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# Hosted UI（Classic）の配色をfrontendのデザイントークンに合わせる（#00052）。
# ロゴ画像は未用意のため配色調整のみ。domainの作成後でないと設定できない。
resource "aws_cognito_user_pool_ui_customization" "web" {
  client_id    = aws_cognito_user_pool_client.web.id
  user_pool_id = aws_cognito_user_pool.this.id
  css          = file("${path.module}/hosted-ui.css")

  depends_on = [aws_cognito_user_pool_domain.this]
}

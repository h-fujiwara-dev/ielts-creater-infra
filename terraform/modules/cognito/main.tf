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

  # 確認コードメールをSES経由（band-eight.comドメイン）で送信する（#00053）。未指定時は
  # Cognitoデフォルトの送信（no-reply@verificationemail.com、到達率が低い）のまま。
  dynamic "email_configuration" {
    for_each = var.ses_source_arn != null ? [1] : []
    content {
      email_sending_account = "DEVELOPER"
      source_arn            = var.ses_source_arn
      from_email_address    = var.email_from_address
    }
  }

  # 確認コードメールをResend経由で送信する（#00057）。未指定環境（#00058時点のprod等）では
  # Cognitoデフォルトの送信のままとし、lambda_configブロック自体を生成しない。
  dynamic "lambda_config" {
    for_each = var.custom_email_sender_lambda_arn != null ? [1] : []
    content {
      kms_key_id = var.custom_email_sender_kms_key_arn
      custom_email_sender {
        lambda_arn     = var.custom_email_sender_lambda_arn
        lambda_version = "V1_0"
      }
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

# ゲスト機能（#00056）用のパブリッククライアント。Hosted UI/OAuthは使わず、
# backendのGuestAuthServiceがInitiateAuth(USER_PASSWORD_AUTH)でプログラム的に
# 固定の共有デモアカウントを認証するためだけに使う。既存のwebクライアント
# （Authorization Code + PKCE、Hosted UI前提）とは完全に分離する。
resource "aws_cognito_user_pool_client" "guest" {
  name         = "ielts-creater-guest-${var.environment}"
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  prevent_user_existence_errors = "ENABLED"

  access_token_validity = 60
  id_token_validity     = 60

  token_validity_units {
    access_token = "minutes"
    id_token     = "minutes"
  }
}

# パスワードポリシー（8文字以上・大小英字・数字必須）を満たすランダムパスワードを生成する。
# 人が入力することはなく、backendがSecrets Manager経由で参照するのみのため記号は含めない。
resource "random_password" "guest_user" {
  length      = 24
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

# ゲスト共有デモアカウント本体。管理者作成のため招待メールは送信しない（message_action=SUPPRESS）。
# passwordを直接指定するとCONFIRMED状態の恒久パスワードとして設定される
# （temporary_passwordと異なり初回ログイン時の強制変更を要求しない）。
resource "aws_cognito_user" "guest" {
  user_pool_id   = aws_cognito_user_pool.this.id
  username       = var.guest_email
  message_action = "SUPPRESS"
  password       = random_password.guest_user.result

  attributes = {
    email          = var.guest_email
    email_verified = "true"
  }
}

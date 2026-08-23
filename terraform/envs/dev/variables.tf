variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "cognito_domain_prefix" {
  description = "Cognito Hosted UIドメインのプレフィックス（グローバルで一意である必要がある）"
  type        = string
  default     = "ielts-creater"
}

variable "callback_urls" {
  description = "OAuthログイン成功後のリダイレクト先URL一覧"
  type        = list(string)
  # cognito-signupは「無料ではじめる」ボタン用の2つ目のNextAuthプロバイダ
  # （frontend側 #00062、Hosted UIの/signupエンドポイントへ直接誘導する）のコールバック。
  default = [
    "http://localhost:3000/api/auth/callback/cognito",
    "http://localhost:3000/api/auth/callback/cognito-signup",
  ]
}

variable "logout_urls" {
  description = "ログアウト後のリダイレクト先URL一覧"
  type        = list(string)
  # frontend側cognito-logout route（GET /api/auth/cognito-logout）は/loginへリダイレクトする
  # 実装のため、実際にCognito App Clientへ登録すべき値は/login付き。デフォルト値がこの実態と
  # 乖離していたため実態に合わせる（#00062で発覚）。
  default = ["http://localhost:3000/login"]
}

variable "supabase_db_url" {
  description = "SupabaseのJDBC接続URL（例: jdbc:postgresql://<host>:5432/postgres?sslmode=require）"
  type        = string
  sensitive   = true
}

variable "supabase_db_username" {
  description = "Supabase接続ユーザー名"
  type        = string
  sensitive   = true
}

variable "supabase_db_password" {
  description = "Supabase接続パスワード"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI APIキー（APP_GENERATION_MODE=openai時にbackendが使用。Secrets Managerへ格納する）"
  type        = string
  sensitive   = true
}

variable "resend_api_key" {
  description = "Resend APIキー（Cognito確認コードメール送信用、#00057。Secrets Managerへ格納する）"
  type        = string
  sensitive   = true
}

variable "resend_from_email" {
  description = "確認コードメールの送信元アドレス（Resendで検証済みのドメインを使用、#00057）"
  type        = string
}

variable "cors_allowed_origins" {
  description = "backendが許可するCORSオリジン（ローカルfrontendのURL、#00043参照）"
  type        = string
  default     = "http://localhost:3000"
}

variable "backend_image_tag" {
  description = "ECSにデプロイするbackendイメージのタグ"
  type        = string
  default     = "latest"
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "cognito_domain_prefix" {
  description = "Cognito Hosted UIドメインのプレフィックス（グローバルで一意である必要がある）"
  type        = string
  default     = "ielts-creater-prod"
}

variable "callback_urls" {
  description = "OAuthログイン成功後のリダイレクト先URL一覧（#00051で確定したband-eight.comを見込む）"
  type        = list(string)
  default     = ["https://band-eight.com/api/auth/callback/cognito"]
}

variable "logout_urls" {
  description = "ログアウト後のリダイレクト先URL一覧（#00051で確定したband-eight.comを見込む）"
  type        = list(string)
  default     = ["https://band-eight.com/login"]
}

variable "supabase_db_url" {
  description = "Supabase（prod専用プロジェクト）のJDBC接続URL（例: jdbc:postgresql://<host>:5432/postgres?sslmode=require）"
  type        = string
  sensitive   = true
}

variable "supabase_db_username" {
  description = "Supabase（prod専用プロジェクト）接続ユーザー名"
  type        = string
  sensitive   = true
}

variable "supabase_db_password" {
  description = "Supabase（prod専用プロジェクト）接続パスワード"
  type        = string
  sensitive   = true
}

variable "openai_api_key" {
  description = "OpenAI APIキー（APP_GENERATION_MODE=openai時にbackendが使用。Secrets Managerへ格納する）"
  type        = string
  sensitive   = true
}

variable "cors_allowed_origins" {
  description = "backendが許可するCORSオリジン（本番frontendのURL）"
  type        = string
  default     = "https://band-eight.com"
}

variable "backend_image_tag" {
  description = "ECSにデプロイするbackendイメージのタグ"
  type        = string
  default     = "latest"
}

variable "github_actions_deploy_repo" {
  description = "CI/CD用IAM Role（OIDC）を引き受けられるGitHubリポジトリ（owner/repo）"
  type        = string
  default     = "h-fujiwara-dev/ielts-creater-backend"
}

variable "github_actions_deploy_ref" {
  description = "CI/CD用IAM Role（OIDC）を引き受けられるGitHub ref（ブランチ）"
  type        = string
  default     = "refs/heads/main"
}

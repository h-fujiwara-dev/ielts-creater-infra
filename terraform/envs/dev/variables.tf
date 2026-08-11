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
  default     = ["http://localhost:3000/api/auth/callback/cognito"]
}

variable "logout_urls" {
  description = "ログアウト後のリダイレクト先URL一覧"
  type        = list(string)
  default     = ["http://localhost:3000"]
}

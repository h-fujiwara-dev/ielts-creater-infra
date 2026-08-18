variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "user_pool_name" {
  description = "Cognito User Pool名（未指定時は ielts-creater-<environment> を使用）"
  type        = string
  default     = null
}

variable "domain_prefix" {
  description = "Hosted UIドメインのプレフィックス（グローバルで一意である必要がある）"
  type        = string
}

variable "callback_urls" {
  description = "OAuthログイン成功後のリダイレクト先URL一覧"
  type        = list(string)
}

variable "logout_urls" {
  description = "ログアウト後のリダイレクト先URL一覧"
  type        = list(string)
}

variable "guest_email" {
  description = "ゲスト共有デモアカウントのメールアドレス（username_attributes=emailのためusernameとしても使用、#00056）"
  type        = string
  default     = "guest@ielts-creater.invalid"
}

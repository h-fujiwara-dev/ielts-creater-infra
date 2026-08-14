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

variable "custom_domain" {
  description = "Hosted UIのカスタムドメイン（例: auth.band-eight.com）。指定時はdomain_prefixの代わりにこちらを使用する（certificate_arnとセットで指定する）"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "custom_domain用のACM証明書ARN。CognitoのカスタムドメインはCloudFront経由のためus-east-1リージョンの証明書である必要がある（AWSの制約）"
  type        = string
  default     = null
}

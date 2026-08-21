variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "resend_api_key" {
  description = "Resend APIキー（Secrets Manager経由でLambdaに注入する）"
  type        = string
  sensitive   = true
}

variable "resend_from_email" {
  description = "確認コードメールの送信元アドレス（Resendで検証済みのドメインを使用すること）"
  type        = string
}

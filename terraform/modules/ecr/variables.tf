variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "repository_name" {
  description = "ECRリポジトリ名（未指定時は ielts-creater-api-<environment> を使用）"
  type        = string
  default     = null
}

variable "untagged_image_expiry_days" {
  description = "タグなしイメージを自動削除するまでの日数（コスト対策）"
  type        = number
  default     = 14
}

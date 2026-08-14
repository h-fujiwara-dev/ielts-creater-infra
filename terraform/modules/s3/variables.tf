variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "bucket_name" {
  description = "S3バケット名（未指定時は ielts-creater-listening-audio-<environment>-<account_id> を使用。バケット名はグローバルで一意である必要がある）"
  type        = string
  default     = null
}

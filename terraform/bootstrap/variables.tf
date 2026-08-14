variable "aws_region" {
  description = "tfstateバックエンドを構築するAWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "state_bucket_name" {
  description = "tfstateを保管するS3バケット名（グローバルで一意である必要がある）"
  type        = string
}

variable "lock_table_name" {
  description = "tfstateロック用DynamoDBテーブル名"
  type        = string
  default     = "ielts-creater-tfstate-lock"
}

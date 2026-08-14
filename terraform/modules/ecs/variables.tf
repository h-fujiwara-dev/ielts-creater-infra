variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID（modules/networkの出力）"
  type        = string
}

variable "private_subnet_ids" {
  description = "ECSタスクを配置するPrivate Subnet ID一覧（modules/networkの出力）"
  type        = list(string)
}

variable "cloud_map_namespace_id" {
  description = "ECS Service Discovery登録先のCloud Mapプライベートdns名前空間ID（modules/networkの出力）"
  type        = string
}

variable "vpclink_security_group_id" {
  description = "API GatewayのVPC LinkのセキュリティグループID（envs/dev側で作成し、ecs-sgのingress許可元に使う。api-gateway⇔ecsの循環参照を避けるためenv層で共有する）"
  type        = string
}

variable "ecr_repository_url" {
  description = "backendイメージのECRリポジトリURL（modules/ecrの出力）"
  type        = string
}

variable "image_tag" {
  description = "デプロイするbackendイメージのタグ"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "backendコンテナのリッスンポート"
  type        = number
  default     = 8080
}

variable "s3_bucket_arn" {
  description = "Listening音声用S3バケットARN（タスクロールにGetObject/PutObjectを付与する対象。modules/s3の出力）"
  type        = string
}

variable "environment_variables" {
  description = "コンテナに渡す非機密の環境変数"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets Managerから注入する環境変数。secret_arnはIAMポリシーのResourceに、valueFromはコンテナ定義のsecretsにそのまま使う"
  type = list(object({
    name       = string
    valueFrom  = string
    secret_arn = string
  }))
  default = []
}

variable "cpu" {
  description = "Fargateタスクのvcpu（256単位）。0.25vCPU/0.5GBの最小構成でコストを抑える"
  type        = number
  default     = 256
}

variable "memory" {
  description = "FargateタスクのMB単位メモリ"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "ECS Serviceの希望タスク数"
  type        = number
  default     = 1
}

variable "log_retention_days" {
  description = "CloudWatch Logsの保持日数"
  type        = number
  default     = 14
}

variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "private_subnet_ids" {
  description = "VPC LinkのENIを配置するPrivate Subnet ID一覧（modules/networkの出力）"
  type        = list(string)
}

variable "vpclink_security_group_id" {
  description = "VPC LinkのセキュリティグループID（envs/dev側で作成し、modules/ecsのecs-sgと共有する）"
  type        = string
}

variable "cloud_map_service_arn" {
  description = "Private integration先のCloud MapサービスARN（modules/ecsの出力）"
  type        = string
}

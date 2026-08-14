variable "environment" {
  description = "環境名（dev/prod等）"
  type        = string
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "使用するAZ（Public/Private Subnetを各AZに1つずつ作成する）"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "Public SubnetのCIDRブロック（azsと同じ順序・同じ要素数）"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private SubnetのCIDRブロック（azsと同じ順序・同じ要素数）"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "nat_instance_type" {
  description = "NAT InstanceのEC2インスタンスタイプ（NAT Gatewayの代わりにコスト削減のため自前で構築する。このAWSアカウントはFree Tier対象インスタンスタイプのみ許可されているためt4g.microを使う）"
  type        = string
  default     = "t4g.micro"
}

variable "cloud_map_namespace_name" {
  description = "ECS Service Discovery用Cloud Mapのプライベートdns名前空間"
  type        = string
  default     = null
}

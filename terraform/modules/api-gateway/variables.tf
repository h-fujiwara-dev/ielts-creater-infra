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

variable "jwt_issuer" {
  description = "Cognito JWT Authorizerが検証するissuer URL（modules/cognitoのissuer_url出力）"
  type        = string
}

variable "jwt_audience" {
  description = "Cognito JWT Authorizerが受理するapp client ID一覧（アクセストークンのclient_idクレームと照合される）"
  type        = list(string)
}

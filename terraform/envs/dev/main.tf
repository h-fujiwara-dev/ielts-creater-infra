module "cognito" {
  source = "../../modules/cognito"

  environment   = "dev"
  domain_prefix = var.cognito_domain_prefix
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  custom_email_sender_lambda_arn  = module.email_sender.lambda_arn
  custom_email_sender_kms_key_arn = module.email_sender.kms_key_arn
}

module "email_sender" {
  source = "../../modules/email-sender"

  environment       = "dev"
  resend_api_key    = var.resend_api_key
  resend_from_email = var.resend_from_email
}

module "network" {
  source = "../../modules/network"

  environment = "dev"
}

module "ecr" {
  source = "../../modules/ecr"

  environment = "dev"
}

module "s3" {
  source = "../../modules/s3"

  environment = "dev"
}

# API Gateway VPC LinkとECSタスクの双方から参照する共有セキュリティグループ。
# modules/ecsとmodules/api-gatewayを循環参照させないため、env層でwiringする
resource "aws_security_group" "vpclink" {
  name        = "ielts-creater-dev-vpclink-sg"
  description = "API Gateway VPC Link ENIs (egress only; inbound rules live on the target security group)"
  vpc_id      = module.network.vpc_id

  egress {
    description = "To ECS tasks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ielts-creater-dev-vpclink-sg"
  }
}

# Supabase接続情報・OpenAI APIキーはファイルに書かず、Secrets Manager経由でECSタスク定義から注入する
# （backend実装規約.md 7章、terraform.tfvarsはgitignore対象）
resource "aws_secretsmanager_secret" "supabase_db" {
  name = "ielts-creater-dev-supabase-db"
}

resource "aws_secretsmanager_secret_version" "supabase_db" {
  secret_id = aws_secretsmanager_secret.supabase_db.id
  secret_string = jsonencode({
    url      = var.supabase_db_url
    username = var.supabase_db_username
    password = var.supabase_db_password
  })
}

resource "aws_secretsmanager_secret" "openai_api_key" {
  name = "ielts-creater-dev-openai-api-key"
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = var.openai_api_key
}

module "ecs" {
  source = "../../modules/ecs"

  environment               = "dev"
  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_subnet_ids
  cloud_map_namespace_id    = module.network.cloud_map_namespace_id
  vpclink_security_group_id = aws_security_group.vpclink.id
  ecr_repository_url        = module.ecr.repository_url
  image_tag                 = var.backend_image_tag
  s3_bucket_arn             = module.s3.bucket_arn

  environment_variables = {
    SPRING_PROFILES_ACTIVE = "prod"
    COGNITO_ISSUER_URI     = module.cognito.issuer_url
    COGNITO_APP_CLIENT_ID  = module.cognito.user_pool_client_id
    COGNITO_REGION         = var.aws_region
    CORS_ALLOWED_ORIGINS   = var.cors_allowed_origins
    STORAGE_S3_BUCKET      = module.s3.bucket_name
  }

  secrets = [
    {
      name       = "DB_URL"
      valueFrom  = "${aws_secretsmanager_secret.supabase_db.arn}:url::"
      secret_arn = aws_secretsmanager_secret.supabase_db.arn
    },
    {
      name       = "DB_USERNAME"
      valueFrom  = "${aws_secretsmanager_secret.supabase_db.arn}:username::"
      secret_arn = aws_secretsmanager_secret.supabase_db.arn
    },
    {
      name       = "DB_PASSWORD"
      valueFrom  = "${aws_secretsmanager_secret.supabase_db.arn}:password::"
      secret_arn = aws_secretsmanager_secret.supabase_db.arn
    },
    {
      name       = "OPENAI_API_KEY"
      valueFrom  = aws_secretsmanager_secret.openai_api_key.arn
      secret_arn = aws_secretsmanager_secret.openai_api_key.arn
    },
  ]
}

module "api-gateway" {
  source = "../../modules/api-gateway"

  environment               = "dev"
  private_subnet_ids        = module.network.private_subnet_ids
  vpclink_security_group_id = aws_security_group.vpclink.id
  cloud_map_service_arn     = module.ecs.cloud_map_service_arn
}

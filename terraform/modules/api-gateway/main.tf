locals {
  name_prefix = "ielts-creater-${var.environment}"
}

# ALBの代わりにHTTP API + VPC Link + Cloud Map private integrationでECSタスクへ直接ルーティングする
# （ALB固定費 約$18/月 → VPC Link 約$7.2/月+従量課金でコストを削減。#00044で方針転換）

resource "aws_apigatewayv2_vpc_link" "this" {
  name               = "${local.name_prefix}-vpc-link"
  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.vpclink_security_group_id]
}

resource "aws_apigatewayv2_api" "this" {
  name          = "${local.name_prefix}-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "this" {
  api_id             = aws_apigatewayv2_api.this.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  connection_type    = "VPC_LINK"
  connection_id      = aws_apigatewayv2_vpc_link.this.id
  integration_uri    = var.cloud_map_service_arn

  # ゲスト機能（#00056）のIPアドレス単位クォータのため。HTTP_PROXY + VPC_LINK構成では
  # X-Forwarded-Forが自動付与されず（実機確認で全リクエストがVPC内部IPとして記録される
  # 不具合を確認）、request.getRemoteAddr()もVPC LinkのENI/Cloud Map経路のIPを返すため
  # クライアントの実IPを取得できない。API Gateway自体が把握している$context.http.sourceIp
  # を明示的にヘッダーとして注入する。
  request_parameters = {
    "overwrite:header.x-client-real-ip" = "$context.identity.sourceIp"
  }
}

# backendのSpring Securityはこれまで唯一の認証境界だった（#00075、多層防御のため追加）。
# JWT Authorizerをproxy/rootルートに適用し、認証をAPI Gateway層でも検証する。
# ゲストトークン発行エンドポイント（POST /api/v1/auth/guest-token）はトークンを
# 持たない状態で呼ばれる必要があるため、専用の完全一致ルートで認証を除外する
# （HTTP APIは完全一致ルートを{proxy+}ワイルドカードより優先する）。
resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${local.name_prefix}-cognito-authorizer"

  jwt_configuration {
    audience = var.jwt_audience
    issuer   = var.jwt_issuer
  }
}

resource "aws_apigatewayv2_route" "guest_token" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "POST /api/v1/auth/guest-token"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito.id
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

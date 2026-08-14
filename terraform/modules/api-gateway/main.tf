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
}

resource "aws_apigatewayv2_route" "proxy" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_route" "root" {
  api_id    = aws_apigatewayv2_api.this.id
  route_key = "ANY /"
  target    = "integrations/${aws_apigatewayv2_integration.this.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

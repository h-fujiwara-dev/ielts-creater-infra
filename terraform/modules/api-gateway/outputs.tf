output "api_endpoint" {
  description = "backend APIのエンドポイント（frontendの BACKEND_API_ORIGIN に設定。#00043で使用）"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "vpc_link_id" {
  description = "VPC Link ID"
  value       = aws_apigatewayv2_vpc_link.this.id
}

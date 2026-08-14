output "cluster_name" {
  description = "ECSクラスタ名"
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECSサービス名"
  value       = aws_ecs_service.this.name
}

output "cloud_map_service_arn" {
  description = "Cloud MapサービスARN（modules/api-gatewayのintegration_uriに渡す）"
  value       = aws_service_discovery_service.this.arn
}

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

output "cluster_arn" {
  description = "ECSクラスタARN（CI/CDのIAMロールをリソース限定するために使用）"
  value       = aws_ecs_cluster.this.arn
}

output "service_arn" {
  description = "ECSサービスARN（CI/CDのIAMロールをリソース限定するために使用）"
  value       = aws_ecs_service.this.id
}

output "execution_role_arn" {
  description = "ECSタスク実行ロールARN（CI/CDのIAMロールにiam:PassRoleを付与する対象）"
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "ECSタスクロールARN（CI/CDのIAMロールにiam:PassRoleを付与する対象）"
  value       = aws_iam_role.task.arn
}

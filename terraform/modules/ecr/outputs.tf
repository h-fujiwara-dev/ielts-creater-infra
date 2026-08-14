output "repository_url" {
  description = "ECRリポジトリURL（docker push/pullで使用）"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ECRリポジトリARN"
  value       = aws_ecr_repository.this.arn
}

output "repository_name" {
  description = "ECRリポジトリ名"
  value       = aws_ecr_repository.this.name
}

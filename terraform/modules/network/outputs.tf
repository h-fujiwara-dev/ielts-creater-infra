output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPCのCIDRブロック"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Public SubnetのID一覧"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private SubnetのID一覧"
  value       = aws_subnet.private[*].id
}

output "nat_instance_id" {
  description = "NAT InstanceのID（SSM Session Manager接続時に使用）"
  value       = aws_instance.nat.id
}

output "cloud_map_namespace_id" {
  description = "ECS Service Discovery用Cloud Mapプライベートdns名前空間のID"
  value       = aws_service_discovery_private_dns_namespace.this.id
}

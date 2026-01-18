output "primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "port" {
  value = aws_elasticache_replication_group.redis.port
}

output "auth_token" {
  value = aws_elasticache_replication_group.redis.auth_token
}

output "global_group_id" {
  value = var.replica ? data.terraform_remote_state.primary[0].outputs.redis-01_global_group_id : one(aws_elasticache_global_replication_group.global[*].global_replication_group_id)
}

output "replication_group_id" {
  value = aws_elasticache_replication_group.redis.replication_group_id
}

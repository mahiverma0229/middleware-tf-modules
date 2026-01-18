output "port" {
  value = aws_rds_cluster.postgresql.port
}

output "endpoint" {
  value = var.replica ? aws_rds_cluster.postgresql.reader_endpoint : aws_rds_cluster.postgresql.endpoint
}
output "reader_endpoint" {
  value = aws_rds_cluster.postgresql.reader_endpoint
}
output "username" {
  value = aws_rds_cluster.postgresql.master_username
}

output "password" {
  value = var.replica ? data.terraform_remote_state.primary[0].outputs.postgres-03_password : aws_rds_cluster.postgresql.master_password
}

output "postgres_db_name" {
  value = aws_rds_cluster.postgresql.database_name
}

output "postgres_aurora_global_cluster_id" {
  value = one(aws_rds_global_cluster.postgresql[*].id)
}

output "postgres_arn" {
  value = aws_rds_cluster.postgresql.arn
}

output "postgres_encrypt" {
  value = aws_rds_cluster.postgresql.storage_encrypted
}

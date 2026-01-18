output "emr_master_sg" {
  value = var.emr_enabled ? aws_security_group.emr_master_sg.id : null
}
output "emr_slave_sg" {
  value = var.emr_enabled ? aws_security_group.emr_slave_sg.id : null
}
output "emr_service_access_sg" {
  value = var.emr_enabled ? aws_security_group.emr_service_access_sg.id : null
}
output "emr_cluster" {
  value = var.emr_enabled ? aws_emr_cluster.emr_cluster.id : null
}
output "emr_master_public_dns" {
  description = "Public DNS name of the EMR master node (can be used for private access within VPC)"
  value       = var.emr_enabled ? aws_emr_cluster.emr_cluster.master_public_dns : null
}
output "emr_cluster_arn" {
  description = "ARN of the EMR cluster"
  value       = var.emr_enabled ? aws_emr_cluster.emr_cluster.arn : null
}
output "emr_port" {
  description = "Port used for EMR master node communication"
  value       = var.emr_enabled ? var.emr_port : null
}

output "emr_warehouse_location" {
  description = "Spark warehouse location for EMR"
  value       = var.emr_enabled ? local.iceberg_warehouse_location : null
}

output "emr_logs_location" {
  description = "S3 logs location for EMR"
  value       = var.emr_enabled ? local.logs_location : null
}

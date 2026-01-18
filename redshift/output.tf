output "redshift_user" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.redshift_secrets.secret_string)["username"]
  sensitive = true
}
output "redshift_password" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.redshift_secrets.secret_string)["password"]
  sensitive = true
}
output "redshift_port" {
  value = try(aws_redshift_cluster.aws_redshift_cluster[0].port, null)
}
output "redshift_ClusterIdentifier" {
  value = try(aws_redshift_cluster.aws_redshift_cluster[0].cluster_identifier, null)
}
output "redshift_db" {
  value = try(aws_redshift_cluster.aws_redshift_cluster[0].database_name, null)
}
output "redshift_endpoint" {
  description = "The connection endpoint"
  value       = try(aws_redshift_cluster.aws_redshift_cluster[0].endpoint, null)
}
output "redshift_cluster_dns_name" {
  description = "The DNS name of the cluster"
  value       = try(aws_redshift_cluster.aws_redshift_cluster[0].dns_name, null)
}
output "redshift_cluster_namespaceid" {
  description = "The DNS name of the cluster"
  value       = try(split(":", aws_redshift_cluster.aws_redshift_cluster[0].cluster_namespace_arn)[6], null)
}
output "redshift_cluster_accountid" {
  description = "The DNS name of the cluster"
  value       = try(split(":", aws_redshift_cluster.aws_redshift_cluster[0].cluster_namespace_arn)[4], null)
}
output "redshift_snapshot_copy_grant" {
  description = "Snapshot copy grant from the destination region"
  value       = try(aws_redshift_snapshot_copy_grant.redshift_snapshot_copy_grant[0].snapshot_copy_grant_name, null)
}

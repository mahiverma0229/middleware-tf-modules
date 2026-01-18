output "redshift_srvls_user" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.rss_secrets[0].secret_string)["username"]
  sensitive = true
}
output "redshift_srvls_password" {
  value     = jsondecode(data.aws_secretsmanager_secret_version.rss_secrets[0].secret_string)["password"]
  sensitive = true
}
output "redshift_srvls_port" {
  value = try(aws_redshiftserverless_workgroup.redshift_serverless_workgroup[0].port, null)
}
output "redshift_srvls_db" {
  value = try(aws_redshiftserverless_namespace.redshift_serverless_namespace[0].db_name, null)
}

output "redshift_srvls_workgroup" {
  value = try(aws_redshiftserverless_workgroup.redshift_serverless_workgroup[0].arn, null)
}
output "redshift_srvls_endpoint" {
  description = "The connection endpoint"
  value       = try(aws_redshiftserverless_workgroup.redshift_serverless_workgroup[0].endpoint[0].address, null)
}
output "redshift_srvls_namespaceid" {
  value = try(aws_redshiftserverless_namespace.redshift_serverless_namespace[0].namespace_id, null)
}
output "redshift_srvls_accountid" {
  value = try(split(":", aws_redshiftserverless_namespace.redshift_serverless_namespace[0].arn)[4], null)
}
output "redshift_srvls_externalDB" {
  value = var.rss_external_db
}


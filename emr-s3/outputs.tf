output "bucket_name" {
  description = "Name of the EMR datalake S3 bucket"
  value       = aws_s3_bucket.emr_datalake_bucket.id
}

output "bucket_arn" {
  description = "ARN of the EMR datalake S3 bucket"
  value       = aws_s3_bucket.emr_datalake_bucket.arn
}

output "bootstrap_scripts_location" {
  description = "S3 path to bootstrap scripts folder"
  value       = "s3://${aws_s3_bucket.emr_datalake_bucket.id}/bootstrap"
}

output "warehouse_location" {
  description = "S3 path to Iceberg warehouse folder"
  value       = "s3://${aws_s3_bucket.emr_datalake_bucket.id}/iceberg-${local.environment_name}-warehouse"
}

output "logs_location" {
  description = "S3 path to EMR logs folder"
  value       = "s3://${aws_s3_bucket.emr_datalake_bucket.id}/${local.environment_name}-logs"
}

output "bootstrap_script_paths" {
  description = "Map of bootstrap script names to their S3 paths"
  value = {
    archive_emr_bootstrap_system = "s3://${aws_s3_bucket.emr_datalake_bucket.id}/bootstrap/archive_emr_bootstrap_system.sh"
    spark_connect_restart        = "s3://${aws_s3_bucket.emr_datalake_bucket.id}/bootstrap/spark-connect-restart.sh"
  }
}
output "kms_key_arn" {
  value     = var.kms_replica ? var.kms_primary_key_arn != null ? aws_kms_replica_key.kms_replica_key[0].arn : null : aws_kms_key.kms_key[0].arn
  sensitive = true
}

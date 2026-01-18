resource "aws_kms_key" "kms_key" {
  count                    = var.kms_replica ? 0 : 1
  description              = var.kms_key_description
  key_usage                = var.kms_key_usage
  customer_master_key_spec = var.kms_customer_master_key_spec
  policy                   = var.kms_key_policy
  deletion_window_in_days  = var.kms_key_waiting_period
  is_enabled               = var.kms_key_is_enabled
  enable_key_rotation      = var.kms_enable_key_rotation
  multi_region             = var.kms_enable_multi_region

  lifecycle {
    ignore_changes = [
      key_usage,
      customer_master_key_spec,
      multi_region,
    ]
  }
}

resource "aws_kms_replica_key" "kms_replica_key" {
  count                   = var.kms_replica ? var.kms_primary_key_arn != null ? 1 : 0 : 0
  description             = var.kms_key_description
  primary_key_arn         = var.kms_primary_key_arn
  deletion_window_in_days = var.kms_key_waiting_period
  policy                  = var.kms_key_policy
  enabled                 = var.kms_key_is_enabled
}

resource "aws_kms_alias" "kms_key_alias" {
  count         = var.kms_key_alias != null ? var.kms_replica ? var.kms_primary_key_arn != null ? 1 : 0 : 1 : 0
  name          = var.kms_key_alias
  target_key_id = var.kms_replica ? aws_kms_replica_key.kms_replica_key[0].key_id : aws_kms_key.kms_key[0].key_id
}

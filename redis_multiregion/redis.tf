data "terraform_remote_state" "primary" {
  count   = var.replica ? 1 : 0
  backend = "s3"
  config = {
    bucket  = var.remote_state_bucket
    region  = var.remote_state_region
    key     = var.remote_state_key
    encrypt = true
    profile = var.remote_state_profile
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = var.redis_name != null ? "${var.redis_name}-redis-cache-subnet-group" : "${var.cluster_id}-${var.namespace_id}-redis"
  subnet_ids = var.redis_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id        = var.redis_name != null ? var.redis_name : "${var.cluster_id}-${var.namespace_id}-redis"
  global_replication_group_id = var.redis_snapshot_name != null ? null : var.replica ? data.terraform_remote_state.primary[0].outputs.redis-01_global_group_id : null
  description                 = var.redis_description
  apply_immediately           = var.redis_apply_immediately
  at_rest_encryption_enabled  = var.replica ? null : var.redis_at_rest_encryption_enabled
  auth_token                  = var.redis_transit_encryption_enabled ? var.replica ? data.terraform_remote_state.primary[0].outputs.redis-01_password : var.redis_password : null
  automatic_failover_enabled  = var.redis_multi_az_enabled == true ? true : false
  engine                      = var.replica ? null : var.redis_engine
  engine_version              = var.replica ? null : var.redis_version
  final_snapshot_identifier   = "${var.cluster_id}-redis-final-snapshot-${formatdate("YYYY-MM-DD-hh-mm", timestamp())}"
  kms_key_id                  = var.redis_at_rest_encryption_enabled ? var.redis_kms_key_arn : null
  multi_az_enabled            = var.redis_multi_az_enabled
  node_type                   = var.replica ? null : var.redis_node_type
  num_cache_clusters          = var.redis_num_cache_clusters
  port                        = var.redis_port
  security_group_ids          = [var.redis_security_group_id]
  snapshot_name               = var.redis_snapshot_name
  snapshot_retention_limit    = var.redis_backup_retention_period
  snapshot_window             = var.redis_backup_window
  subnet_group_name           = aws_elasticache_subnet_group.redis_subnet_group.name
  transit_encryption_enabled  = var.replica ? null : var.redis_transit_encryption_enabled
  parameter_group_name        = var.redis_parameter_group_name

  dynamic "log_delivery_configuration" {
    for_each = var.redis_log_delivery_configuration
    content {
      destination      = log_delivery_configuration.value.destination
      destination_type = log_delivery_configuration.value.destination_type
      log_format       = log_delivery_configuration.value.log_format
      log_type         = log_delivery_configuration.value.log_type
    }
  }

  lifecycle {
    ignore_changes = [
      automatic_failover_enabled,
      engine_version,
      engine,
      final_snapshot_identifier,
      global_replication_group_id,
      multi_az_enabled,
      snapshot_name,
    ]
  }
}

resource "aws_elasticache_global_replication_group" "global" {
  count                              = var.primary ? 1 : 0
  global_replication_group_id_suffix = var.redis_name != null ? var.redis_name : "${var.cluster_id}-${var.namespace_id}-redis"
  primary_replication_group_id       = aws_elasticache_replication_group.redis.id
}

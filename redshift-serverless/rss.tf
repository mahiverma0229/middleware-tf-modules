locals {
  cluster_creds = jsondecode(data.aws_secretsmanager_secret_version.rss_secrets[0].secret_string)
  #parameter_group_name = "${var.cluster_id}-${var.identifier_id}-redshift-pg"
}
resource "aws_redshiftserverless_namespace" "redshift_serverless_namespace" {
  count               = var.rss_enabled ? var.delete_rss_cluster ? 0 : 1 : 0
  namespace_name      = var.rss_namespace_name
  admin_username      = local.cluster_creds.username
  admin_user_password = local.cluster_creds.password
  db_name             = var.rss_db_name
  kms_key_id          = var.rss_kms_key_arn
  log_exports         = var.rss_log_exports
  tags = {
    Name = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-rss-namespace"
  }
}

resource "aws_redshiftserverless_workgroup" "redshift_serverless_workgroup" {
  count                = var.rss_enabled ? var.delete_rss_cluster ? 0 : 1 : 0
  namespace_name       = aws_redshiftserverless_namespace.redshift_serverless_namespace[0].namespace_name
  workgroup_name       = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-redshift"
  #base_capacity        = var.rss_base_capacity
  enhanced_vpc_routing = var.enhanced_vpc_routing
  max_capacity         = var.rss_max_capacity
  port                 = var.rss_port
  publicly_accessible  = var.publicly_accessible
  security_group_ids   = [var.rss_security_group_id]
  subnet_ids           = var.rss_subnet_ids
  price_performance_target {
    enabled = var.rss_price_performance_target_enabled
    level = var.rss_price_performance_target_level
  }
  tags = {
    Name = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-rss"
  }
}

resource "aws_redshiftserverless_snapshot" "snapshot" {
  count            = var.rss_enabled ? var.delete_rss_cluster ? 0 : 1 : 0
  namespace_name   = join("", aws_redshiftserverless_workgroup.redshift_serverless_workgroup.*.namespace_name)
  snapshot_name    = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-rss-snapshot"
  retention_period = var.rss_snapshot_retention_period
}

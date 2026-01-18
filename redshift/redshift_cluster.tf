
################################################################################
# Subnet group for redshift cluster
################################################################################

resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-redshift-subnet-gp"
  subnet_ids = var.redshift_subnet_ids
}

locals {
  cluster_creds        = jsondecode(data.aws_secretsmanager_secret_version.redshift_secrets.secret_string)
  parameter_group_name = "${var.cluster_id}-${var.identifier_id}-redshift-pg"
}

################################################################################
# redshift Cluster
################################################################################

resource "aws_redshift_cluster" "aws_redshift_cluster" {
  count                 = var.redshift_enabled ? var.delete_redshift_cluster ? 0 : 1 : 0
  cluster_identifier    = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-redshift"
  database_name         = var.redshift_db_name
  master_username       = local.cluster_creds.username
  master_password       = local.cluster_creds.password
  node_type             = var.redshift_node_type
  cluster_type          = var.redshift_cluster_type
  cluster_version       = var.redshift_version
  allow_version_upgrade = var.redshift_allow_version_upgrade
  #availability_zone                   = var.redshift_availability_zone
  multi_az                            = var.redshift_multi_az_enabled
  availability_zone_relocation_enabled = var.redshift_availability_zone_relocation_enabled
  automated_snapshot_retention_period = var.redshift_auto_snapshot_retention_period
  manual_snapshot_retention_period    = var.redshift_manual_snapshot_retention_period
  publicly_accessible                 = var.redshift_publicly_accessible
  number_of_nodes                     = var.redshift_number_of_nodes
  encrypted                           = var.redshift_encryption_enabled
  kms_key_id                          = var.redshift_kms_key_arn
  cluster_parameter_group_name        = local.parameter_group_name
  vpc_security_group_ids              = [var.redshift_security_group_id]
  cluster_subnet_group_name           = aws_redshift_subnet_group.redshift_subnet_group.id
  port                                = var.redshift_port
  skip_final_snapshot                 = var.redshift_skip_final_snapshot
  final_snapshot_identifier           = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-redshift-snapshot-final"
  snapshot_identifier                 = var.redshift_snapshot_identifier
  #iam_roles                           = var.redshift_msk_iam_role 
  tags = {
    Name = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-redshift"
  }
  lifecycle {
    ignore_changes = [
      cluster_version,
      snapshot_identifier,
      encrypted,
      kms_key_id,
      tags,
      master_password,
      master_username
    ]
  }
  depends_on = [
    aws_redshift_subnet_group.redshift_subnet_group
  ]

}
################################################################################
# redshift parameter group
################################################################################

resource "aws_redshift_parameter_group" "aws_redshift_cluster_parameter_group" {
  name        = local.parameter_group_name
  description = "custom redshift parameter group for performance tuning"
  family      = var.parameter_group_family

  dynamic "parameter" {
    for_each = var.parameter_group_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
}

################################################################################
# Redshift audit log enablement with CloudWatch log group 
################################################################################
resource "aws_cloudwatch_log_group" "redshift_cloudwatch_log_group" {
  count             = var.redshift_cloudwatch_logs_enabled ? 1 : 0
  name              = "${var.cluster_id}-${var.namespace_id}-redshift-cloudwatch-group"
  retention_in_days = var.redshift_cloudwatch_retention_in_days
}

resource "aws_redshift_logging" "aws_redshift_logging" {
  count                = var.redshift_enabled ? var.delete_redshift_cluster ? 0 : 1 : 0
  cluster_identifier   = aws_redshift_cluster.aws_redshift_cluster[0].id
  log_destination_type = "cloudwatch"
  log_exports          = var.redshift_log_exports
}

################################################################################
# redshift snapshot schedule + association with redshift cluster
################################################################################

resource "aws_redshift_snapshot_schedule" "aws_redshift_snapshot_schedule" {
  count       = var.redshift_enabled ? var.delete_redshift_cluster ? 0 : 1 : 0
  identifier  = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-redshift-snapshot"
  description = "Redshift snapshot schedule"
  definitions = var.snapshot_schedule_definitions
}

resource "aws_redshift_snapshot_schedule_association" "redshift_snapshot_association" {
  count               = var.redshift_enabled ? var.delete_redshift_cluster ? 0 : var.snapshot_schedule_enabled ? 1 : 0 : 0
  cluster_identifier  = aws_redshift_cluster.aws_redshift_cluster[0].id
  schedule_identifier = aws_redshift_snapshot_schedule.aws_redshift_snapshot_schedule[0].id
}

resource "aws_redshift_snapshot_copy_grant" "redshift_snapshot_copy_grant" {
  count                    = var.redshift_enabled ? var.delete_redshift_cluster ? 0 : var.redshift_multi_region_enabled ? 1 : 0 : 0
  snapshot_copy_grant_name = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-redshift-snapshotcopy-grant"
  kms_key_id               = var.redshift_kms_key_arn
}

resource "aws_redshift_snapshot_copy" "redshift_snapshot_copy" {
  count = var.redshift_enabled ? var.delete_redshift_cluster ? 0 : var.redshift_multi_region_enabled ? 1 : 0 : 0
  cluster_identifier = aws_redshift_cluster.aws_redshift_cluster[0].id
  destination_region       = var.aws_dr_region
  snapshot_copy_grant_name = var.redshift_snapshot_copy_grant
  depends_on = [
    aws_redshift_snapshot_copy_grant.redshift_snapshot_copy_grant
  ]
}




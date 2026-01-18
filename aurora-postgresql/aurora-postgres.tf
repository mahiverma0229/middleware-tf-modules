## Importing data to secondary from primary
data "terraform_remote_state" "primary" {
  count   = var.replica ? 1 : 0
  backend = "s3"
  config  = {
    bucket  = var.remote_state_bucket
    region  = var.remote_state_region
    key     = var.remote_state_key
    encrypt = true
    profile = var.remote_state_profile
  }
}

locals {
  postgres_name_prefix = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}"
}

resource "aws_db_subnet_group" "postgresql" {
  name       = var.postgres_name
  subnet_ids = var.db_group_subnets
}

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier               = var.postgres_name != null ? var.postgres_name : "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-aurora"
  engine                           = "aurora-postgresql"
  engine_version                   = var.pg_version
  skip_final_snapshot              = var.aurora_skip_final_snapshot
  db_subnet_group_name             = aws_db_subnet_group.postgresql.name
  db_cluster_parameter_group_name  = aws_rds_cluster_parameter_group.pg_cluster_parameter_group.id
  db_instance_parameter_group_name = aws_db_parameter_group.pg_parameter_group.id
  global_cluster_identifier        = var.aurora_snapshot_identifier != null ? null : var.aurora_remove_from_global_cluster ? null : var.replica ? data.terraform_remote_state.primary[0].outputs.postgres-03_aurora_global_cluster_id : var.primary ? var.global_cluster_id != null ? length(var.global_cluster_id) == 0 ? null : var.global_cluster_id : null : null 
  database_name                    = var.replica ? null : var.db_name
  master_username                  = var.replica ? null : var.primary_username != null ? var.primary_username : replace("${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-postgresdb", "-", "_")
  master_password                  = var.replica ? null : var.primary_password
  storage_encrypted                = var.aurora_storage_encrypted
  kms_key_id                       = var.aurora_storage_encrypted ? var.aurora_kms_key_arn : null
  backup_retention_period          = var.aurora_backup_retention_period
  preferred_backup_window          = var.aurora_preferred_backup_window
  snapshot_identifier              = var.aurora_snapshot_identifier
  final_snapshot_identifier        = var.aurora_skip_final_snapshot ? null : "${var.cluster_id}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hh-mm", timestamp())}"
  vpc_security_group_ids           = [var.aurora_security_group_id]
  allow_major_version_upgrade      = var.aurora_allow_major_version_upgrade
  apply_immediately                = var.aurora_apply_immediately
  enabled_cloudwatch_logs_exports  = var.aurora_enabled_cloudwatch_logs_exports
  tags                             = var.aurora_tags

  lifecycle {
    ignore_changes = [
      engine_version,
      snapshot_identifier,
      final_snapshot_identifier,
      storage_encrypted,
      kms_key_id,
      tags,
    ]
  }
}

#Second attach instances to regional cluster
resource "aws_rds_cluster_instance" "postgresql" {
  count                      = var.pg_instance_count
  engine                     = "aurora-postgresql"
  identifier                 = var.postgres_name != null ? "${var.postgres_name}-${count.index}" : "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-${count.index}"
  cluster_identifier         = aws_rds_cluster.postgresql.id
  instance_class             = var.pg_instance_class
  db_subnet_group_name       = aws_db_subnet_group.postgresql.name
  apply_immediately          = var.aurora_instance_apply_immediately
  auto_minor_version_upgrade = var.aurora_auto_minor_version_upgrade
  tags                       = var.aurora_tags

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

# Finally upgrade regional cluster to Primary cluster by attaching global cluster to it
resource "aws_rds_global_cluster" "postgresql" {
  count                        = var.primary ? 1 : 0 
  global_cluster_identifier    = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-global-aurora"
  engine_version               = var.pg_version
  force_destroy                = true
  source_db_cluster_identifier = aws_rds_cluster.postgresql.arn

  lifecycle {
    ignore_changes = [
      database_name,
    ]
  }
}

resource "aws_db_parameter_group" "pg_parameter_group" {
  name_prefix = "${local.postgres_name_prefix}-pg"
  family      = join("", ["postgres", split(".", var.pg_version)[0]])

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "pg_cluster_parameter_group" {
  name_prefix = "${local.postgres_name_prefix}-cluster-pg"
  family = "aurora-postgresql${split(".", var.pg_version)[0]}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

#Arora PG auto-scaling : configure Read Replica count as a scalable target

resource "aws_appautoscaling_target" "pg_scalable_target" {
  count              = var.pg_autoscaling_enabled ? 1 : 0
  service_namespace  = "rds"                          #RDS service
  scalable_dimension = "rds:cluster:ReadReplicaCount" #Dimension to scale. Arora Read Replica
  resource_id        = "cluster:${aws_rds_cluster.postgresql.id}"
  min_capacity       = var.pg_min_read_replica_count
  max_capacity       = var.pg_max_read_replica_count
  tags = {
    Name = "${var.cluster_id}-${var.namespace_id}-pg-autoscaling-target"
  }
  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}
#Define dynamic auto-scaling policy (Target tracking)
resource "aws_appautoscaling_policy" "pg_scaling_policy" {
  count              = var.pg_autoscaling_enabled ? var.pg_dynamic_scaling_enabled ? 1 : 0 : 0
  name               = "${var.cluster_id}-${var.namespace_id}-pg-dynamic-scaling-policy"
  resource_id        = aws_appautoscaling_target.pg_scalable_target[0].resource_id
  service_namespace  = aws_appautoscaling_target.pg_scalable_target[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.pg_scalable_target[0].scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.pg_autoscaling_metric_type
    }
    target_value        = var.pg_autoscaling_target_value
    scale_in_cooldown   = var.pg_scale_in_cooldown_period
    scale_out_cooldown  = var.pg_scale_out_cooldown_period
  }
  depends_on = [aws_appautoscaling_target.pg_scalable_target]
}

##Schedule based auto-scaling. <<for lower environments>>
#1. Scale-down during weekends (Saturday, Sunday). If current capacity is greater than the specified maximum capacity, Application Auto Scaling scales in (decreases capacity) to the specified maximum capacity.
#Schedule is every Saturday-Sunday at 00:00 EST (05:00 UTC) (Day of week 7)

resource "aws_appautoscaling_scheduled_action" "scale_down_weekend" {
  count               = var.pg_autoscaling_enabled ? var.pg_schedule_scaling_enabled ? 1 : 0 : 0
  name                = "${var.cluster_id}-${var.namespace_id}-scale-down-weekend"
  resource_id         = aws_appautoscaling_target.pg_scalable_target[0].resource_id
  service_namespace   = aws_appautoscaling_target.pg_scalable_target[0].service_namespace
  scalable_dimension  = aws_appautoscaling_target.pg_scalable_target[0].scalable_dimension
  schedule            = "cron(0 5 ? * SAT-SUN *)"

scalable_target_action {
    max_capacity = var.pg_read_replicas_off_hours
  }
depends_on = [aws_appautoscaling_target.pg_scalable_target]
}

#2. Scale-down during off-hours (weekdays) (after 5 pm EST). If current capacity is greater than the specified maximum capacity, Application Auto Scaling scales in (decreases capacity) to the specified maximum capacity.
#Schedule is 6 PM EST (11 PM UTC) Monday to Friday to set the capacity for the off-peak period

resource "aws_appautoscaling_scheduled_action" "scale_down_off_hours" {
  count              = var.pg_autoscaling_enabled ? var.pg_schedule_scaling_enabled ? 1 : 0 : 0
  name               = "${var.cluster_id}-${var.namespace_id}-scale-down-off_hours"
  resource_id        = aws_appautoscaling_target.pg_scalable_target[0].resource_id
  service_namespace  = aws_appautoscaling_target.pg_scalable_target[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.pg_scalable_target[0].scalable_dimension
  schedule           = "cron(0 23 ? * MON-FRIDAY *)"

scalable_target_action {
    max_capacity=var.pg_read_replicas_off_hours
  }
depends_on = [aws_appautoscaling_target.pg_scalable_target]
}

#3. Scale-up during weekedays business hours. If current capacity is less than the specified minimum capacity, Application Auto Scaling scales out (increases capacity) to the specified minimum capacity.
#Schedule is 4 AM EST (9AM UTC), Monday to Friday

resource "aws_appautoscaling_scheduled_action" "scale_up_weekdays" {
  count               = var.pg_autoscaling_enabled ? var.pg_schedule_scaling_enabled ? 1 : 0 : 0
  name                = "${var.cluster_id}-${var.namespace_id}-scale-up-weekdays"
  resource_id         = aws_appautoscaling_target.pg_scalable_target[0].resource_id
  service_namespace   = aws_appautoscaling_target.pg_scalable_target[0].service_namespace
  scalable_dimension  = aws_appautoscaling_target.pg_scalable_target[0].scalable_dimension
  schedule            = "cron(0 9 ? * MON-FRIDAY *)"

scalable_target_action {
    min_capacity = var.pg_read_replicas_weedays
  }
depends_on = [aws_appautoscaling_target.pg_scalable_target]
}


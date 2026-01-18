variable "postgres_name" {
  type = string
}

variable "global_cluster_id" {
  type        = string
  description = "Identifier for global cluster"
}

variable "db_group_subnets" {
  description = "List of subnets for DB subnet group"
}

variable "cluster_id" {
  type        = string
  description = "Identifier for CP4S Cluster"
}

variable "namespace_id" {
  type        = string
  description = "Identifier for namespace middleware is assocated with in CP4S cluster"
}

variable "identifier_id" {
  type        = string
  description = "Identifier to make the module uniquie, ie: 02 or 03"
}

variable "pg_version" {
  type    = string
  default = "16.4"
}

variable "pg_instance_count" {
  type    = number
  default = 2
}

variable "pg_instance_class" {
  type    = string
  default = "db.r5.large"
}

variable "aurora_remove_from_global_cluster" {
  type    = bool
  default = false
}

variable "primary" {
  type    = bool
  default = false
}

variable "replica" {
  type    = bool
  default = false
}

variable "db_name" {
  type        = string
  nullable    = true
  default     = null
  description = "Database name"

  # Constraints: Must contain 1 to 60 alphanumeric characters or hyphens. first character must be a letter. 
  # can't contain two consecutive hyphens. can't end with a hyphen.
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,59}$", var.db_name)) && length(regexall("-{2,}|-$", var.db_name)) == 0
    error_message = "The input does not meet validation condition for the database name."
  }
}

variable "aurora_apply_immediately" {
  type        = bool
  description = "Apply Aurora DB cluster configuration changes immediately"
  default     = false
}

variable "aurora_instance_apply_immediately" {
  type        = bool
  description = "Apply Aurora DB instance configuration changes immediately"
  default     = false
}

variable "primary_username" {
  description = "DB username (only for primary cluster)"
}

variable "primary_password" {
  type        = string
  nullable    = true
  default     = null
  description = "DB password (only for primary cluster)"
}

variable "aurora_backup_retention_period" {
  type        = number
  description = "The backup retention period of Aurora Postgres cluster"
}

variable "aurora_preferred_backup_window" {
  type        = string
  description = "The daily time range during which the backups happen in Aurora Postgres cluster"
}

variable "remote_state_bucket" {
  type    = string
  default = null
}

variable "remote_state_region" {
  type    = string
  default = null
}

variable "remote_state_key" {
  type    = string
  default = null
}

variable "remote_state_profile" {
  type    = string
  default = null
}

variable "aurora_storage_encrypted" {
  type        = bool
  description = "Specify true to enable the storage encryption for the Aurora Postgres cluster"
  default     = true
}

# Use the default AWS managed KMS (aws/rds) key for encryption by leaving the 'kms_key_id' argument as null.
# To use a customer managed key for encryption, provide the ARN of the key via the 'aurora_kms_key_arn' variable.
# Use the 'kms' module in common folder to create a customer managed KMS key.
variable "aurora_kms_key_arn" {
  type        = string
  description = "Specify the ARN of the AWS customer managed KMS encryption key. If not specified, the default AWS managed KMS ('aws/rds' managed service) key will be used for encryption"
  default     = null
}

variable "aurora_security_group_id" {
  description = "List of VPC security groups to associate with the Aurora Postgres cluster"
}

variable "aurora_replica_password" {
  type      = string
  default   = null
  sensitive = true
}

variable "aurora_snapshot_identifier" {
  type        = string
  description = "Specifies whether to create this cluster from a snapshot"
}

variable "aurora_skip_final_snapshot" {
  type        = bool
  default     = false
  description = "DB snapshot is created before the DB cluster is deleted. Toggle only when you dont want to create final snapshot"
}

variable "aurora_enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["postgresql"]
}

variable "aurora_allow_major_version_upgrade" {
  type        = bool
  description = "Set to true when upgrading to a new major version"
  default     = true
}

variable "aurora_auto_minor_version_upgrade" {
  type        = bool
  default     = false
  description = "Minor engine upgrades will not be applied automatically to the DB instance during the maintenance window. To enable this set it to true"
}

variable "aurora_tags" {
  type        = map(any)
  description = "A map of tags to assign to the Aurora Postgres cluster"
  default     = {}
}

variable "parameters" {
  description = "A list of DB parameter maps to apply"
  type        = list(map(string))
  default = [
    {
      name         = "max_prepared_transactions"
      value        = 120
      apply_method = "pending-reboot"
    },
    {
      name         = "shared_preload_libraries"
      value        = "pg_stat_statements"
      apply_method = "pending-reboot"
    }
  ]
}
#Variables for Arora PG auto-scaling enablement based on Target Tracking scaling policy.
variable "pg_autoscaling_enabled" {
  type    = bool
  description = "Set this value to true to enable Arora Postgres auto-scaling"
  default = false
}
variable "pg_schedule_scaling_enabled" {
  type    = bool
  description = "Set the value of this variable to true to enable schedule based auto-scaling for Amazon Aurora PostgreSQL."
  default = false
}

variable "pg_dynamic_scaling_enabled" {
  type    = bool
  description = "Set the value of this variable to true to enable dynamic target tracking auto-scaling for Amazon Aurora PostgreSQL."
  default = false
}
variable "pg_min_read_replica_count" {
  type    = number
  description = "minimum number of Aurora Read Replicas allowed (0 for no read replicas, 1 for minimum redundancy)."
  default = 0
}

variable "pg_max_read_replica_count" {
  type    = number
  description = "Maximum number of Aurora Read Replicas allowed."
  default = 1
}
variable "pg_autoscaling_metric_type" {
  type    = string
  description = "Pre-defined metric type of Target Tracking scaling policy"
  default = "RDSReaderAverageCPUUtilization"
}
variable "pg_autoscaling_target_value" {
  type    = number
  description = "target value of the predefined cloudWatch metric on CPU utilization in percent"
  default = 90.0
}
variable "pg_scale_in_cooldown_period" {
  type    = number
  description = "Cooldown period to prevent rapid scale-in. it is time in seconds before another scale-in can accour"
  default = 300
}

variable "pg_scale_out_cooldown_period" {
  type    = number
  description = "Cooldown period to prevent rapid scaling. it is time in seconds before another scale-out can accour"
  default = 60
}
variable "pg_scalable_dimension" {
  type    = string
  description ="specific resource property  that Auto Scaling to manage and adjust automatically based on metrics and policies. It defines what is being scaled."
  default = "rds:cluster:ReadReplicaCount"
}
variable "pg_read_replicas_weedays" {
  type    = number
  description = "Minimum number of Aurora Read Replicas during business hours schedule."
  default = 1
}

variable "pg_read_replicas_off_hours" {
  type    = number
  description = "Maximum number of Aurora Read Replicas during off_hours schedule."
  default = 0
}
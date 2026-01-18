variable "cluster_id" {}
variable "namespace_id" {}
variable "identifier_id" {}
variable "redshift_subnet_ids" {}
variable "aws_dr_region" {}


variable "encryption_at_rest_kms_key_arn" {
  type        = string
  default     = ""
  description = "You may specify a KMS key short ID or ARN (it will always output an ARN) to use for encrypting your data at rest"
}

variable "redshift_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create middleware Amazon Redshift cluster. "
  default     = false
}
variable "is_secondary_region" {
  type        = bool
  description = "During cross-region setup, set the value of this variable to true in the secondary region to create AWS KMS replica keys and replicate other resources from the primary region to the secondary region."
  default     = false
}

variable "redshift_db_name" {
  type        = string
  description = "Amazon Redshift DB name."
  default     = "bludb"
}

variable "redshift_node_type" {
  type        = string
  description = "Amazon Redshift node type"
  default     = "ra3.4xlarge"
}

variable "redshift_cluster_type" {
  type        = string
  description = "Amazon Redshift cluster type. possibel values are signle-zone or multi-zone."
  default     = "multi-node"


}

variable "redshift_version" {
  type        = string
  description = "The version of the Amazon Redshift engine to use. See https://docs.aws.amazon.com/redshift/latest/mgmt/cluster-versions.html"
  default     = "1.0"
}

variable "redshift_snapshot_destination" {
  type        = string
  default     = "us-west-2"
  description = "The destination of the snapshot to be copied to"
}

variable "redshift_allow_version_upgrade" {
  type        = bool
  default     = false
  description = "Whether or not to enable major version upgrades which are applied during the maintenance window to the Amazon Redshift engine that is running on the cluster"
}

variable "redshift_availability_zone" {
  description = "The EC2 Availability Zone (AZ) in which you want Amazon Redshift to provision the cluster. Can only be changed if `availability_zone_relocation_enabled` is `true`"
  type        = string
  default     = "us-east-1a"
}

variable "redshift_publicly_accessible" {
  type        = bool
  default     = false
  description = "If true, the cluster can be accessed from a public network"
}

variable "redshift_number_of_nodes" {
  type        = number
  default     = 2
  description = "The number of compute nodes in the cluster. This parameter is required when the ClusterType parameter is specified as multi-node"
}

variable "redshift_port" {
  type        = number
  default     = 5439
  description = "The port number on which the cluster accepts incoming connections"
}

variable "redshift_encryption_enabled" {
  type        = bool
  description = "This variable is used to create an AWS customer managed KMS key. Set the value of this variable to false when the redshift_enabled variable is false."
  default     = true
}


variable "redshift_kms_key_arn" {
  type        = string
  description = "Specify the ARN of the AWS customer managed KMS encryption key."
  default     = null
}
variable "redshift_user_name" {
  type        = string
  description = "Amazon Redshift master user name."
  default     = "guardium"
}
variable "parameter_group_family" {
  description = "The family of the Redshift parameter group"
  type        = string
  default     = "redshift-1.0"
}

variable "parameter_group_parameters" {
  description = "value"
  type        = map(any)
  default     = {}
}

variable "redshift_cloudwatch_logs_enabled" {
  type        = bool
  default     = true
  description = "Indicates whether you want to enable or disable streaming broker logs to Amazon CloudWatch Logs"
}
variable "redshift_log_exports" {
  type        = list(string)
  default     = ["connectionlog", "userlog", "useractivitylog"]
  description = "Redshift audit log types to export to cloudWatch."
}
variable "redshift_cloudwatch_retention_in_days" {
  type        = number
  default     = 30
  description = "The maximum number of days log events retained in the specified Amazon CloudWatch log group"
}

variable "redshift_auto_snapshot_retention_period" {
  description = "The number of days that automated snapshots are retained."
  type        = number
  default     = 7
}
variable "snapshot_schedule_definitions" {
  description = "The definition of the snapshot schedule. The definition is made up of schedule expressions, for example `cron(30 12 *)` or `rate(12 hours)`"
  type        = list(string)
  default     = ["rate(12 hours)"]
}

variable "snapshot_schedule_enabled" {
  description = "Determines whether to create a snapshot schedule"
  type        = bool
  default     = true
}

variable "snapshot_destination_region" {
  type        = string
  description = "Redshift destination region where snapshot to be copied"
  default     = "US-WEST-2"
}

variable "redshift_security_group_id" {
  description = "The list of VPC security groups to associate with the DB cluster"
}


variable "redshift_skip_final_snapshot" {
  type        = bool
  description = "Set the value of this variable to true to skip final snapshot before cluster deletion"
  default     = false
}

variable "redshift_multi_az_enabled" {
  type        = bool
  description = "Set the value of this variable to true for multi-az Redshift cluster"
  default     = false
}
variable "redshift_availability_zone_relocation_enabled" {
  type        = bool
  description = "Set the value of this variable to true to enable AZ relocation for Redshift cluster"
  default     = false
}
variable "redshift_manual_snapshot_retention_period" {
  type        = number
  default     = 7
  description = "Number of days to retain manual DB snapshots"
}
variable "redshift_multi_region_enabled" {
  type        = bool
  description = "Set the value of this variable to true for multi region environment. It is for redshift_multihost"
  default     = false
}
variable "redshift_snapshot_identifier" {
  type        = string
  description = "Specifies whether to create this cluster from a snapshot"

}

# variable "redshift_msk_iam_role" {
#   type = list(string)
#   default = []
#   description = "Set the value of IAM role for redshift to allow access to msk for streaming ingestion in materialised view"
# }

variable "redshift_snapshot_copy_grant" {
  type        = string
  description = "Specify the name of the snapshot copy grant."
  default     = null
}
# below toggle is to delete only Redshift cluster during fail-over and fail-back scenario
variable "delete_redshift_cluster" {
  type        = bool
  description = "Set the value of this variable to true to delete only redshift cluster during fail-over and fail-back before restore from the snapshot"
  default     = false
}
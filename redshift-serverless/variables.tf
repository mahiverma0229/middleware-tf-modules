variable "cluster_id" {}
variable "namespace_id" {}
variable "identifier_id" {}
variable "rss_subnet_ids" {}
variable "rss_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create Amazon Redshift serverless"
  default     = false
}
variable "rss_namespace_name" {
  type        = string
  default     = ""
  description = "The name of the namespace for redshift serverless."
}
variable "rss_db_name" {
  type        = string
  default     = "gdscdb"
  description = "The name of the first database created in the namespace."
}
variable "rss_kms_key_arn" {
  type        = string
  description = "Specify the ARN of the AWS customer managed KMS encryption key."
  default     = null
}
variable "rss_log_exports" {
  type        = list(string)
  default     = ["useractivitylog"]
  description = "The types of logs the namespace can export. Available export types are userlog, connectionlog, and useractivitylog."
}
variable "encryption_at_rest_kms_key_arn" {
  type        = string
  default     = ""
  description = "You may specify a KMS key short ID or ARN (it will always output an ARN) to use for encrypting your data at rest"
}
variable "rss_workgroup_name" {
  type        = string
  default     = "gdsc-rss-wg"
  description = "The name of the workgroup."
}
variable "rss_base_capacity" {
  type        = number
  default     = 8
  description = "The base compute capacity of the workgroup in Redshift Processing Units (RPUs)."
}
variable "enhanced_vpc_routing" {
  type        = bool
  default     = true
  description = "If `true`, enhanced VPC routing is enabled"
}
variable "rss_max_capacity" {
  type        = number
  default     = 256
  description = "The maximum compute resource capacity of the workgroup in Redshift Processing Units (RPUs)."
}
variable "rss_port" {
  type        = number
  default     = 5442
  description = "The port number on which the cluster accepts incoming connections"
}
variable "publicly_accessible" {
  type        = bool
  default     = false
  description = "If true, the cluster can be accessed from a public network"
}
variable "rss_security_group_id" {
  description = "The list of VPC security groups to associate with the DB cluster"
}
variable "rss_config_parameters" {
  description = "List of dynamic configuration parameters for Redshift Serverless"
  type = list(object({
    parameter_key   = string
    parameter_value = string
  }))
  default = []
}
variable "rss_snapshot_retention_period" {
  description = "The number of days that snapshots is retained."
  type        = number
  default     = 7
}
variable "rss_user_name" {
  type        = string
  description = "Amazon Redshift serverless master user name."
  default     = "guardium"
}
variable "rss_external_db" {
  type        = string
  default     = "gdsc"
  description = "The name of the db to be created for datashare."
}
variable "rss_price_performance_target_enabled" {
  type        = bool
  default     = true
  description = "This flag indicates whether to enable price-performance scaling for redshift serverless cluster"
}

variable "rss_price_performance_target_level" {
  type        = number
  default     = 100
  description = "Price-performance scaling level. valid values are 1 (LOW_COST), 25(ECONOMICAL), 50(BALANCED), 75(RESOURCEFUL) & 100(HIGH_PERFORMANCE)"
}
#Below parameter is added to handle fail-over and fail-back for redshift serverless when only deletion of the cluster is required
variable "delete_rss_cluster" {
  type        = bool
  description = "Set the value of this variable to true to delete only redshift serverless cluster during fail-over and fail-back before restore from the snapshot"
  default     = false
}
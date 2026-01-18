variable "cluster_id" {
  type        = string
  description = "Identifier for GI Cluster"
}

variable "namespace_id" {
  type        = string
  description = "Identifier for namespace middleware is assocated with in GI cluster"
}

variable "primary" {
  type        = bool
  description = "Specify true to create global replication group"
  default     = false
}

variable "replica" {
  type        = bool
  description = "Specify true to create secondary replication group"
  default     = false
}

variable "redis_name" {
  type        = string
  description = "Replication group identifier"
  default     = null

  # Constraints: Must up to 40 characters, and must begin with a letter. it should not end with a hyphen or
  # contain two consecutive hyphens. Valid characters: A-Z, a-z,0-9 and hyphen
  # can be left null, it will be generated automatically
  validation {
    condition = var.redis_name == null  ? true :(
      can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,39}$", var.redis_name)) &&
      length(regexall("-{2,}|-$", var.redis_name)) == 0
    )
    error_message = "The input does not meet validation condition for the redis name."
  }
}

variable "redis_description" {
  type        = string
  description = "Replication group description"
  default     = "Managed by Terraform"
}

variable "redis_password" {
  type        = string
  description = "Password used to access a password protected server"
  default     = null
}

variable "redis_engine" {
  type        = string
  description = "The engine. can be redis or valkey"
  default     = "redis"
}

variable "redis_version" {
  type        = string
  description = "Version number of the cache engine to be used for the cache clusters in this replication group"
  default     = "5.0.6"
}

variable "redis_port" {
  type        = number
  description = "Port number on which each of the cache nodes will accept connections"
  default     = 6379
}

variable "redis_num_cache_clusters" {
  type        = number
  description = "Number of cache clusters (primary and replicas) this replication group will have"
  default     = 3
}

variable "redis_node_type" {
  type        = string
  description = "Instance class to be used"
  default     = "cache.r6g.large"
}

variable "redis_multi_az_enabled" {
  type        = bool
  description = "Specify true to enable Multi-AZ Support for the replication group."
  default     = true
}

variable "redis_security_group_id" {
  description = "VPC security group ID associated with this replication group"
}

variable "redis_subnet_ids" {
  description = "List of VPC Subnet IDs for the cache subnet group"
}

variable "redis_at_rest_encryption_enabled" {
  type        = bool
  description = "Specify true to enable encryption at rest."
  default     = true
}

variable "redis_transit_encryption_enabled" {
  type        = bool
  description = "Specify true to enable encryption in transit."
  default     = true
}

variable "redis_kms_key_arn" {
  type        = string
  description = "Specify the ARN of the AWS customer managed KMS encryption key. If not specified, the default AWS service owned KMS key will be used for encryption"
  default     = null
}

variable "redis_backup_window" {
  type        = string
  description = "Daily time range (in UTC) during which ElastiCache will begin taking a daily snapshot of your cache cluster"
  default     = "00:00-01:00"
}

variable "redis_backup_retention_period" {
  type        = number
  description = "Number of days for which ElastiCache will retain automatic cache cluster snapshots before deleting them"
  default     = 7
}

variable "redis_snapshot_name" {
  type        = string
  description = "Name of a snapshot from which to restore data into the new node group"
  default     = null
}

variable "redis_apply_immediately" {
  type        = bool
  description = "Apply configuration changes immediately"
  default     = false
}

variable "redis_log_delivery_configuration" {
  type = map(object({
    destination      = string
    destination_type = string
    log_format       = string
    log_type         = string
  }))
  description = "Specifies the destination and format of Redis SLOWLOG or Redis Engine Log"
  default     = {}
}

variable "redis_parameter_group_name" {
  type        = string
  description = "Name of the parameter group to associate with the replication group. If this argument is omitted, the default cache parameter group for the specified engine is used."
  default     = null
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

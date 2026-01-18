# General variables
variable "aws_account_id" {
  type        = string
  description = "AWS Account ID from terragrunt account.hcl."
}

variable "aws_partition" {
  type        = string
  description = "AWS Partition."
  default     = "aws"
}

variable "aws_region" {
  type        = string
  description = "AWS Region from terragrunt region.hcl."
}
# AWS Secrets Manager
variable "push_secrets_to_sm" {
  type        = bool
  default     = false
  description = "Toggle to enable push of middleware-secrets onto AWS Secrets Manager" 
}
variable "middleware_secrets_manager_name" {
  type = string
  default = "Guardium/middleware"
  description = "This is the middleware secrets manager name populated in env.hcl based on environment"

}
variable "all_middleware_secrets" {
  default = {
    key1 = "value1"
  }
  type = map(string)
}
# added for redshift snapshot copy in multi-region env
variable "aws_dr_region" {
  type        = string
  description = "AWS DR Region from terragrunt region.hcl."
}

variable "team" {
  type        = string
  description = "Team name from terragrunt team.hcl. Used for naming VPC resources."
}

variable "cluster_id" {
  type        = string
  description = "Identifier for GI cluster from terragrunt cluster.hcl."
}

variable "namespace_id" {
  type        = string
  description = "The name of the middleware namespace."
}

variable "identifier_id" {
  type        = string
  description = "The middleware namespace identifier. Increment the value of this variable by one (i.e. 02) to refresh the middleware."
}

variable "old_subnets_toggle" {
  type        = bool
  description = "Set the value of this variable to false to enable 3 private subnets."
  default     = true
}

variable "is_secondary_region" {
  type        = bool
  description = "During cross-region setup, set the value of this variable to true in the secondary region to create AWS KMS replica keys and replicate other resources from the primary region to the secondary region."
  default     = false
}

variable "cr_standby_instance" {
  type        = bool
  description = "During cross-region setup, set the value of this variable to true in the secondary region."
  default     = false
}

variable "remote_state_bucket" {
  type        = string
  description = "Name of the Amazon S3 bucket that contains Terraform remote state."
  default     = null
}

variable "remote_state_region" {
  type        = string
  description = "The AWS Region where the Amazon S3 bucket with the Terraform remote state is located."
  default     = null
}

variable "remote_state_key" {
  type        = string
  description = "The key prefix of the Amazon S3 bucket that contains the Terraform remote state."
  default     = null
}

variable "remote_state_profile" {
  type        = string
  description = "The Terraform remote state profile name."
  default     = null
}

# Amazon VPC variables
variable "vpc_cidr" {
  type        = string
  description = "The IPv4 CIDR block of the middleware VPC. The value of CIDR block in the primary region and secondary region should not overlap."
}

variable "vpc_newbits" {
  type        = number
  description = "The number of newbits each subnets gets, ensure enough IPs in the subnet CIDR and the newbits to divide across private & public subnets."
  default     = 3
}

variable "vpc_num_private_subnets" {
  type        = number
  description = "The number of middleware VPC private subnets."
}

variable "vpc_num_public_subnets" {
  type        = number
  description = "The number of middleware VPC public subnets. The value of this variable must be same as vpc_num_private_subnets."
}

variable "vpc_private_ingress_nacls" {
  type        = map(any)
  description = "Middleware VPC security group private ingress rules."
  default = {
    tcp_443 = {
      rule_number = 100
      action      = "allow"
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
    }

    tcp_others = {
      rule_number = 2010
      action      = "allow"
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      from_port   = 1024
      to_port     = 65535
    }
  }
}

variable "vpc_public_ingress_nacls" {
  type        = map(any)
  description = "Middleware VPC security group private ingress rules."
  default = {
    tcp_443 = {
      rule_number = 100
      action      = "allow"
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
    }

    tcp_MSK = {
      rule_number = 110
      action      = "allow"
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      from_port   = 9096
      to_port     = 9096
    }

    tcp_MSK_IAM = {
      rule_number = 120
      action      = "allow"
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      from_port   = 9098
      to_port     = 9098
    }

    tcp_others = {
      rule_number = 2010
      action      = "allow" #
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      from_port   = 1024
      to_port     = 65535
    }
  }
}

variable "cluster_vpc_num_private_subnets" {
  type        = number
  description = "The number of cluster VPC private subnets"
  default     = 3
}

variable "sos_vpc_num_private_subnets" {
  type        = number
  description = "The number of SOS VPC private subnets"
  default     = 3
}


variable "connect_cluster_vpc" {
  type        = bool
  description = "Set the value of this variable to true to create a middleware VPC peering connection with the cluster VPC."
  default     = false
}

variable "connect_cluster_vpc_peer_name" {
  type        = string
  description = "The name of the cluster VPC with which you are creating the middleware VPC peering connection. Required when connect_cluster_vpc is true."
  default     = null
}

variable "connect_cluster_vpc_peer_id" {
  type        = string
  description = "The ID of the cluster VPC with which you are creating the middleware VPC peering connection. Required when connect_cluster_vpc is true."
  default     = "Undefined"
}

# AWS Transit Gateway variables
variable "transit_gateway_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create an AWS Transit Gateway."
  default     = false
}

variable "connect_cluster_tga_vpc_id" {
  type        = string
  description = "The ID of cluster VPC."
  default     = null
}

variable "connect_cluster_env_name" {
  type        = string
  description = "The name of the environment cluster."
  default     = null
}
variable "tgw_attach_middleware" {
  type        = bool
  description = "Set the value of this variable to false to detach the peering attachment of middleware VPC with the AWS Transit Gateway."
  default     = true
}

variable "tgw_secondary" {
  type        = bool
  description = "Set the value of this variable to true to establish peering attachment of middleware VPC with the AWS Transit Gateway."
  default     = false
}

variable "tgw_peering_attachment_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create an AWS Transit Gateway inter-region peering attachment."
  default     = false
}

variable "tga_peering_attachment_region" {
  type        = string
  description = "The AWS Region where the inter-region peering attachment has to be established. Required when tgw_peering_attachment_enabled is true."
  default     = null
}

variable "tga_peer_transit_gateway_id" {
  type        = string
  description = "The Transit gateway ID meant for the acceptor Transit gateway for inter-region peering attachment. Required when tgw_peering_attachment_enabled is true."
  default     = null
}

variable "tgw_peer_attachment_rtb_id" {
  type        = string
  description = "The Transit gateway route table ID meant for the acceptor Transit gateway for inter-region peering attachment. Required when tgw_peering_attachment_enabled is true."
  default     = null
}

variable "tgw_amazon_side_asn" {
  type        = number
  description = "Private Autonomous System Number (ASN) for the Amazon side of a BGP session."
  default     = 64512
}

variable "tgw_auto_accept_shared_attachments" {
  type        = string
  description = "Whether resource attachment requests are automatically accepted."
  default     = "enable"
}

variable "tgw_default_route_table_association" {
  type        = string
  description = "Whether resource attachments are automatically associated with the default association route table."
  default     = "disable"
}

variable "tgw_default_route_table_propagation" {
  type        = string
  description = "Whether resource attachments automatically propagate routes to the default propagation route table."
  default     = "disable"
}

variable "tgw_dns_support" {
  type        = string
  description = "Whether DNS support is enabled."
  default     = "enable"
}

variable "tgw_vpn_ecmp_support" {
  type        = string
  description = "Whether VPN Equal Cost Multipath Protocol support is enabled."
  default     = "enable"
}

variable "transit_gateway_default_route_table_association" {
  type        = bool
  description = "Boolean whether this is the default association route table for the AWS Transit Gateway."
  default     = false
}

variable "transit_gateway_default_route_table_propagation" {
  type        = bool
  description = "Boolean whether this is the default propagation route table for the AWS Transit Gateway."
  default     = false
}

# AWS KMS variables
variable "kms_enable_key_rotation" {
  type        = bool
  description = "Set the value to true to enable the KMS key rotation, or false to disable it."
  default     = true
}

variable "kms_enable_multi_region" {
  type        = bool
  description = "Set the value to true to make the KMS key multi-region. Note that a single-region key cannot be converted to a multi-region key after creation."
  default     = true
}

variable "kms_key_waiting_period" {
  type        = number
  description = "Specify the waiting period before deleting the KMS key."
  default     = 7
}

# Amazon RDS PostgreSQL/Amazon Aurora PostgreSQL variables
variable "postgres_03_aurora_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create middleware Amazon Aurora PostgreSQL."
  default     = false
}

variable "postgres_03_name" {
  type        = string
  description = "Amazon RDS PostgreSQL instance or Amazon Aurora PostgreSQL cluster name."
  default     = null
}

variable "postgres_03_version" {
  type        = string
  description = "The database engine version of the Amazon RDS PostgreSQL/Amazon Aurora PostgreSQL."
  default     = "14.3"
}

variable "postgres_03_db_name" {
  type        = string
  description = "Name of the database engine to be used for Amazon RDS PostgreSQL/Amazon Aurora PostgreSQL."
  default     = "postgres"
}

variable "postgres_03_username" {
  type        = string
  description = "Master username for Amazon RDS PostgreSQL DB instance/Amazon Aurora PostgreSQL cluster."
  default     = null
}

variable "postgres_03_password" {
  type        = string
  description = "Master password for Amazon RDS PostgreSQL DB instance/Amazon Aurora PostgreSQL cluster."
  default     = null
  sensitive   = true
}

variable "postgres_03_port" {
  type        = number
  description = "Port on which the Amazon RDS PostgreSQL/Amazon Aurora PostgreSQL DB accepts connections."
  default     = 5432
}

variable "postgres_03_instance_count" {
  type        = number
  description = "Instance count of the Amazon Aurora PostgreSQL cluster. Modify the default value to change the Amazon Aurora PostgreSQL cluster instance count."
  default     = 2
}

variable "postgres_03_instance_class" {
  type        = string
  description = "Instance class of the Amazon RDS PostgreSQL instance/Amazon Aurora PostgreSQL. Modify the default value to change the Amazon RDS PostgreSQL instance class."
  default     = "db.r6g.large"
}

variable "postgres_03_aurora_apply_immediately" {
  type        = bool
  description = "Set the value of this variable to true to apply changes immediately on Amazon Aurora PostgreSQL cluster."
  default     = false
}

variable "postgres_03_aurora_instance_apply_immediately" {
  type        = bool
  description = "Set the value of this variable to true to apply changes immediately Amazon Aurora PostgreSQL cluster instance. Must be set to true when modifying postgres_03_instance_class variable."
  default     = false
}

variable "postgres_03_aurora_encryption_enabled" {
  type        = bool
  description = "This variable is used to create an AWS customer managed KMS key using the postgres_aurora_kms module. Set the value of this variable to false when the postgres_03_enabled variable is false."
  default     = true
}

variable "postgres_03_aurora_global_cluster_id" {
  type        = string
  description = "Amazon Aurora PostgreSQL global cluster id."
  default     = null
}

variable "postgres_03_backup_retention_period" {
  type        = number
  description = "Number of days to retain Amazon RDS PostgreSQL/Amazon Aurora PostgreSQL automatic backups for."
  default     = 7
}

variable "postgres_03_aurora_backup_window" {
  type        = string
  description = "Daily time range during which Amazon Aurora PostgreSQL automatic backups are created if automatic backups are enabled using postgres_03_backup_retention_period."
  default     = "00:00-02:00"
}

variable "postgres_03_aurora_snapshot_identifier" {
  type        = string
  description = "The Amazon Aurora PostgreSQL cluster snapshot identifier that specifies whether or not to create the new Amazon Aurora PostgreSQL cluster from the snapshot."
  default     = null
}

variable "postgres_03_aurora_skip_final_snapshot" {
  type        = bool
  description = "Determines whether a final snapshot is created before the Amazon Aurora PostgreSQL cluster is deleted. If true is specified, no cluster snapshot is created."
  default     = false
}

variable "postgres_03_aurora_auto_minor_version_upgrade" {
  type        = bool
  description = "Minor engine upgrades will not be applied automatically to the Amazon Aurora PostgreSQL DB instance during the maintenance window. To enable this set it to true."
  default     = false
}

variable "postgres_03_primary" {
  type        = bool
  description = "Set the value of this variable to true to enable creation of Amazon Aurora PostgreSQL global database."
  default     = false
}

variable "postgres_03_replica" {
  type        = bool
  description = "Set the value of this variable true to enable creation of Amazon Aurora PostgreSQL secondary cluster."
  default     = false
}

variable "postgres_03_aurora_remove_from_global_cluster" {
  type        = bool
  description = "Set the value of this variable to true to remove the Amazon Aurora PostgreSQL secondary cluster from the global database and promote it to a standalone regional cluster."
  default     = false
}

variable "postgres_03_parameters" {
  description = "A list of DB parameter maps to apply"
  type        = list(map(string))
  default     = [
  {
    name         = "max_prepared_transactions"
    value        = 120
    apply_method = "pending-reboot"
  },
  {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements,pg_cron"
    apply_method = "pending-reboot"
  },
  {
    name         = "cron.database_name"
    value        = "queuemanager"
    apply_method = "pending-reboot"
  }
  ]
}
variable "postgres_03_autoscaling_enabled" {
  type        = bool
  description = "Set the value of this variable to true to enable auto-scaling for Amazon Aurora PostgreSQL."
  default     = false
}
variable "postgres_03_dynamic_scaling_enabled" {
  type        = bool
  description = "Set the value of this variable to true to enable dynamic auto-scaling (target tracking policy). applicable for higher environments."
  default     = false
}

variable "postgres_03_schedule_scaling_enabled" {
  type        = bool
  description = "Set the value of this variable to true to enable schedule based auto-scaling.applicable for lower environments."
  default     = false
}
variable "postgres_03_min_read_replica_count" {
  type    = number
  description = "minimum number of Aurora Read Replicas allowed (0 for no read replicas, 1 for minimum redundancy)."
  default = 0
}

variable "postgres_03_max_read_replica_count" {
  type    = number
  description = "Maximum number of Aurora Read Replicas allowed."
  default = 1
}
variable "postgres_03_autoscaling_target_value" {
  type    = number
  description = "target value of the predefined cloudWatch metric on CPU utilization in percent"
  default = 90.0
}
variable "postgres_03_scale_in_cooldown_period" {
  type    = number
  description = "Cooldown period to prevent rapid scale-in. it is time in seconds before another scale-in can accour"
  default = 300
}

variable "postgres_03_scale_out_cooldown_period" {
  type    = number
  description = "Cooldown period to prevent rapid scaling. it is time in seconds before another scale-out can accour"
  default = 60
}
variable "postgres_03_read_replicas_off_hours" {
  type        = number
  description = "Maximum number of Aurora Read Replicas during off_hours schedule."
  default     = 0
}

variable "postgres_03_read_replicas_business_hours" {
  type        = number
  description = "Minimum number of Aurora Read Replicas during business hours schedule."
  default     = 1
}
# Amazon ElastiCache Redis variables
variable "redis_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create middleware Amazon ElastiCache Redis."
  default     = false
}

variable "redis_name" {
  type        = string
  description = "Amazon ElastiCache Redis replication group identifier."
  default     = null
}

variable "cloudwatch_retention_in_days" {
  type        = number
  default     = 30
  description = "The maximum number of days log events retained in the specified Amazon CloudWatch log group"
}

variable "redis_description" {
  type        = string
  description = "Description for the Amazon ElastiCache Redis replication group."
  default     = null
}

variable "redis_password" {
  type        = string
  description = "Password used to access a password protected server."
  default     = null
  sensitive   = true
}

variable "redis_port" {
  type        = number
  description = "Port number on which each of the cache nodes of Amazon ElastiCache Redis will accept connections."
  default     = 6379
}

variable "redis_engine" {
  type        = string
  description = "The engine. can be redis or valkey"
  default     = "redis"
}

variable "redis_version" {
  type        = string
  description = "The version number of the cache engine to be used for the cache clusters in the Amazon ElastiCache Redis replication group. can be 6.2, 7.0, for redis and 7.2, 8 for valkey"
  default     = "6.2"
}

variable "redis_num_cache_clusters" {
  type        = number
  description = "Number of cache clusters (primary and replicas) the Amazon ElastiCache Redis replication group will have."
  default     = 3
}

variable "redis_node_type" {
  type        = string
  description = "Instance class for Amazon ElastiCache Redis instance. Modify the default value to change the Amazon ElastiCache Redis instance class."
  default     = "cache.r6g.large"
}

variable "redis_multi_az_enabled" {
  type        = bool
  description = "Specifies whether to enable Multi-AZ Support for the Amazon ElastiCache Redis replication group."
  default     = true
}

variable "redis_encryption_enabled" {
  type        = bool
  description = "This variable is used to create an AWS customer managed KMS key using the redis_kms module. Set the value of this variable to false when the redis_enabled variable is false."
  default     = true
}

variable "redis_apply_immediately" {
  type        = bool
  description = "Set the value of this variable to true to apply changes immediately on Amazon ElastiCache Redis cluster. Must be set to true when modifying redis_node_type variable."
  default     = false
}

variable "redis_backup_window" {
  type        = string
  description = "Daily time range (in UTC) during which Amazon ElastiCache will begin taking a daily back of the redis replication group."
  default     = "00:00-01:00"
}

variable "redis_backup_retention_period" {
  type        = number
  description = "Number of days for which Amazon ElastiCache will retain automatic redis replication group backups before deleting them."
  default     = 7
}

variable "redis_snapshot_name" {
  type        = string
  description = "The Amazon ElastiCache Redis backup name that specifies whether or not to create the new Amazon ElastiCache Redis cluster from the backup."
  default     = null
}

variable "redis_failover_lambda_role" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the lambda function role that is used for Amazon ElastiCache Redis failover."
  default     = null
}

variable "redis_primary" {
  type        = bool
  description = "Set the value of this variable to true to enable creation of Amazon ElastiCache Redis global datastore."
  default     = false
}

variable "redis_replica" {
  type        = bool
  description = "Set the value of this variable to true to enable creation of Amazon ElastiCache Redis secondary cluster."
  default     = false
}

variable "redis_restore" {
  type    = bool
  default = false
}

variable "redis_remove_from_global_datastore" {
  type        = bool
  description = "Set the value of this variable to true to remove the Amazon ElastiCache secondary cluster from the global datastore and promote it to a standalone regional cluster."
  default     = false
}

# Amazon DocumentDB variables
variable "docdb_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create middleware Amazon DocumentDB."
  default     = false
}

variable "docdb_global_cluster_id" {
  type        = string
  description = "The Amazon DocumentDB global cluster identifier."
  default     = null
}

variable "docdb_name" {
  type        = string
  description = "The name of your Amazon DocumentDB cluster."
  default     = null
}

variable "docdb_username" {
  type        = string
  description = "Amazon DocumentDB master username."
  default     = null
}

variable "docdb_password" {
  type        = string
  description = "Amazon DocumentDB master password."
  default     = null
  sensitive   = true
}

variable "docdb_port" {
  type        = number
  description = "The port on which the Amazon DocumentDB cluster accepts connections."
  default     = 27017
}

variable "docdb_instance_count" {
  type        = number
  description = "Instance count of the Amazon DocumentDB cluster instance. Modify the default value to change the Amazon DocumentDB cluster instance count."
  default     = 2
}

variable "docdb_instance_class" {
  type        = string
  description = "Instance class of the Amazon DocumentDB cluster. Modify the default value to change the Amazon DocumentDB cluster instance class."
  default     = "db.r6g.2xlarge"
}

variable "docdb_cluster_parameters" {
  type = map(object({
    name  = string
    value = string
  }))
  description = "List of Amazon DocumentDB parameters to apply."
  default = {
    "audit_logs" = {
      name  = "audit_logs"
      value = "enabled"
    }
    "profiler" = {
      name  = "profiler"
      value = "enabled"
    }
    "profiler_threshold_ms" = {
      name  = "profiler_threshold_ms"
      value = 50
    }
    "profiler_sampling_rate" = {
      name  = "profiler_sampling_rate"
      value = 0.0
    }
  }
}

variable "docdb_encryption_enabled" {
  type        = bool
  description = "This variable is used to create an AWS customer managed KMS key using the docdb_kms module. Set the value of this variable to false when the docdb_enabled variable is false."
  default     = true
}

variable "docdb_backup_retention_period" {
  type        = number
  description = "Specify the number of days to retain Amazon DocumentDB automatic backups."
  default     = 7
}

variable "docdb_backup_window" {
  type        = string
  description = "Specify the Amazon DocumentDB cluster backup window in which automatic snapshots are taken."
  default     = "00:00-02:00"
}

variable "docdb_skip_final_snapshot" {
  type        = bool
  description = "Specify false to create a Amazon DocumentDB cluster snapshot with the docdb_final_snapshot_identifier name before the DB cluster is deleted."
  default     = false
}

variable "docdb_snapshot_identifier" {
  type        = string
  default     = null
  description = "The Amazon DocumentDB cluster snapshot identifier that specifies whether or not to create the new Amazon DocumentDB cluster from the snapshot."
}

variable "docdb_apply_immediately" {
  type        = bool
  description = "Set the value of this variable to true to apply changes immediately on Amazon DocumentDB cluster."
  default     = false
}

variable "docdb_instance_apply_immediately" {
  type        = bool
  description = "Set the value of this variable to true to apply changes immediately Amazon DocumentDB cluster instance. Must be set to true when modifying docdb_instance_class variable."
  default     = false
}

variable "docdb_primary" {
  type        = bool
  description = "Set the value of this variable to true to enable creation of Amazon DocumentDB global cluster."
  default     = false
}

variable "docdb_secondary" {
  type        = bool
  description = "Set the value of this variable to true to enable creation of Amazon DocumentDB secondary cluster."
  default     = false
}

variable "docdb_remove_from_global_cluster" {
  type        = bool
  description = "Set the value of this variable to true to remove the Amazon DocumentDB secondary cluster from the global cluster and promote it to a standalone regional cluster."
  default     = false
}

variable "docdb_root_password" {
  type        = string
  description = "Amazon DocumentDB root user password."
  default     = null
  sensitive   = true
}

variable "docdb_metadata_password" {
  type        = string
  description = "Amazon DocumentDB meta user password."
  default     = null
  sensitive   = true
}

variable "docdb_lambda_role" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the lambda function role, that is used for Amazon DocumentDB configuration. Required when docdb_enabled is true."
  default     = null
}

# Amazon MSK variables
variable "msk_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create middleware Amazon MSK."
  default     = false
}

variable "msk_setup_phase" {
  type        = string
  description = "Current phase of MSK setup, valid values: \"initial\", \"second\", \"final\""
}

variable "msk_availability_zone_count" {
  type        = number
  description = "The number of Availability Zones to deploy to"
  default     = 3

  validation {
    condition     = var.msk_availability_zone_count == 2 || var.msk_availability_zone_count == 3
    error_message = "Availability_zone_count must be either 2 or 3."
  }
}

variable "msk_brokers_per_zone" {
  type        = number
  description = "The number of brokers per Availability Zone"
  default     = 1

  validation {
    condition     = var.msk_brokers_per_zone >= 1
    error_message = "Must provision at least 1 broker per zone."
  }
}

variable "msk_broker_instance_type" {
  type        = string
  description = "Instance type to use for the kafka brokers of Amazon MSK cluster. Modify the default value to change the kafka broker instance type."
  default     = "kafka.m5.large"
}

variable "msk_broker_volume_size" {
  type        = number
  description = "The size in GiB of the EBS volume for the data drive on each broker node of Amazon MSK cluster. Minimum value of 1 and maximum value of 16384."
  default     = 500
}

variable "msk_storage_mode" {
  type        = string
  description = "Supported storage mode are either LOCAL or TIERED"
  default     = "LOCAL"

  validation {
    condition     = contains(["LOCAL", "TIERED"], var.msk_storage_mode)
    error_message = "Value for storage mode must be one of: \"LOCAL\", \"TIERED\"."
  }
}

variable "msk_express_broker_disabled" {
  type        = bool
  description = "This param will control the enabling of express broker in msk and turn off standard broker related configuration"
  default     = true
}

variable "msk_provisioned_throughput_enabled" {
  type        = string
  description = "Set to true to enable MSK provisioned throughput"
  default     = ""

  validation {
    condition     = contains(["", "false"], var.msk_provisioned_throughput_enabled)
    error_message = "Valid values for var: provisioned_throughput_enabled are \"\" and \"false\""
  }
}

variable "msk_kafka_version" {
  type        = string
  description = "Amazon MSK cluster Kafka version."
  default     = "2.7.0"
}

variable "msk_certificate_authority_arns" {
  type        = list(string)
  default     = []
  description = "List of AWS Secrets Manager secret ARNs for scram authentication (cannot be set to `true` at the same time as `client_tls_auth_enabled`)."
}

variable "msk_lambda_role_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the lambda function role, that is used by Amazon MSK cluster to create superuser."
  default     = null
}

variable "msk_secondary" {
  type        = bool
  description = "Used to setup and manage Amazon MSK connectors in the secondary region. Must be set to true when msk_secondary_to_primary is true."
  default     = false
}

variable "msk_secondary_to_primary" {
  type        = bool
  description = "Used to setup and manage Amazon MSK connectors in the primary region."
  default     = false
}

variable "msk_encryption_enabled" {
  type        = bool
  description = "This variable is used to create an AWS customer managed KMS key using the msk_kms module. Set the value of this variable to false when the msk_enabled variable is false."
  default     = true
}

variable "msk_connect_iam_role_arn" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the lambda function role, that is used for Amazon MSK connector. Required when msk_enabled is true and msk_secondary is true."
  default     = null
}

variable "msk_mirrormaker_plugin_name" {
  type        = string
  description = "Amazon MSK MirrorMaker plugin name."
  default     = null
}

variable "msk_mirror_source_name" {
  type        = string
  description = "Amazon MSK Source Connector name."
  default     = null
}

variable "msk_mirror_checkpoint_name" {
  type        = string
  description = "Amazon MSK Checkpoint Connector name."
  default     = null
}

variable "msk_connector_excluded_topics" {
  type        = string
  description = "Amazon MSK Connector excluded topics for replication."
  default     = "tenant_fetcher_ae,notifications_pulse,notifications_daily,import_groups,guardium_connector_sync,refresh_health,scheduler_pulse,purge_data,risk_analytics_controller_pulse,retention_purge,uc_status,sync_cr,.*[\\-\\.]internal,.*\\.replica,__.*"
}

#Pass ROSA cluster's PVC CIDR to allow msk connectivity from the cluster
variable "msk_allowed_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks to be allowed to connect to the MSK cluster"
}

# MSK Replicator Variable
variable "msk_replicator_enabled"{
  type    = bool
  default = false
  description = "This is toggle to create a cloud-managed MSK replicator."
}

variable "msk_secondary_replicator" {
  type        = bool
  description = "Used to setup and manage Amazon MSK replicators in the secondary region."
  default     = false
}

/*
Note: The below variables are for Terraform modules that are no longer used by Guardium Insights
TODO: to be removed later

# Amazon S3 variables
variable "s3_enabled" {
  type        = bool
  description = "Toggle to create or skip resource creation"
  default     = false
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
  default     = ""
}

# Amazon Elastic File System variables
variable "efs_enabled" {
  type    = bool
  default = false
}

variable "efs_name" {
  type    = string
  default = null
}

# USED BY SOS AUDIT LOGGING, FACON AND NEW RELIC INFRASTRUCTURE AGENT
variable "kube_config_file" {
  type        = string
  description = "Location of the .kube/config to get the Openshift contects for its login access"
  # Comes from https://github.ibm.com/security-secops/xdr-middleware/blob/main/environments/guardium_dev/us-east-1/gi/gi-XX/giaas/env.hcl
}

# SOS Audit Logging Agent variables
variable "sos_audit_logging_enabled" {
  type        = bool
  description = "Defines if the SOS audit logging will be enabled. Default is true"
  default     = true
}

variable "cluster_logging_subscription_channel" {
  type        = string
  description = "Specify the channel that the cluster logging subscription connects to"
  default     = "stable-5.4"
}

variable "syslog_forwarder_app_name" {
  type        = string
  description = "Specify the app name that identifies the application that sent the log"
  default     = "gisaas"
}

variable "syslog_forwarder_service_port" {
  type        = number
  description = "Specify the port that will be exposed by the syslog forwarder service"
  default     = 9200
}

variable "syslog_forwarder_service_target_port" {
  type        = number
  description = "Specify the port that the syslog forwarder service will forward the traffic to on the pods"
  default     = 6514
}

variable "syslog_forwarder_replica_count" {
  type        = number
  description = "Specify the number of pods of the syslog forwarder deployment"
  default     = 3
}
*/

### variable declarations for GI to gsp connectivity. 

variable "gsp_cluster_vpc_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create a middleware VPC peering connection with the cluster VPC."
  default     = false
}

variable "gsp_cluster_vpc_id" {
  type    = list(string)
  default = []
}


variable "gsp_cluster_vpc_name" {
  type    = list(string)
  default = []
}

# DSPM tgw peering

variable "gsp_tgw_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create a transit gateway peering with DSPM rosa and Lamba VPCs"
  default     = false
}

# DSPM kafka user 

variable "gsp_cluster_id" {
  type        = string
  description = "Identifier for GSP cluster ID. Provide when GSP peering is enabled"
  default     = null
}

variable "gsp_peering_enabled" {
  type        = bool
  default     = false
  description = "This is toggle to create a kafka user for gsp to consume MSK. set it true if peering is enabled"
}


#### redshift cluster variables ######

variable "redshift_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create middleware Amazon Redshift cluster & its associated resources like KMS Key parameter group, subnet group etc."
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

variable "redshift_snapshot_destination" {
  type        = string
  default     = "us-west-2"
  description = "The destination of the snapshot to be copied to"
}

variable "redshift_version" {
  type        = string
  description = "The version of the Amazon Redshift engine to use. See https://docs.aws.amazon.com/redshift/latest/mgmt/cluster-versions.html"
  default     = "1.0"
}

variable "redshift_allow_version_upgrade" {
  type        = bool
  default     = false
  description = "Whether or not to enable major version upgrades which are applied during the maintenance window to the Amazon Redshift engine that is running on the cluster"
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
variable "redshift_availability_zone" {
  description = "The EC2 Availability Zone (AZ) in which you want Amazon Redshift to provision the cluster. Can only be changed if `availability_zone_relocation_enabled` is `true`"
  type        = string
  default     = "us-east-1a"
}
variable "redshift_availability_zone_relocation_enabled" {
  type        = bool
  description = "Set the value of this variable to true to enable AZ relocation for Redshift cluster"
  default     = false
}
variable "redshift_user_name" {
  type        = string
  description = "Amazon Redshift master user name."
  default     = "guardium"
}
variable "redshift_log_exports" {
  type        = list(string)
  default     = ["connectionlog", "userlog", "useractivitylog"]
  description = "Redshift audit log types to export to cloudWatch."
}

variable "redshift_lambda_role" {
  type        = string
  description = "The Amazon Resource Name (ARN) of the lambda function role that is used for Amazon redshift datashare for cross-region."
  default     = null
}

variable "redshift_datashare" {
  type        = string
  description = "Amazon Redshift Datashare name."
  default     = "dev04_cross_region_datashare"
}
variable "redshift_schema" {
  type        = string
  description = "Amazon Redshift schema for the datashare."
  default     = "public"
}
variable "redshift_prmry_datshr" {
  type        = bool
  description = "Toggle to create Datashare in the primary region"
  default     = false
}
variable "redshift_secondary_datshr" {
  type        = bool
  description = "Toggle to create Datashare in the secondary region"
  default     = false
}
variable "redshift_multi_region_enabled" {
  type        = bool
  description = "Set the value of this variable to true for multi region environment. It is for redshift_multihost"
  default     = false
}
variable "redshift_snapshot_schedule_frequency" {
  description = "The definition of the snapshot schedule. The definition is made up of schedule expressions, for example `cron(30 12 *)` or `rate(12 hours)`"
  type        = list(string)
  default     = ["rate(12 hours)"]
}
variable "redshift_snapshot_identifier" {
  type        = string
  description = "The Amazon Redshift cluster snapshot identifier that specifies whether or not to create the new Amazon Redshift cluster from the snapshot."
  default     = null

}
# variable "redshift_msk_iam_role" {
#   type = list(string)
#   default = []
#   description = "Set the value of IAM role for redshift to allow access to msk for streaming ingestion in materialised view"
# }
# below toggle is to delete only Redshift cluster during fail-over and fail-back scenario
variable "delete_redshift_cluster" {
  type        = bool
  description = "Set the value of this variable to true to delete only redshift cluster during fail-over and fail-back before restore from the snapshot"
  default     = false
}
variable "redshift_auto_snapshot_retention_period" {
  description = "The number of days that automated snapshots are retained."
  type        = number
  default     = 7
}
variable "redshift_manual_snapshot_retention_period" {
  type        = number
  default     = 7
  description = "Number of days to retain manual DB snapshots"
}
#DSPM Microfrontend (cloudfront) vars
variable "cloudfront_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create a middleware FE"
  default     = false
}
variable "dspm_env" {
  type        = string
  description = "dspm env"
  default     = null
}

variable "zone_name" {
  description = "The name of the private hosted zone for dspm"
  type        = string
  default     = null
}
variable "dspm_fe_allowed_origin" {
  type        = list(string)
  default     = []
  description = "The allowed origin for CORS in DSPM microfrontend"
}

# Redshift Serverless variables
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
variable "rss_log_exports" {
  type        = list(string)
  default     = ["useractivitylog"]
  description = "The types of logs the namespace can export. Available export types are userlog, connectionlog, and useractivitylog."
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
variable "rss_config_parameters" {
  description = "List of dynamic configuration parameters for Redshift Serverless"
  type = list(object({
    parameter_key   = string
    parameter_value = string
  }))
  default = [
    {
      parameter_key   = "require_ssl"
      parameter_value = true
    },
    {
      parameter_key   = "use_fips_ssl"
      parameter_value = true
    },
    {
      parameter_key   = "enable_user_activity_logging"
      parameter_value = false
    },
    {
      parameter_key   = "enable_case_sensitive_identifier"
      parameter_value = false
    },
    {
      parameter_key   = "auto_analyze"
      parameter_value = "auto_analyze"
    },
    {
      parameter_key   = "auto_mv"
      parameter_value = true
    },
    {
      parameter_key   = "datestyle"
      parameter_value = "ISO,MDY"
    },
    {
      parameter_key   = "extra_float_digits"
      parameter_value = 0
    },
    {
      parameter_key   = "extra_float_digits"
      parameter_value = 0
    }
  ]
}
variable "rss_external_db" {
  type        = string
  default     = "gdsc"
  description = "The name of the db to be created for datashare."
}

variable "redshift_external_db" {
  type        = string
  default     = "dev04_datashare"
  description = "The name of the db to be created for datashare in multi-region env."
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


#Amazon EMR variables

variable "emr_enabled" {
  type        = bool
  description = "Set the value of this variable to true to create middleware Amazon EMR cluster."
  default     = false
}
variable "emr_release_label" {
  description = "Name of the EMR Cluster"
  type = string
  default     = null
}
variable "emr_service_role" {
  description = "IAM role ARN for EMR"
  type        = string
  default     = null
}
variable  "emr_auto_termination_policy_timeout" {
  description = "Timeout in seconds for the auto termination of the cluster in case of idle"
  type        = number
  default     = 10800
}
variable "emr_instance_profile" {
  description = "IAM instance profile for the cluster"
  type        = string
  default     = null
}
variable "emr_termination_protection" {
  description = "boolean value for termination protection"
  type        = bool
  default     = false
}
variable "emr_keep_job_flow_alive_when_no_steps" {
  description = "boolean value for to keep the cluster alive when there are no steps"
  type        = bool
  default     = false
}
variable "emr_encryption_enabled" {
  description = "Enable encryption for EMR"
  type        = bool
  default     = true
}

variable "emr_bucket_name" {
  description = "S3 bucket name for EMR. Specify the bucket name to use. If not provided, a bucket name will be auto-generated."
  type        = string
  default     = null
}

variable "emr_tags" {
  description = "Tags to apply to EMR resources"
  type        = map(string)
  default     = {}
}


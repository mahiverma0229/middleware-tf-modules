variable "cluster_id" {}
variable "namespace_id" {}
variable "identifier_id" {}

# Pass the variable "setup_phase" and set to to initial when setting up a new MSK cluster and running the automation for first time.
# Note that we need to run the automation couple of times to complete the msk cluster setup, to step through each phase in order

variable "policy" {
  type    = string
  default = ""
}
variable "setup_phase" {
  type        = string
  description = "Current phase of MSK setup, valid values: \"initial\", \"second\", \"final\""

  validation {
    condition     = contains(["initial", "second", "final"], var.setup_phase)
    error_message = "Value for setup_phase must be one of: \"initial\", \"second\", \"final\"."
  }
}

variable "brokers_per_zone" {
  type        = number
  description = "The number of brokers per Availability Zone"

  validation {
    condition     = var.brokers_per_zone >= 1
    error_message = "Must provision at least 1 broker per zone."
  }
}

variable "availability_zone_count" {
  type        = number
  description = "The number of Availability Zones to deploy to"

  validation {
    condition     = var.availability_zone_count == 2 || var.availability_zone_count == 3
    error_message = "Availability_zone_count must be either 2 or 3."
  }
}

variable "kafka_version" {
  type        = string
  description = "The desired Kafka software version"
  default     = "2.8.1"
}

variable "kafka_express_broker_disabled" {
  type        = bool
  description = "This param will control the enabling of express broker and msk and turn off standard broker related configuration"
  default     = true
}

variable "storage_mode" {
  type        = string
  description = "Supported storage mode are either LOCAL or TIERED"
  default     = "LOCAL"

  validation {
    condition     = contains(["LOCAL", "TIERED"], var.storage_mode)
    error_message = "Value for storage mode must be one of: \"LOCAL\", \"TIERED\"."
  }
}

variable "public_properties" {
  type        = map(string)
  description = "Contents of the server.properties file. Supported properties are documented in the [MSK Developer Guide](https://docs.aws.amazon.com/msk/latest/developerguide/msk-configuration-properties.html)"
  default = {
    "allow.everyone.if.no.acl.found" = "true"
  }
}

variable "properties" {
  type        = map(string)
  description = "Contents of the server.properties file. Supported properties are documented in the [MSK Developer Guide](https://docs.aws.amazon.com/msk/latest/developerguide/msk-configuration-properties.html)"
  default = {
    "replica.selector.class"         = "org.apache.kafka.common.replica.RackAwareReplicaSelector",
    "allow.everyone.if.no.acl.found" = "false"
    "auto.create.topics.enable"      = "true"
  }
}

variable "broker_instance_type" {
  type        = string
  description = "The instance type to use for the Kafka brokers"
  default     = "kafka.m5.large"
}

variable "broker_volume_size" {
  type        = number
  default     = 500
  description = "The size in GiB of the EBS volume for the data drive on each broker node"
}

variable "msk_provisioned_throughput_enabled" {
  type        = string
  description = "Set to true to enable MSK provisioned throughput"

  validation {
    condition     = contains(["", "false"], var.msk_provisioned_throughput_enabled)
    error_message = "Valid values for var: provisioned_throughput_enabled are \"\" and \"false\""
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where subnets will be created (e.g. `vpc-aceb2723`)"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR where MSK will run"
}

#Pass ROSA cluster's VPC CIDR to allow msk connectivity from the cluster
variable "msk_allowed_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks to be allowed to connect to the MSK cluster"
}

#Pass the subnet id that will be used by MSK cluster.
variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for Client Broker"
}

variable "zone_id" {
  type        = string
  description = "Route53 DNS Zone ID for MSK broker hostnames"
  default     = null
}

variable "enable_iam_client_authentication" {
  type        = bool
  description = "Enables IAM client authentication"
  default     = true
}

variable "enable_scram_client_authentication" {
  type        = bool
  description = "Enables SCRAM client authentication"
  default     = true
}

## Middleware Security group ID attached to MSK security-group ID
variable "middleware_security_group_id"{ 
  type = string
  description = "This is the security group id of the middleware services middleware-sg-for-all"
}

# Intentionally not deprecated via security_group_inputs.tf since it cannot effectively be replaced via var.additional_security_group_rules.
# This is because the logic to create these rules exists within this module, and should not be passed in by the consumer
# of this module.
variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "List of CIDR blocks to be allowed to connect to the cluster"
}

variable "client_broker" {
  type        = string
  default     = "TLS"
  description = "Encryption setting for data in transit between clients and brokers. Valid values: `TLS`, `TLS_PLAINTEXT`, and `PLAINTEXT`"
}

variable "encryption_in_cluster" {
  type        = bool
  default     = true
  description = "Whether data communication among broker nodes is encrypted"
}

variable "msk_kms_key_arn" {
  type        = string
  description = "Specify the ARN of the AWS customer managed KMS encryption key. If not specified, the default AWS managed KMS ('aws/kafka' managed service) key will be used for encrypting the data at rest"
  default     = null
}
variable "encryption_at_rest_kms_key_arn" {
  type        = string
  description = "Specify the ARN of the AWS customer managed KMS encryption key. If not specified, the default AWS managed KMS ('aws/kafka' managed service) key will be used for encrypting the data at rest"
  default     = null
}

variable "enhanced_monitoring" {
  type        = string
  default     = "DEFAULT"
  description = "Specify the desired enhanced MSK CloudWatch monitoring level. Valid values: `DEFAULT`, `PER_BROKER`, and `PER_TOPIC_PER_BROKER`"
}

#certificate_authority_arns should be set to the PCA arn during the next run when enabling the sasl and tls.
variable "certificate_authority_arns" {
  type        = list(string)
  default     = []
  description = "List of ACM Certificate Authority Amazon Resource Names (ARNs) to be used for TLS client authentication"
}

variable "jmx_exporter_enabled" {
  type        = bool
  default     = true
  description = "Set `true` to enable the JMX Exporter"
}

variable "node_exporter_enabled" {
  type        = bool
  default     = true
  description = "Set `true` to enable the Node Exporter"
}

variable "cloudwatch_logs_enabled" {
  type        = bool
  default     = true
  description = "Indicates whether you want to enable or disable streaming broker logs to Amazon CloudWatch Logs"
}

variable "cloudwatch_retention_in_days" {
  type        = number
  default     = 30
  description = "The maximum number of days log events retained in the specified Amazon CloudWatch log group"
}

variable "firehose_logs_enabled" {
  type        = bool
  default     = false
  description = "Indicates whether you want to enable or disable streaming broker logs to Kinesis Data Firehose"
}

variable "firehose_delivery_stream" {
  type        = string
  default     = ""
  description = "Name of the Kinesis Data Firehose delivery stream to deliver logs to"
}

variable "s3_logs_enabled" {
  type        = bool
  default     = false
  description = " Indicates whether you want to enable or disable streaming broker logs to S3"
}

variable "s3_logs_bucket" {
  type        = string
  default     = ""
  description = "Name of the S3 bucket to deliver logs to"
}

variable "s3_logs_prefix" {
  type        = string
  default     = ""
  description = "Prefix to append to the S3 folder name logs are delivered to"
}

variable "storage_autoscaling_target_value" {
  type        = number
  default     = 60
  description = "Percentage of storage used to trigger autoscaled storage increase"
}

variable "storage_autoscaling_max_capacity" {
  type        = number
  default     = null
  description = "Maximum size the autoscaling policy can scale storage. Defaults to `broker_volume_size`"
}

variable "storage_autoscaling_disable_scale_in" {
  type        = bool
  default     = false
  description = "If the value is true, scale in is disabled and the target tracking policy won't remove capacity from the scalable resource."
}

# Mirrormaker variables
variable "secondary_to_primary" {
  type = bool
}

variable "mirrormaker_bucket" {
  type    = string
  default = "mirrormaker-bucket"
}

variable "mirrormaker_file_type" {
  type    = string
  default = "JAR"
}

variable "mirrormaker_plugin" {
  type    = string
  default = null
}

variable "mirror_source_name" {
  type    = string
  default = null
}

variable "mirror_checkpoint_name" {
  type    = string
  default = null
}

variable "role_arns" {
  type    = list(string)
  default = ["arn:aws:iam::aws:policy/AmazonMSKFullAccess", "arn:aws:iam::aws:policy/AdministratorAccess"]
}

variable "msk_secondary" {
  type    = bool
  default = false
}

variable "remote_state_bucket" {
  type = string
}

variable "remote_state_key" {
  type = string
}

variable "remote_state_profile" {
  type = string
}

variable "remote_state_region" {
  type = string
}

variable "kafkaconnect_version" {
  type    = string
  default = "2.7.1"
}

variable "msk_connect_iam_role_arn" {
  type = string
}

variable "aws_ca_crt_names" {
  type        = set(string)
  default     = [
    "AmazonRootCA1",
    "AmazonRootCA2",
    "AmazonRootCA3",
    "AmazonRootCA4",
    "SFSRootCAG2"
  ]
}
variable "msk_connector_excluded_topics" {
  type        = string
  description = "MSK connector excluded topics for replication"
  default     = "tenant_fetcher_ae,notifications_pulse,notifications_daily,import_groups,guardium_connector_sync,refresh_health,scheduler_pulse,purge_data,risk_analytics_controller_pulse,retention_purge,uc_status,sync_cr,.*[\\-\\.]internal,.*\\.replica,__.*"
}

variable "msk_connector_replication_factor" {
  type        = string
  description = "MSK connector replication factor"
  default     = "2"
}

# GSP cluster ID for kafka user 

variable "gsp_cluster_id" {
  type        = string
  description = "Identifier for GSP cluster ID"
  default     = null
}

# toggle if GI to gsp peering is enabled 
variable "gsp_peering_enabled" {
  type    = bool
  default = false
  description = "This is toggle to create a kafka user for gsp to consume MSK. set it true if peering is enabled"
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
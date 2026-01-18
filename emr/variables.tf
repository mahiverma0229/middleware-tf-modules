variable "vpc_id" {}
variable "emr_subnet_ids" {
  description = "The list of VPC subnet IDs to associate with the EMR security group"
}
variable "emr_name" {
  description = "Name of the EMR Cluster"
  type = string
  default = null
}
variable "emr_enabled" {
  description = "Boolean flag to enable/disable EMR cluster creation"
  type        = bool
  default     = true
}
variable "emr_release_label" {
  description = "EMR release version (e.g., emr-6.9.0)"
  type = string
}
variable "emr_service_role" {
  description = "IAM role ARN for EMR"
  type        = string
}
variable "emr_scale_down_behavior" {
  description = "Scale down behavior of the cluster"
  type = string
  default = "TERMINATE_AT_TASK_COMPLETION"
}
variable "emr_unhealthy_node_replacement" {
  description = "Enable unhealthy node replacement"
  type        = bool
  default     = true
}
variable  "emr_auto_termination_policy_timeout" {
  description = "Timeout in seconds for the auto termination of the cluster in case of idle"
  type        = number
}
variable "emr_tgw_route_depends_on" {
  description = "Resources that the EMR cluster depends on (e.g., route tables)"
  type        = list(any)
  default     = []
}
variable "emr_termination_protection" {
  description = "boolean value for termination protection"
  type        = bool
}
variable "emr_keep_job_flow_alive_when_no_steps" {
  description = "boolean value for to keep the cluster alive when there are no steps"
  type        = bool
}
variable "emr_instance_profile" {
  description = "IAM instance profile for the cluster"
  type        = string
}
variable "emr_key_name" {
  description = "Name of the key pair to use for SSH access"
  type        = string
  default     = "archive-emr-key-pair"
}
variable "emr_applications" {
  description = "List of applications to install on the EMR cluster"
  type        = list(object({
    name = string
  }))
  default     = [
    { name = "Hadoop" },
    { name = "Hive" },
    { name = "Livy" },
    { name = "Spark" }
  ]
}
variable "emr_tags" {
  description = "Tags for the EMR cluster"
  type        = map(string)
  default     = {}
}
variable "emr_encryption_enabled" {
  description = "Enable encryption for EMR"
  type        = bool
  default     = false
}

variable "emr_kms_key_arn" {
  description = "ARN of the KMS key to use for EMR encryption"
  type        = string
  default     = null
}
variable "emr_instance_type" {
  description = "Instance type for the master, core and task nodes"
  type = string
  default = "m5.xlarge"
}

variable "emr_ebs_config_size" {
  description = "ebs config size for the master, core and task nodes"
  type = string
  default = "32"
}
variable "emr_ebs_config_type" {
  description = "ebs config type for the master, core and task nodes"
  type = string
  default = "gp3"
}
variable "emr_ebs_config_volumes_per_instance" {
  description = "ebs config volumes per instance for the master, core and task nodes"
  type = number
  default = 2
}

variable "emr_configurations" {
  description = "List of EMR configurations"
  type        = list(object({
    classification = string
    properties = map(string)
  }))
  default     = [
    {
      classification = "iceberg-defaults"
      properties = {
        "iceberg.enabled" = "true"
      }
    },
    {
      classification = "spark-defaults"
      properties = {
        "spark.hadoop.fs.s3a.connection.maximum" = "200"
        "spark.hadoop.fs.s3a.connection.request.timeout" = "60000"
        "spark.hadoop.fs.s3a.connection.timeout" = "60000"
        "spark.hadoop.fs.s3a.fast.upload" = "true"
        "spark.hadoop.fs.s3a.fast.upload.default" = "true"
        "spark.hadoop.fs.s3a.keepalivetime" = "60000"
        "spark.hadoop.fs.s3a.threads.max" = "100"
        "spark.sql.catalog.spark_catalog" = "org.apache.iceberg.spark.SparkCatalog"
        "spark.sql.catalog.spark_catalog.type" = "hadoop" 
        "spark.sql.catalog.spark_catalog.http-client.apache.connection-timeout-ms" = "60000"
        "spark.sql.catalog.spark_catalog.http-client.apache.max-connections" = "3000"
        "spark.sql.catalog.spark_catalog.http-client.apache.socket-timeout-ms" = "60000"
        "spark.sql.catalog.spark_catalog.http-client.type" = "apache"
        "spark.sql.catalog.spark_catalog.io-impl" = "org.apache.iceberg.aws.s3.S3FileIO"
        "spark.sql.catalogImplementation" = "hive"
        "spark.sql.extensions" = "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions"
        "spark.hadoop.fs.s3a.impl" = "org.apache.hadoop.fs.s3a.S3AFileSystem"
        "spark.hadoop.fs.s3a.endpoint" = "s3.amazonaws.com" 
      }
    },
    {
      classification = "hive-site"
      properties = {
        "hive.metastore.client.factory.class" = "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
      }
    },
    {
      classification = "spark-hive-site"
      properties = {
        "hive.metastore.client.factory.class" = "com.amazonaws.glue.catalog.metastore.AWSGlueDataCatalogHiveClientFactory"
      }
    }
  ]
}



variable "emr_bootstrap_actions" {
  description = "List of bootstrap actions for the EMR cluster"
  type        = list(object({
    Name = string
    Path = string
    Args = list(string)
  }))
  default     = []
}

variable "emr_steps" {
  description = "List of steps for the EMR cluster"
  type        = list(object({
    Name = string
    ActionOnFailure = string
    Jar = string
    Properties = string
    Args = list(string)
    Type = string
  }))
  default     = []
}

variable "emr_managed_scaling_policy_unit_type" {
  description = "Unit type for managed scaling policy"
  type = string
  default = "InstanceFleetUnits"
}
variable "emr_managed_scaling_policy_minimum_capacity_units" {
  description = "Minimum Capacity Units for managed scaling policy"
  type = number
  default = 1
}
variable "emr_managed_scaling_policy_maximum_capacity_units" {
  description = "Maximum Capacity Units for managed scaling policy"
  type = number
  default = 4
}
variable "emr_managed_scaling_policy_maximum_ondemand_capacity_units" {
  description = "Maximum On Demand Capacity Units for managed scaling policy"
  type = number
  default = 4
}
variable "emr_managed_scaling_policy_maximum_core_capacity_units" {
  description = "Maximum Core Capacity Units for managed scaling policy"
  type = number
  default = 4
}
variable "cluster_id" {
  description = "Cluster identifier for resource naming"
  type        = string
  default     = null
}

variable "namespace_id" {
  description = "Namespace identifier for resource naming"
  type        = string
  default     = null
}

variable "identifier_id" {
  description = "Additional identifier for resource naming"
  type        = string
  default     = null
}
variable "emr_port" {
  description = "Port used for EMR master node communication"
  type        = number
  default     = 15002
}
# S3 Bucket variables (passed from emr-s3 module)
variable "emr_bucket_name" {
  description = "Name of the S3 bucket for EMR (from emr-s3 module)"
  type        = string
  default     = ""
}

variable "emr_bootstrap_scripts_location" {
  description = "S3 path to bootstrap scripts folder (from emr-s3 module)"
  type        = string
  default     = ""
}

variable "emr_warehouse_location" {
  description = "S3 path to Iceberg warehouse folder (from emr-s3 module)"
  type        = string
  default     = ""
}

variable "emr_logs_location" {
  description = "S3 path to EMR logs folder (from emr-s3 module)"
  type        = string
  default     = ""
}

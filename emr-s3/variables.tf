variable "emr_s3_enabled" {
  description = "Enable/disable EMR S3 bucket creation. Set to false to delete the bucket and all its contents."
  type        = bool
  default     = true
}

variable "cluster_id" {
  description = "Cluster identifier (e.g., sgi-dev03, sgi-rel03). Used to derive environment name for bucket naming."
  type        = string
}

variable "emr_bucket_name" {
  description = "S3 bucket name for EMR. If provided, will use this bucket name instead of auto-generating one."
  type        = string
  default     = null
}

variable "namespace_id" {
  description = "Namespace identifier for resource naming and tagging"
  type        = string
}

variable "identifier_id" {
  description = "Identifier for resource naming and tagging"
  type        = string
}

variable "emr_tags" {
  description = "Tags to apply to EMR S3 resources"
  type        = map(string)
  default     = {}
}

variable "emr_encryption_enabled" {
  description = "Enable KMS encryption for EMR S3 bucket"
  type        = bool
  default     = false
}

variable "emr_kms_key_arn" {
  description = "KMS key ARN for EMR S3 bucket encryption (required if emr_encryption_enabled is true)"
  type        = string
  default     = ""
}


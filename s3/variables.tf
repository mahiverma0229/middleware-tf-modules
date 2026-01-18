## Variables
variable "s3_bucket_name" {
  type        = string
  description = "Optional override for s3 bucket name"
  default     = ""

  # Constraints: Must be between 3 (min) and 63 (max) character long, can have only lowercase letters,numbers,dot(.)
  # and hyphens,begin and end with letter o number, not start with prefix xn--
  # not end with the suffix -s3alias,--ol-s3, no ip address(1.1.1.1)
  # can be left empty, it will be generated automatically
  validation {
    condition = var.s3_bucket_name == "" ? true : (
      (length(var.s3_bucket_name) <= 63 &&
        can(regex("^[a-z0-9]([a-z0-9.-]*[a-z0-9])?$", var.s3_bucket_name)) &&
        !can(regex("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$", var.s3_bucket_name)) &&
        !startswith(var.s3_bucket_name, "xn--") &&
        !endswith(var.s3_bucket_name, "-s3alias") &&
        !endswith(var.s3_bucket_name, "--ol-s3")
      )
    )
    error_message = "The input does not meet validation condition for the s3 bucket name."
  }
}

variable "cluster_id" {
  type        = string
  description = "Identifier for CP4S Cluster"
}

variable "namespace_id" {
  type        = string
  description = "Identifier for namespace middleware is assocated with in CP4S cluster"
}

variable "s3_bucket_user_name" {
  type        = string
  default     = ""
  description = "Existing user in aws account, functional id."
}

variable "s3_bucket_user_arn" {
  type        = string
  default     = ""
  description = "Existing user arn in aws account, functional id."
}

variable "s3_lifecycle_archival_rule_status" {
  type        = string
  default     = "Disabled"
  description = "s3 lifecycle status"
}

variable "s3_lifecycle_archival_storage_class" {
  type        = string
  default     = "GLACIER"
  description = "Indicates s3 default storage class"
}

variable "s3_bucket_versioning" {
  type        = string
  default     = "Disabled"
  description = "Versioning s3 is enabled or disabled."
}

variable "s3_lifecycle_expiration_status" {
  type        = string
  default     = "Disabled"
  description = "Max days to keep objects on s3 bucket"
}

variable "s3_lifecycle_expiration_days" {
  type        = number
  default     = 0
  description = "Max days to keep objects on s3 bucket (must be overridden if rule is enabled)"
}

variable "s3_lifecycle_archival_storage_prefix" {
  type        = string
  default     = "/"
  description = "Indicates s3 default storage prefix"
}

variable "s3_lifecycle_transition_days" {
  type        = number
  default     = 0
  description = "Number of days to keep objects before transition"
}

variable "cluster_id" {
  type        = string
  description = "Identifier for CP4S Cluster"
}

variable "namespace_id" {
  type        = string
  description = "Identifier for namespace middleware is assocated with in CP4S cluster"
}

variable "els_name" {
  type        = string
  description = "Name for els domain"
  default     = null

  # Constraints: Must be between 3 and 28 characters, valid characters are a-z(lowecase only), 0-9, and - (hyphen)
  # can be left null, it will be generated automatically
  validation {
    condition = var.els_name == null ? true : (
      can(regex("^[a-z][a-z0-9-]{2,27}$", var.els_name)
      )
    )
    error_message = "The input does not meet validation condition for the els domain."
  }
}

variable "els_version" {
  type = string
}

variable "els_node_count" {
  type    = number
  default = 1
}

variable "els_instance_type" {
  type = string
}

variable "els_zone_awareness_enabled" {
  type    = bool
  default = false
}

variable "els_warm_enabled" {
  type    = bool
  default = false
}

variable "els_dedicated_master_enabled" {
  default = false
}

variable "els_az_count" {
  type    = number
  default = 2
}

variable "els_subnet_ids" {
  type = list(string)
}

variable "els_security_group_id" {
  type = string
}

variable "els_master_user_name" {
  type        = string
  description = "Username for the admin / master user, if set to null will auto-generate"
}

variable "els_master_user_password" {
  type      = string
  sensitive = true
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "els_ebs_enabled" {
  type    = bool
  default = true
}

variable "els_volume_size" {
  type = number
}

variable "els_volume_type" {
  type = string
}

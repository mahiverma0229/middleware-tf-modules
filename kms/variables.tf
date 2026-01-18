variable "kms_replica" {
  type    = bool
  default = false
}

variable "kms_key_description" {
  type        = string
  description = "Specify the description of the KMS key"
  default     = "Managed by Terraform"
}

variable "kms_key_usage" {
  type        = string
  description = "Specify the intended use of the key. Valid values are ENCRYPT_DECRYPT, SIGN_VERIFY, or GENERATE_VERIFY_MAC"
  default     = "ENCRYPT_DECRYPT"
}

variable "kms_customer_master_key_spec" {
  type        = string
  description = "Specify whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values are SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, HMAC_256, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1"
  default     = "SYMMETRIC_DEFAULT"
}

variable "kms_key_policy" {
  type        = string
  description = "Provide the KMS key policy. If a key policy is not specified, AWS gives the KMS key a default key policy"
  default     = null
}

variable "kms_key_waiting_period" {
  type        = number
  description = "Specify the waiting period before deleting the KMS key"
  default     = 30
}

variable "kms_key_is_enabled" {
  type        = bool
  description = "Set the value to true to enable the KMS key, or false to disable it"
  default     = true
}

variable "kms_enable_key_rotation" {
  type        = bool
  description = "Set the value to true to enable the KMS key rotation, or false to disable it"
  default     = false
}

variable "kms_enable_multi_region" {
  type        = bool
  description = "Set the value to true to make the KMS key multi-Region. Note that a single-Region key cannot be converted to a multi-Region key after creation."
  default     = false
}

variable "kms_primary_key_arn" {
  type        = string
  description = "Specify the ARN of the multi-Region primary key to replicate"
  default     = null
  sensitive   = true
}

variable "kms_key_alias" {
  type        = string
  description = "Provide an alias for the KMS customer master key"
  default     = null
}

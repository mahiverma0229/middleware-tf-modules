variable "all_middleware_secrets" {
}

variable "secret_map"{
    default = {
    key1 = "value1"
  }
  type = map(string)
}
variable "middleware_secrets_manager_name" {
  type = string
}

variable "sm_encryption_at_rest_kms_key_arn" {
  type = string
}

variable "name_prefix" {
  type        = string
  description = "transitgateway name"

  # Constraints: Use only letters, numbers, hyphen or underscore with no spaces up to 128 characters
  validation {
    condition = can(regex("^[A-Za-z0-9-_]+$", var.name_prefix)) && length(var.name_prefix) <= 128 && length(var.name_prefix) > 0
    error_message = "The input does not meet validation condition for the transitgateway name."
  }
}
variable "cluster_id" {}
variable "namespace_id" {}
variable "aws_region" {}

variable "connect_cluster_env_name"{}

variable "old_subnets_toggle" {
  type        = bool
  description = "This variable is added to provide support for 3 private subnets for gi maintaining backwards compatibility of 2 private subnets"
  default     = true
}

variable "tga_peering_attachment_region" {
  type        = string
  description = "The region where the transit-gateway peering attachment has to be established"
}

variable "tga_peer_transit_gateway_id" {
  type        = string
  description = "The transit-gateway id meant for peering attachment"
}

variable "tgw_peering_attachment_enabled" {
  type = bool
  description = "This is a toggle variable to enable/disable tgw cross-region peering attachment"
}

variable "tgw_peer_attachment_rtb_id"{
  type        = string
  description = "This is meant for transit-gateway route-table id for acceptor tgw"
}

variable "connect_cluster_tga_vpc_id" {
  type        = string
  description = "The vpc_id of the cluster vpc"
}

variable "amazon_side_asn" {
    default = 64512
}

variable "auto_accept_shared_attachments" {
    default = "enable"
}

variable "default_route_table_association" {
    default = "disable"
}

variable "default_route_table_propagation" {
    default = "disable"
}

variable "dns_support" {
    default = "enable"
}

variable "vpn_ecmp_support" {
    default = "enable"
}

variable "subnet_ids" {}

variable "vpc_id" {}

variable "transit_gateway_default_route_table_association" {
    default = false
}

variable "transit_gateway_default_route_table_propagation" {
    default = false
}

variable "tgw_secondary" {
    type = bool
    default = false
}

variable "tgw_attach_middleware" {
    type = bool
    default = true
}

variable "selected_cluster_vpc_num_private_subnets" {
    type    = number
    default = 3
}

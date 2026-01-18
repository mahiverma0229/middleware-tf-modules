
# general configuration

variable "cluster_id" {
  type        = string
  description = "Identifier for CP4S Cluster"
}

variable "namespace_id" {
  type        = string
  description = "Identifier for namespace middleware is associated with in CP4S cluster"
}

variable "vpc_prefix" {
  type        = string
  default     = "middleware"
}

variable "name_prefix" {
  type        = string
  default     = "xdr"
}

variable "vpc_cidr" {
  type = string
}

variable "old_subnets_toggle" {
  type        = bool
  description = "set to true, if expecting the old subnet divisions -- pre MCSP for Threat Management"
  default     = false
}

variable "vpc_newbits" {
  type        = number
  description = "newbits each subnets gets, ensure enough IPs in the subnet cidr + newbits to divide across private & public subnets "
}

variable "vpc_num_private_subnets" {
  type        = number
  description = "number of private subnets, ensure enough IPs in vpc_cidr"
}

variable "vpc_num_public_subnets" {
  type        = number
  description = "number of public subnets, ensure enough IPs in vpc_cidr"
}

variable "gsp_cluster_vpc_enabled" {
  type        = bool
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

variable "middleware_vpc_id" {
  description = "Assign Middleware VPC ID"
}

variable "middleware_vpc_cidr" {
  description = "Assign Middleware VPC ID"
}
variable "private_route_table_ids" {
  description = "List of private route table IDs from VPC module"
  type        = list(string)
}

variable "public_route_table_ids" {
  description = "List of private route table IDs from VPC module"
  type        = list(string)
}
variable "aws_account_id" {
  type = string
}

variable "aws_partition" {
  type = string
  default = "aws"
}

variable "aws_region" {
  type = string
}



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

variable "connect_cluster_vpc" {
  type        = bool
  default     = false
}

variable "connect_cluster_vpc_peer_id" {
  type        = string
  default     = "Undefined"
}

variable "connect_cluster_vpc_peer_name" {
  type        = string
  default     = null
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

variable "private_ingress_nacls" {
  description = "Private subnet ingress NACLs definition map"
  type        = map
  default     = {
    tcp_443 = {
      rule_number = 100
      action = "allow"  #
      protocol = "tcp"
      cidr_block = "0.0.0.0/0"
      from_port = 443
      to_port = 443
    }
  }
}

variable "private_egress_nacls" {
  description = "Private subnet egress NACLs definition map"
  type        = map
  default     = {
    tcp_443 = {
      rule_number = 100
      action = "allow"
      protocol = "all"
      cidr_block = "0.0.0.0/0"
      from_port = 0
      to_port = 0
    }
  }
}

variable "public_ingress_nacls" {
  description = "Public subnet ingress NACLs definition map"
  type        = map
  default     = {
    tcp_443 = {
      rule_number = 100
      action = "allow"
      protocol = "tcp"
      cidr_block = "0.0.0.0/0"
      from_port = 443
      to_port = 443
    }
  }
}

variable "public_egress_nacls" {
  description = "Public subnet egress NACLs definition map"
  type        = map
  default     = {
    tcp_443 = {
      rule_number = 100
      action = "allow"
      protocol = "all"
      cidr_block = "0.0.0.0/0"
      from_port = 0
      to_port = 0
    }
  }
}

variable "security_group_rules" {
  description = "List of rules to extend security group with"
  type        = map(any)
  /*
  Expected value like:
  {
    egress = {
      rule_name = {
        description = "sample desc"
        protocol = "tcp"
        from_port = 443
        to_port = 443
        cidr = "10.0.0.0/8"
      },
      ...
    },
    ingress = {
      ...rules...
    }
  }

*/
}

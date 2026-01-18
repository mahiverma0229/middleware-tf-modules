resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge (
    {
      Name = "${var.vpc_prefix}-${var.cluster_id}-${var.namespace_id}-vpc"
    }
  )
}

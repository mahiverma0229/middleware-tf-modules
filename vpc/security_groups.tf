locals {
  vpc_peer_error   = "Error - not peered, and 'vpc_peer' used in security group definition"
  vpc_peering_cidr = var.connect_cluster_vpc ? tostring(data.aws_vpc.selected_cluster_vpc.0.cidr_block) : local.vpc_peer_error
}

resource "aws_security_group" "all_middleware_sg" {

  name        = "${var.cluster_id}-${var.namespace_id}-sg-for-all"
  description = "${var.vpc_prefix}-${var.cluster_id}-${var.namespace_id} tmp Security Group for all services"
  vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.security_group_rules.ingress
    content {
      description = ingress.value.description
      protocol    = ingress.value.protocol
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      cidr_blocks = ingress.value.cidr == "vpc_peer" ? [local.vpc_peering_cidr] : [ingress.value.cidr]
    }
  }

  dynamic "egress" {
    for_each = var.security_group_rules.egress
    content {
      description = egress.value.description
      protocol    = egress.value.protocol
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      cidr_blocks = egress.value.cidr == "vpc_peer" ? [local.vpc_peering_cidr] : [egress.value.cidr]
    }
  }

  lifecycle { create_before_destroy = true }
  tags = {
    Name = "${var.vpc_prefix}-${var.cluster_id}-${var.namespace_id}-sg-for-all"
  }
}

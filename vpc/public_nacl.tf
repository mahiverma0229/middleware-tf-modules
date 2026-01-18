resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.vpc.id

  tags = merge (
    {
      Name = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-public-nacl"
    }
  )
}

resource "aws_network_acl_association" "public_nacl_association" {
  count = var.vpc_num_public_subnets

  network_acl_id = aws_network_acl.public_nacl.id
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
}

## NEW below

resource "aws_network_acl_rule" "public_ingress" {
  for_each = var.public_ingress_nacls

  network_acl_id = aws_network_acl.public_nacl.id

  rule_number    = each.value.rule_number
  rule_action    = each.value.action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port

  egress         = false
}
resource "aws_network_acl_rule" "public_egress" {
  for_each = var.public_egress_nacls

  network_acl_id = aws_network_acl.public_nacl.id

  rule_number    = each.value.rule_number
  rule_action    = each.value.action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port

  egress         = true
}

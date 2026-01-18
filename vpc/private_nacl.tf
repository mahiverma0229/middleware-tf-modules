resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.vpc.id

  tags = merge (
    {
      Name = "${var.name_prefix}-${var.cluster_id}-${var.namespace_id}-private-nacl"
    }
  )
}

resource "aws_network_acl_association" "private_nacl_association" {
  count = var.vpc_num_private_subnets

  network_acl_id = aws_network_acl.private_nacl.id
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
}

resource "aws_network_acl_rule" "private_ingress" {
  for_each = var.private_ingress_nacls
 
  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  egress         = false
}
resource "aws_network_acl_rule" "private_egress" {
  for_each = var.private_egress_nacls

  network_acl_id = aws_network_acl.private_nacl.id
  rule_number    = each.value.rule_number
  rule_action    = each.value.action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port

  egress         = true
}

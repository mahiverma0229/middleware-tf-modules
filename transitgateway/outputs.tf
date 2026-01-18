output "transit_gateway_id" {
  value = one(aws_ec2_transit_gateway.tgw[*].id)
}

output "transit_gateway_route_table_id" {
  value = one(aws_ec2_transit_gateway_route_table.tgw_rtb[*].id)
}
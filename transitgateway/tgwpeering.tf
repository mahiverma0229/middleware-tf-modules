# Create tga peering type --> Requestor connection 

resource "aws_ec2_transit_gateway_peering_attachment" "tg_peering_attachment_requestor" {
   count = var.tgw_peering_attachment_enabled ? 1 : 0
   peer_region             = var.tga_peering_attachment_region
   peer_transit_gateway_id = var.tga_peer_transit_gateway_id
   transit_gateway_id      = aws_ec2_transit_gateway.tgw.id

   tags = {
     Name = "${var.cluster_id}-TGW-Peering-Requestor"
   }
}

#Accept the peering connection --> Acceptor connection

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tg_peering_attachment_acceptor" {
  count = var.tgw_peering_attachment_enabled ? 1 : 0
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.tg_peering_attachment_requestor[count.index].id

  tags = {
    Name = "${var.cluster_id}-TGW-Peering-Acceptor"
  }

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment.tg_peering_attachment_requestor
  ]
}

#Create Route Table Association using peer attachment -> using requester tgw peering attachment

resource "aws_ec2_transit_gateway_route_table_association" "tgw_requester_rta" {
  count = var.tgw_peering_attachment_enabled ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.tg_peering_attachment_requestor[count.index].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tgw_rtb.id
}

#Create Route Table Association using peer attachment -> using accepter tgw peering attachment

# data "aws_ec2_transit_gateway_route_table" "tg_peering_attachment_acceptor_rtb"{
#     provider = aws.peer
#     filter {
#       name = "tag:Name"
#       values = ["*-tg-rtb"]
#     }      
# }

resource "aws_ec2_transit_gateway_route_table_association" "tgw_acceptor_rta" {
  count = var.tgw_peering_attachment_enabled ? 1 : 0
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment_accepter.tg_peering_attachment_acceptor[count.index].id
  transit_gateway_route_table_id = var.tgw_peer_attachment_rtb_id
}

#Update Static route in tgw-route-table using the tgw-peer attachment [us-west-2]

#Update Static route in tgw-route-table using the tgw-peer attachment [us-east-1]

#Update the private-route table of vpc with the cidr range of the vpc to send traffic targeting tgw,
#and for return traffic, update the cidr range of the request traffic in the response vpc's private route table 




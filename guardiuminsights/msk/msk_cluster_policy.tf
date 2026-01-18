resource "aws_msk_cluster_policy" "aws_msk_cluster_policy" {
  count = var.msk_replicator_enabled ? 1 : 0 
  cluster_arn = aws_msk_cluster.aws_msk_cluster.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "MskClusterPolicyForReplicator"
      Effect = "Allow"
      Principal = {
        "Service" = "kafka.amazonaws.com"
      }
      Action = [
        "kafka:CreateVpcConnection",
        "kafka:GetBootstrapBrokers",
        "kafka:DescribeClusterV2"
      ]
      Resource = aws_msk_cluster.aws_msk_cluster.arn
    }]
  })
}

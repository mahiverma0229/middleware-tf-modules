data "aws_iam_role" "opensearch_iam_service_linked_role" {
  name = "AWSServiceRoleForAmazonElasticsearchService"
}

resource "random_string" "opensearch_random_id" {
  length  = 5
  special = false
  upper   = false
}

locals {
  # gives us a max 28 char name.
  dynamic_domain_name = length("${var.cluster_id}-${var.namespace_id}-els") > 28 ? join("-", [substr("${var.cluster_id}-${var.namespace_id}", 0, 22), random_string.opensearch_random_id.result]) : "${var.cluster_id}-${var.namespace_id}-els"
}

resource "aws_elasticsearch_domain_policy" "els_domain_policy" {
  domain_name = aws_elasticsearch_domain.opensearch.domain_name

  access_policies = <<POLICIES
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "*"
        ]
      },
      "Action": [
        "es:*"
      ],
      "Resource": "${aws_elasticsearch_domain.opensearch.arn}/*"
    }
  ]
}
POLICIES

}

# AWS renamed elastic -> opensearch, also version change.  Use "OpenSearch_<major>.x"
resource "aws_elasticsearch_domain" "opensearch" {
  #depends_on = [aws_iam_service_linked_role.opensearch_iam_service_linked_role]
  depends_on            = [data.aws_iam_role.opensearch_iam_service_linked_role]
  domain_name           = var.els_name != null ? var.els_name : local.dynamic_domain_name
  elasticsearch_version = var.els_version

  cluster_config {
    instance_count           = var.els_node_count
    instance_type            = var.els_instance_type
    zone_awareness_enabled   = var.els_zone_awareness_enabled
    warm_enabled             = var.els_warm_enabled
    dedicated_master_enabled = var.els_dedicated_master_enabled
    dynamic "zone_awareness_config" {
      for_each = var.els_zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.els_az_count
      }
    }
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }
  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = var.els_master_user_name != null ? var.els_master_user_name : "${var.cluster_id}_${var.namespace_id}_admin"
      master_user_password = var.els_master_user_password
      # You can also use IAM role/user ARN
      # master_user_arn = var.es_master_user_arn
    }
  }
  ebs_options {
    ebs_enabled = var.els_ebs_enabled
    volume_size = var.els_volume_size
    volume_type = var.els_volume_type
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    subnet_ids         = var.els_zone_awareness_enabled ? slice(var.els_subnet_ids, 0, var.els_az_count) : [var.els_subnet_ids[0]]
    security_group_ids = [var.els_security_group_id]
  }

  lifecycle {
    ignore_changes = [vpc_options[0].subnet_ids]
  }

  tags = merge(
    {
      Name = var.els_name != null ? var.els_name : local.dynamic_domain_name
    },
  )

}


data "terraform_remote_state" "primary_replicator" {
  count   = var.msk_secondary_replicator ? 1 : 0
  backend = "s3"
  config = {
    bucket  = var.remote_state_bucket
    region  = var.remote_state_region
    key     = var.remote_state_key
    encrypt = true
    profile = var.remote_state_profile
  }
}

locals {
  source_cluster_arn   = var.msk_secondary_replicator ? data.terraform_remote_state.primary_replicator[0].outputs.kafka-01_cluster_arn : null
  source_subnet_ids    = var.msk_secondary_replicator ? data.terraform_remote_state.primary_replicator[0].outputs.kafka-01_public_subnet_id : null
  source_sg_id         = var.msk_secondary_replicator ? data.terraform_remote_state.primary_replicator[0].outputs.kafka-01_source_sg_id : null
}

resource "aws_msk_replicator" "aws_msk_replicator_dr" {
  count                      = var.msk_replicator_enabled ? var.msk_secondary_replicator ? 1 : 0 : 0
  replicator_name            = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-msk-replicator"
  description                = "Creating MSK Replicator for asynchronous data replication in DR."
  service_execution_role_arn = var.msk_connect_iam_role_arn

  ## MSK Source Cluster configuration
  kafka_cluster {
    amazon_msk_cluster {
      msk_cluster_arn = local.source_cluster_arn
    }

    vpc_config {
      subnet_ids          = local.source_subnet_ids
      security_groups_ids = [local.source_sg_id]
    }
  }

  ## MSK Target Cluster configuration
  kafka_cluster {
    amazon_msk_cluster {
      msk_cluster_arn = aws_msk_cluster.aws_msk_cluster.arn
    }

    vpc_config {
      subnet_ids          = local.selected_subnet_ids
      security_groups_ids = [aws_security_group.msk_sg.id]
    }
  }

  replication_info_list {
    source_kafka_cluster_arn = local.source_cluster_arn
    target_kafka_cluster_arn = aws_msk_cluster.aws_msk_cluster.arn
    target_compression_type  = "NONE"


    topic_replication {
      topic_name_configuration {
        type = "IDENTICAL"
      }
      topics_to_replicate = [".*"]
      starting_position {
        type = "LATEST"
      }
    }

    consumer_group_replication {
      consumer_groups_to_replicate = [".*"]
    }
  }
}

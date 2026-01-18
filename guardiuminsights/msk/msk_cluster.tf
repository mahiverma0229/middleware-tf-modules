locals {
  selected_subnet_ids = slice(var.subnet_ids, 0, var.availability_zone_count)
  provisioned_throughput_enabled = try(tobool(var.msk_provisioned_throughput_enabled), null)
}

resource "aws_security_group" "msk_sg" {
  name        = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-msk-sg"
  description = "Security Group for msk cluster"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 9094
    to_port     = 9094
    cidr_blocks = var.msk_allowed_cidr_blocks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9194
    to_port     = 9194
    cidr_blocks = var.msk_allowed_cidr_blocks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9096
    to_port     = 9096
    cidr_blocks = var.msk_allowed_cidr_blocks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9196
    to_port     = 9196
    cidr_blocks = var.msk_allowed_cidr_blocks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9098
    to_port     = 9098
    cidr_blocks = var.msk_allowed_cidr_blocks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9198
    to_port     = 9198
    cidr_blocks = var.msk_allowed_cidr_blocks
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9096
    to_port     = 9096
    self        = true
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9098
    to_port     = 9098
    self        = true
  }

  ingress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"                       # -1 = all protocols
  cidr_blocks = var.msk_allowed_cidr_blocks
}

  # Un-Comment to enable traffic between Redshift and MSK
  # ingress {
  #   protocol    = "tcp"
  #   from_port   = 9098
  #   to_port     = 9098
  #   security_groups = [var.middleware_security_group_id]
  # }


  dynamic "ingress" {
    for_each = var.setup_phase == "initial" ? [1] : []
    content {
      protocol    = "tcp"
      from_port   = 1024
      to_port     = 65535
      cidr_blocks = [var.vpc_cidr]
    }
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol         = "tcp"
    from_port        = 14001
    to_port          = 14100
    cidr_blocks      = var.msk_allowed_cidr_blocks
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    protocol    = "tcp"
    from_port   = 9098
    to_port     = 9098
    self        = true
  }

}

resource "aws_cloudwatch_log_group" "msk_cloudwatch_log_group" {
  count             = var.cloudwatch_logs_enabled ? 1 : 0
  name              = "${var.cluster_id}-${var.namespace_id}-msk-cloudwatch-group"
  retention_in_days = var.cloudwatch_retention_in_days
}

# MSK configuration with "allow.everyone.if.no.acl.found" enabled.
resource "aws_msk_configuration" "aws_msk_cluster_config_allow_acl" {
  kafka_versions    = [var.kafka_version]
  name              = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-allow-acl-configuration"
  description       = "Manages an Amazon Managed Streaming for Kafka configuration"
  server_properties = join("\n", [for k in keys(var.public_properties) : format("%s = %s", k, var.public_properties[k])])
}

# MSK configuration with "allow.everyone.if.no.acl.found" disabled.

resource "aws_msk_configuration" "aws_msk_cluster_config_restricted_acl" {
  kafka_versions    = [var.kafka_version]
  name              = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-restricted-acl-configuration"
  description       = "Manages an Amazon Managed Streaming for Kafka configuration"
  server_properties = join("\n", [for k in keys(var.properties) : format("%s = %s", k, var.properties[k])])
}

# MSK configuration variable to choose the specific configuration, initially the cluster will be provisioned with "allow.everyone.if.no.acl.found" enabled
# and later on once the super user is created for the cluster, "allow.everyone.if.no.acl.found" should be disabled.
data "aws_msk_configuration" "aws_msk_cluster_config" {
  name = var.setup_phase == "initial" ? aws_msk_configuration.aws_msk_cluster_config_allow_acl.name : aws_msk_configuration.aws_msk_cluster_config_restricted_acl.name
}

resource "aws_msk_cluster" "aws_msk_cluster" {
  cluster_name           = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-msk"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = var.availability_zone_count * var.brokers_per_zone
  enhanced_monitoring    = var.enhanced_monitoring
  storage_mode           = var.kafka_express_broker_disabled ? var.storage_mode : null

  configuration_info {
    arn      = data.aws_msk_configuration.aws_msk_cluster_config.arn
    revision = 1
  }

  broker_node_group_info {
    client_subnets  = local.selected_subnet_ids
    instance_type   = var.broker_instance_type
    security_groups = [aws_security_group.msk_sg.id]

    dynamic "connectivity_info" {
      for_each = var.kafka_express_broker_disabled ? [1] : []
      content {
        public_access {
          type = var.setup_phase == "final" ? "SERVICE_PROVIDED_EIPS" : "DISABLED"
        }
      }
    }

    dynamic "storage_info" {
      for_each = var.kafka_express_broker_disabled ? [1] : []
      content {
        ebs_storage_info {
          volume_size = var.broker_volume_size
          dynamic "provisioned_throughput" {
            for_each = var.msk_provisioned_throughput_enabled != "" ? [1] : []
            content {
              enabled           = local.provisioned_throughput_enabled
              volume_throughput = null
            }
          }
        }
      }
    }
  }

  encryption_info {
    encryption_in_transit {
      client_broker = var.client_broker
      in_cluster    = var.encryption_in_cluster
    }
    encryption_at_rest_kms_key_arn = var.encryption_at_rest_kms_key_arn
  }

  dynamic "client_authentication" {
    for_each = [1]
    content {
      unauthenticated = var.setup_phase == "initial" ? true : false

      #Before associating the PCA to cluster we need to enable the MTLS. [This depends on parameters passed to the job in the second execution]
      #Associate the PCA to cluster  [This depends on parameters passed to the job in the second execution]
      dynamic "tls" {
        for_each = var.setup_phase == "initial" ? [] : [1]
        content {
          certificate_authority_arns = var.certificate_authority_arns
        }
      }

      dynamic "sasl" {
        for_each = var.setup_phase == "initial" ? [] : [1]
        content {
          iam   = var.enable_iam_client_authentication
          scram = var.enable_scram_client_authentication
        }
      }
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = var.jmx_exporter_enabled
      }
      node_exporter {
        enabled_in_broker = var.node_exporter_enabled
      }
    }
  }

  dynamic "logging_info" {
    for_each = var.kafka_express_broker_disabled ? [1] : []
    content {
      broker_logs {
        cloudwatch_logs {
          enabled   = var.cloudwatch_logs_enabled
          log_group = var.cloudwatch_logs_enabled ? aws_cloudwatch_log_group.msk_cloudwatch_log_group[0].name : null
        }
      }
    }
  }
}

# Associating secret to the cluster, with sasl enabled earlier
locals {
  msk_secrets_arns = var.gsp_peering_enabled ? [aws_secretsmanager_secret.kafka_secret_admin.arn, aws_secretsmanager_secret.kafka-secret-gsp[0].arn] : [aws_secretsmanager_secret.kafka_secret_admin.arn]

}
  
resource "aws_msk_scram_secret_association" "aws_msk_cluster_associate_secret" {
  count           = var.setup_phase == "final" ? 1 : 0
  cluster_arn     = aws_msk_cluster.aws_msk_cluster.arn
  secret_arn_list = [aws_secretsmanager_secret.kafka_secret_admin.arn]
  depends_on      = [aws_secretsmanager_secret_version.kafka_secret_admin, aws_secretsmanager_secret_version.kafka-secret-gsp[0]]
}

  # Import CA certificate

data "http" "aws_ca_certificates" {
  for_each = var.aws_ca_crt_names
  url = "https://www.amazontrust.com/repository/${each.key}.pem"
}

locals {
  aws_ca_certificates = zipmap(var.aws_ca_crt_names, [ for i in data.http.aws_ca_certificates : i.response_body ])
}


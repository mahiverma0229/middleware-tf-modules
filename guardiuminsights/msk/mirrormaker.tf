data "terraform_remote_state" "primary" {
  count   = var.msk_secondary ? 1 : 0
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
  primary_kafka_secret_admin_user         = var.msk_secondary ? data.terraform_remote_state.primary[0].outputs.kafka-01_superuser_name : null
  primary_kafka_secret_admin_password     = var.msk_secondary ? data.terraform_remote_state.primary[0].outputs.kafka-01_superuser_pass : null
  primary_kafka_bootstrap_servers_saslssl = var.msk_secondary ? data.terraform_remote_state.primary[0].outputs.kafka-01_bootstrap_servers_saslssl : null
  secondary_kafka_secret_admin_user       = var.msk_secondary ? jsondecode(data.aws_secretsmanager_secret_version.kafka_secrets.secret_string)["username"] : null
  secondary_kafka_secret_admin_password   = var.msk_secondary ? jsondecode(data.aws_secretsmanager_secret_version.kafka_secrets.secret_string)["password"] : null
}

resource "aws_s3_bucket" "mirrormaker_bucket" {
  count  = var.msk_secondary ? 1 : 0
  bucket = "${var.cluster_id}-${var.mirrormaker_bucket}-${var.identifier_id}"
}

resource "aws_s3_object" "mirrormaker_file" {
  count  = var.msk_secondary ? 1 : 0
  bucket = aws_s3_bucket.mirrormaker_bucket[0].id
  key    = "connect-mirror-2.7.0.jar"
  source = "msk/connect-mirror-2.7.0.jar"
}

resource "aws_mskconnect_custom_plugin" "mirrormaker_plugin" {
  count        = var.msk_secondary ? 1 : 0
  name         = var.mirrormaker_plugin != null ? var.mirrormaker_plugin : "${var.cluster_id}-mirrormaker-plugin"
  content_type = var.mirrormaker_file_type
  location {
    s3 {
      bucket_arn = aws_s3_bucket.mirrormaker_bucket[0].arn
      file_key   = aws_s3_object.mirrormaker_file[0].key
    }
  }
}

resource "aws_cloudwatch_log_group" "msk_connect_log_group" {
  count             = var.msk_secondary ? 1 : 0
  name              = "${var.cluster_id}-msk-connect-log-group"
  retention_in_days = var.cloudwatch_retention_in_days
}

resource "aws_mskconnect_connector" "connector_one" {
  count                = var.msk_secondary ? var.secondary_to_primary ? 0 : 1 : 0
  name                 = var.mirror_source_name != null ? var.mirror_source_name : "${var.cluster_id}-MirrorSourceConnector"
  kafkaconnect_version = var.kafkaconnect_version

  capacity {
    autoscaling {
      mcu_count        = "1"
      min_worker_count = "1"
      max_worker_count = "4"

      scale_in_policy {
        cpu_utilization_percentage = "20"
      }

      scale_out_policy {
        cpu_utilization_percentage = "40"
      }
    }
  }

  connector_configuration = {
    "connector.class"                       = "org.apache.kafka.connect.mirror.MirrorSourceConnector"
    "replication.factor"                    = "${tostring(var.availability_zone_count * var.brokers_per_zone)}"
    "target.cluster.sasl.jaas.config"       = "org.apache.kafka.common.security.scram.ScramLoginModule required username='${local.secondary_kafka_secret_admin_user}'  password='${local.secondary_kafka_secret_admin_password}';"
    "tasks.max"                             = "10"
    "sync.topic.acls.interval.seconds"      = "60"
    "source.cluster.alias"                  = ""
    "sync.topic.configs.interval.seconds"   = "60"
    "target.cluster.security.protocol"      = "SASL_SSL"
    "replication.policy.separator"          = ""
    "value.converter"                       = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "key.converter"                         = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "clusters"                              = "primary,backup"
    "refresh.groups.interval.seconds"       = "60"
    "refresh.topics.interval.seconds"       = "60"
    "offset-syncs.topic.replication.factor" = "${tostring(var.availability_zone_count * var.brokers_per_zone)}"
    "emit.checkpoints.enabled"              = "true"
    "consumer.group.id"                     = "mm2-msc-consumer-backup"
    "topics"                                = "[\\w\\W]*" #variable#
    "target.cluster.sasl.mechanism"         = "SCRAM-SHA-512"
    "producer.enable.idempotence"           = "true"
    "source.cluster.sasl.jaas.config"       = "org.apache.kafka.common.security.scram.ScramLoginModule required username='${local.primary_kafka_secret_admin_user}'  password='${local.primary_kafka_secret_admin_password}';"
    "source.cluster.bootstrap.servers"      = "${local.primary_kafka_bootstrap_servers_saslssl}"
    "source.cluster.sasl.mechanism"         = "SCRAM-SHA-512"
    "target.cluster.alias"                  = "backup"
    "target.cluster.bootstrap.servers"      = "${aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_scram}"
    "source.cluster.security.protocol"      = "SASL_SSL"
    #"topics.exclude"                        = "${var.msk_connector_excluded_topics}"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [aws_security_group.msk_sg.id]
        subnets         = local.selected_subnet_ids
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.mirrormaker_plugin[0].arn
      revision = aws_mskconnect_custom_plugin.mirrormaker_plugin[0].latest_revision
    }

  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_connect_log_group[0].name
      }
    }
  }

  service_execution_role_arn = var.msk_connect_iam_role_arn
  timeouts {
    create = "30m"
  }
}

resource "aws_mskconnect_connector" "connector_two" {
  count                = var.msk_secondary ? var.secondary_to_primary ? 0 : 1 : 0
  name                 = var.mirror_checkpoint_name != null ? var.mirror_checkpoint_name : "${var.cluster_id}-MirrorCheckpointConnector"
  kafkaconnect_version = var.kafkaconnect_version

  capacity {
    autoscaling {
      mcu_count        = "1"
      min_worker_count = "1"
      max_worker_count = "4"

      scale_in_policy {
        cpu_utilization_percentage = "20"
      }

      scale_out_policy {
        cpu_utilization_percentage = "40"
      }
    }
  }

  connector_configuration = {
    "connector.class"                      = "org.apache.kafka.connect.mirror.MirrorCheckpointConnector"
    "replication.factor"                   = "${tostring(var.availability_zone_count * var.brokers_per_zone)}"
    "target.cluster.sasl.jaas.config"      = "org.apache.kafka.common.security.scram.ScramLoginModule required username='${local.secondary_kafka_secret_admin_user}'  password='${local.secondary_kafka_secret_admin_password}';"
    "emit.checkpoints.enabled"             = "true"
    "tasks.max"                            = "10"
    "target.cluster.sasl.mechanism"        = "SCRAM-SHA-512"
    "source.cluster.alias"                 = ""
    "source.cluster.sasl.jaas.config"      = "org.apache.kafka.common.security.scram.ScramLoginModule required username='${local.primary_kafka_secret_admin_user}'  password='${local.primary_kafka_secret_admin_password}';"
    "source.cluster.bootstrap.servers"     = "${local.primary_kafka_bootstrap_servers_saslssl}"
    "source.cluster.sasl.mechanism"        = "SCRAM-SHA-512"
    "target.cluster.alias"                 = ""
    "target.cluster.security.protocol"     = "SASL_SSL"
    "replication.policy.separator"         = ""
    "target.cluster.bootstrap.servers"     = "${aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_scram}"
    "value.converter"                      = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "checkpoints.topic.replication.factor" = "${tostring(var.availability_zone_count * var.brokers_per_zone)}"
    "key.converter"                        = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "clusters"                             = ""
    "source.cluster.security.protocol"     = "SASL_SSL"
    "sync.group.offsets.enabled"           = "true"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [aws_security_group.msk_sg.id]
        subnets         = local.selected_subnet_ids
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.mirrormaker_plugin[0].arn
      revision = aws_mskconnect_custom_plugin.mirrormaker_plugin[0].latest_revision
    }

  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_connect_log_group[0].name
      }
    }
  }

  service_execution_role_arn = var.msk_connect_iam_role_arn

  timeouts {
    create = "30m"
  }
}

resource "aws_mskconnect_connector" "connector_three" {
  count                = var.msk_secondary ? var.secondary_to_primary ? 1 : 0 : 0
  name                 = var.mirror_source_name != null ? var.mirror_source_name : "${var.cluster_id}-MirrorSourceConnector"
  kafkaconnect_version = var.kafkaconnect_version

  capacity {
    autoscaling {
      mcu_count        = "1"
      min_worker_count = "1"
      max_worker_count = "4"

      scale_in_policy {
        cpu_utilization_percentage = "20"
      }

      scale_out_policy {
        cpu_utilization_percentage = "40"
      }
    }
  }

  connector_configuration = {
    "connector.class"                       = "org.apache.kafka.connect.mirror.MirrorSourceConnector"
    "replication.factor"                    = "${tostring(var.availability_zone_count * var.brokers_per_zone)}"
    "target.cluster.sasl.jaas.config"       = "org.apache.kafka.common.security.scram.ScramLoginModule required username='${local.secondary_kafka_secret_admin_user}'  password='${local.secondary_kafka_secret_admin_password}';"
    "tasks.max"                             = "10"
    "sync.topic.acls.interval.seconds"      = "60"
    "source.cluster.alias"                  = ""
    "sync.topic.configs.interval.seconds"   = "60"
    "target.cluster.security.protocol"      = "SASL_SSL"
    "replication.policy.separator"          = ""
    "value.converter"                       = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "key.converter"                         = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "clusters"                              = ""
    "refresh.groups.interval.seconds"       = "60"
    "refresh.topics.interval.seconds"       = "60"
    "offset-syncs.topic.replication.factor" = "${tostring(var.availability_zone_count * var.brokers_per_zone)}"
    "emit.checkpoints.enabled"              = "true"
    "topics"                                = "[\\w\\W]*"
    "target.cluster.sasl.mechanism"         = "SCRAM-SHA-512"
    "producer.enable.idempotence"           = "true"
    "source.cluster.sasl.jaas.config"       = "org.apache.kafka.common.security.scram.ScramLoginModule required username='${local.primary_kafka_secret_admin_user}'  password='${local.primary_kafka_secret_admin_password}';"
    "source.cluster.bootstrap.servers"      = "${local.primary_kafka_bootstrap_servers_saslssl}"
    "source.cluster.sasl.mechanism"         = "SCRAM-SHA-512"
    "target.cluster.alias"                  = ""
    "target.cluster.bootstrap.servers"      = "${aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_scram}"
    "source.cluster.security.protocol"      = "SASL_SSL"
    #"topics.exclude"                        = "${var.msk_connector_excluded_topics}"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [aws_security_group.msk_sg.id]
        subnets         = local.selected_subnet_ids
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.mirrormaker_plugin[0].arn
      revision = aws_mskconnect_custom_plugin.mirrormaker_plugin[0].latest_revision
    }

  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_connect_log_group[0].name
      }
    }
  }

  service_execution_role_arn = var.msk_connect_iam_role_arn

  timeouts {
    create = "30m"
  }
}

resource "aws_mskconnect_connector" "connector_four" {
  count                = var.msk_secondary ? var.secondary_to_primary ? 1 : 0 : 0
  name                 = var.mirror_checkpoint_name != null ? var.mirror_checkpoint_name : "${var.cluster_id}-MirrorCheckpointConnector"
  kafkaconnect_version = var.kafkaconnect_version

  capacity {
    autoscaling {
      mcu_count        = "1"
      min_worker_count = "1"
      max_worker_count = "4"

      scale_in_policy {
        cpu_utilization_percentage = "20"
      }

      scale_out_policy {
        cpu_utilization_percentage = "40"
      }
    }
  }

  connector_configuration = {
    "connector.class"                      = "org.apache.kafka.connect.mirror.MirrorCheckpointConnector"
    "replication.factor"                   = "${tostring(var.availability_zone_count * var.brokers_per_zone)}"
    "target.cluster.sasl.jaas.config"      = "org.apache.kafka.common.security.scram.ScramLoginModule required username='${local.secondary_kafka_secret_admin_user}'  password='${local.secondary_kafka_secret_admin_password}';"
    "emit.checkpoints.enabled"             = "true"
    "tasks.max"                            = "5"
    "target.cluster.sasl.mechanism"        = "SCRAM-SHA-512"
    "source.cluster.alias"                 = ""
    "source.cluster.sasl.jaas.config"      = "org.apache.kafka.common.security.scram.ScramLoginModule required username='${local.primary_kafka_secret_admin_user}'  password='${local.primary_kafka_secret_admin_password}';"
    "source.cluster.bootstrap.servers"     = "${local.primary_kafka_bootstrap_servers_saslssl}"
    "source.cluster.sasl.mechanism"        = "SCRAM-SHA-512"
    "target.cluster.alias"                 = ""
    "target.cluster.security.protocol"     = "SASL_SSL"
    "target.cluster.bootstrap.servers"     = "${aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_scram}"
    "value.converter"                      = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "checkpoints.topic.replication.factor" = "${tostring(var.availability_zone_count * var.brokers_per_zone)}"
    "key.converter"                        = "org.apache.kafka.connect.converters.ByteArrayConverter"
    "clusters"                             = ""
    "source.cluster.security.protocol"     = "SASL_SSL"
    "sync.group.offsets.enabled"           = "true"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers = aws_msk_cluster.aws_msk_cluster.bootstrap_brokers_sasl_iam

      vpc {
        security_groups = [aws_security_group.msk_sg.id]
        subnets         = local.selected_subnet_ids
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "IAM"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "TLS"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.mirrormaker_plugin[0].arn
      revision = aws_mskconnect_custom_plugin.mirrormaker_plugin[0].latest_revision
    }

  }

  log_delivery {
    worker_log_delivery {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_connect_log_group[0].name
      }
    }
  }

  service_execution_role_arn = var.msk_connect_iam_role_arn

  timeouts {
    create = "30m"
  }
}

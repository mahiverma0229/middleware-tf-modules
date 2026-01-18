data "terraform_remote_state" "primary" {
  count   = var.is_secondary_region ? 1 : 0
  backend = "s3"
  config = {
    bucket  = var.remote_state_bucket
    region  = var.remote_state_region
    key     = var.remote_state_key
    encrypt = true
    profile = var.remote_state_profile
  }
}

# outputs from the secondary region

data "terraform_remote_state" "secondary" {
  count   = var.redshift_enabled ? var.is_secondary_region ? 0 : 1 : 1
  backend = "s3"
  config = {
    bucket  = var.remote_state_bucket
    region  = var.remote_state_region
    key     = var.remote_state_key
    encrypt = true
    profile = var.remote_state_profile
  }
}

# AWS Secrets Manager
module "secrets_manager_kms" {
  source = "../common/kms"
  count  = var.push_secrets_to_sm ? 1 : 0

  # flags
  kms_replica = var.is_secondary_region

  # kms key configuration
  kms_key_policy          = templatefile("./kms/kms_key_policy.tftpl", { service = "secrets-manager-${var.cluster_id}", aws_account_id = "${var.aws_account_id}" })
  kms_key_waiting_period  = var.kms_key_waiting_period
  kms_enable_key_rotation = var.kms_enable_key_rotation
  kms_enable_multi_region = var.kms_enable_multi_region
  kms_key_alias           = "alias/secrets-manager-${var.cluster_id}"
  kms_primary_key_arn     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.secrets_manager_kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.secrets_manager_kms_key_arn : null : null
}

module "secrets-manager" {
  source = "../common/secrets-manager"
  count  = var.push_secrets_to_sm ? 1 : 0
  middleware_secrets_manager_name = var.middleware_secrets_manager_name
  sm_encryption_at_rest_kms_key_arn = module.secrets_manager_kms[0].kms_key_arn 
  all_middleware_secrets = local.secrets_output

  depends_on = [
    module.vpc,
    module.fe-cloudfront,
    module.msk,
    module.postgres_aurora,
    module.redis,
    module.redshift,
    module.redshift_serverless,
  ]
}


# Amazon VPC
module "vpc" {
  source = "../common/vpc"

  # general
  cluster_id         = var.cluster_id
  namespace_id       = var.namespace_id
  aws_account_id     = var.aws_account_id
  aws_partition      = var.aws_partition
  aws_region         = var.aws_region
  name_prefix        = var.team
  old_subnets_toggle = var.old_subnets_toggle

  # vpc details
  vpc_cidr    = var.vpc_cidr
  vpc_newbits = var.vpc_newbits

  # security
  vpc_num_private_subnets = var.vpc_num_private_subnets
  vpc_num_public_subnets  = var.vpc_num_public_subnets
  public_ingress_nacls    = var.vpc_public_ingress_nacls
  private_ingress_nacls   = var.vpc_private_ingress_nacls

  # security group rules - defined in security_group_rules.tf
  security_group_rules = local.security_group_rules

  # vpc peering
  connect_cluster_vpc           = var.connect_cluster_vpc
  connect_cluster_vpc_peer_id   = var.connect_cluster_vpc_peer_id
  connect_cluster_vpc_peer_name = var.connect_cluster_vpc_peer_name

}

# AWS Transit Gateway
module "transitgateway" {
  source = "../common/transitgateway"
  count  = var.transit_gateway_enabled ? 1 : 0

  # general
  name_prefix        = var.team
  cluster_id         = var.cluster_id
  namespace_id       = var.namespace_id
  old_subnets_toggle = var.old_subnets_toggle
  aws_region         = var.aws_region

  # flags
  tgw_secondary         = var.tgw_secondary
  tgw_attach_middleware = var.tgw_attach_middleware

  # configuration
  amazon_side_asn                 = var.tgw_amazon_side_asn
  auto_accept_shared_attachments  = var.tgw_auto_accept_shared_attachments
  default_route_table_association = var.tgw_default_route_table_association
  default_route_table_propagation = var.tgw_default_route_table_propagation
  dns_support                     = var.tgw_dns_support
  vpn_ecmp_support                = var.tgw_vpn_ecmp_support

  # tgw attachments
  vpc_id                     = module.vpc.vpc
  subnet_ids                 = module.vpc.private_subnet
  connect_cluster_tga_vpc_id = var.connect_cluster_tga_vpc_id
  connect_cluster_env_name   = var.connect_cluster_env_name

  # tgw route tables
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation
  selected_cluster_vpc_num_private_subnets        = sum([var.cluster_vpc_num_private_subnets, var.sos_vpc_num_private_subnets])

  # tgw peering
  tgw_peering_attachment_enabled = var.tgw_peering_attachment_enabled
  tga_peer_transit_gateway_id    = var.tga_peer_transit_gateway_id
  tga_peering_attachment_region  = var.tga_peering_attachment_region
  tgw_peer_attachment_rtb_id     = var.tgw_peer_attachment_rtb_id

  depends_on = [
    module.vpc,
  ]
}

# Amazon Aurora PostgreSQL
module "postgres_aurora_kms" {
  source = "../common/kms"
  count  = var.postgres_03_aurora_encryption_enabled ? 1 : 0

  # flags
  kms_replica = var.is_secondary_region

  # kms key configuration
  kms_key_policy          = templatefile("./kms/kms_key_policy.tftpl", { service = "postgres-aurora-${var.cluster_id}", aws_account_id = "${var.aws_account_id}" })
  kms_key_waiting_period  = var.kms_key_waiting_period
  kms_enable_key_rotation = var.kms_enable_key_rotation
  kms_enable_multi_region = var.kms_enable_multi_region
  kms_key_alias           = "alias/postgres-aurora-${var.cluster_id}"
  kms_primary_key_arn     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.postgres-03_aurora_kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.postgres-03_aurora_kms_key_arn : null : null
}

module "postgres_aurora" {
  source = "../common/aurora-postgresql/"
  count  = var.postgres_03_aurora_enabled ? 1 : 0
  # general
  cluster_id    = var.cluster_id
  namespace_id  = var.namespace_id
  identifier_id = var.identifier_id

  # flags
  primary                           = var.postgres_03_primary
  replica                           = var.postgres_03_replica
  aurora_remove_from_global_cluster = var.postgres_03_aurora_remove_from_global_cluster

  # db cluster details
  postgres_name     = var.postgres_03_name
  global_cluster_id = var.postgres_03_aurora_global_cluster_id
  db_name           = var.postgres_03_db_name
  pg_instance_count = var.postgres_03_instance_count
  pg_instance_class = var.postgres_03_instance_class
  pg_version        = var.postgres_03_version
  primary_username  = var.postgres_03_username
  primary_password  = var.postgres_03_password
  parameters        = var.postgres_03_parameters

  # network and security
  aurora_security_group_id = module.vpc.all_middleware_sg
  db_group_subnets         = module.vpc.private_subnet
  aurora_storage_encrypted = var.postgres_03_aurora_encryption_enabled
  aurora_kms_key_arn       = module.postgres_aurora_kms[0].kms_key_arn

  # maintenance, backup and restore
  aurora_backup_retention_period    = var.postgres_03_backup_retention_period
  aurora_preferred_backup_window    = var.postgres_03_aurora_backup_window
  aurora_snapshot_identifier        = var.postgres_03_aurora_snapshot_identifier
  aurora_skip_final_snapshot        = var.postgres_03_aurora_skip_final_snapshot
  aurora_apply_immediately          = var.postgres_03_aurora_apply_immediately
  aurora_instance_apply_immediately = var.postgres_03_aurora_instance_apply_immediately
  aurora_auto_minor_version_upgrade = var.postgres_03_aurora_auto_minor_version_upgrade

  # Auto-scaling 
  pg_autoscaling_enabled = var.postgres_03_autoscaling_enabled
  pg_schedule_scaling_enabled = var.postgres_03_schedule_scaling_enabled
  pg_dynamic_scaling_enabled = var.postgres_03_dynamic_scaling_enabled
  
  # remote state
  remote_state_bucket  = var.remote_state_bucket
  remote_state_region  = var.remote_state_region
  remote_state_key     = var.remote_state_key
  remote_state_profile = var.remote_state_profile

  depends_on = [
    module.postgres_aurora_kms[0],
  ]
}

# The randomly generated password value used by the risk-service to generate the admin password to be later consumed by the service.
resource "random_password" "pg_replica_password" {
  count = var.is_secondary_region ? 0 : 1

  length  = 12
  special = false
}

# Amazon ElastiCache Redis
module "redis_kms" {
  source = "../common/kms"
  count  = var.redis_encryption_enabled ? 1 : 0

  # flags
  kms_replica = var.is_secondary_region

  # kms key configuration
  kms_key_policy          = templatefile("./kms/kms_key_policy.tftpl", { service = "redis-${var.cluster_id}", aws_account_id = "${var.aws_account_id}" })
  kms_key_waiting_period  = var.kms_key_waiting_period
  kms_enable_key_rotation = var.kms_enable_key_rotation
  kms_enable_multi_region = var.kms_enable_multi_region
  kms_key_alias           = "alias/redis-${var.cluster_id}"
  kms_primary_key_arn     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.redis-01_kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.redis-01_kms_key_arn : null : null
}

resource "aws_cloudwatch_log_group" "redis" {
  count = var.redis_enabled ? contains(["4.0.10", "5.0.6"], var.redis_version) ? 0 : var.redis_version == "6.0" ? 1 : 2 : 0
  name  = count.index == 0 ? "${var.cluster_id}-${var.namespace_id}-redis/slow-logs" : "${var.cluster_id}-${var.namespace_id}-redis/engine-logs"
  retention_in_days = var.cloudwatch_retention_in_days
}

module "redis" {
  source = "../common/redis_multiregion"
  count  = var.redis_enabled ? 1 : 0

  # general
  cluster_id   = var.cluster_id
  namespace_id = var.namespace_id

  # flags
  primary = var.redis_primary
  replica = var.redis_replica

  # cluster details
  redis_name               = var.redis_name
  redis_description        = var.redis_description != null ? var.redis_description : "${var.cluster_id}-${var.namespace_id}-redis"
  redis_password           = var.redis_password
  redis_version            = var.redis_version
  redis_engine             = var.redis_engine
  redis_num_cache_clusters = var.redis_num_cache_clusters
  redis_node_type          = var.redis_node_type
  redis_multi_az_enabled   = var.redis_multi_az_enabled

  # network and security
  redis_security_group_id          = module.vpc.all_middleware_sg
  redis_subnet_ids                 = module.vpc.private_subnet
  redis_at_rest_encryption_enabled = var.redis_encryption_enabled
  redis_kms_key_arn                = module.redis_kms[0].kms_key_arn
  redis_parameter_group_name       = var.redis_snapshot_name != null ? var.redis_version == "4.0.10" ? "default.redis4.0" : var.redis_version == "5.0.6" ? "default.redis5.0" : contains(["6.0", "6.2"], var.redis_version) ? "default.redis6.x" : var.redis_version == "7.0" ? "default.redis7" : var.redis_version == "7.2" ? "default.valkey7" : var.redis_version == "8" ? "default.valkey8"  : null : null

  # maintenance, backup and restore
  redis_backup_window           = var.redis_backup_window
  redis_backup_retention_period = var.redis_backup_retention_period
  redis_snapshot_name           = var.redis_snapshot_name
  redis_apply_immediately       = var.redis_apply_immediately

  # log delivery
  redis_log_delivery_configuration = contains(["4.0.10", "5.0.6"], var.redis_version) ? {} : var.redis_version == "6.0" ? {
    "redis_slow_log_delivery" = {
      destination      = aws_cloudwatch_log_group.redis[0].name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    }
    } : {
    "redis_slow_log_delivery" = {
      destination      = aws_cloudwatch_log_group.redis[0].name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "slow-log"
    }
    "redis_engine_log_delivery" = {
      destination      = aws_cloudwatch_log_group.redis[1].name
      destination_type = "cloudwatch-logs"
      log_format       = "json"
      log_type         = "engine-log"
    }
  }

  # remote state
  remote_state_bucket  = var.remote_state_bucket
  remote_state_region  = var.remote_state_region
  remote_state_key     = var.remote_state_key
  remote_state_profile = var.remote_state_profile

  depends_on = [
    module.redis_kms[0],
  ]
}

module "lambda_redis_failover" {
  count  = var.redis_enabled ? var.redis_replica ? 1 : 0 : 0
  source = "../common/lambda/"

  lambda_runtime               = "python3.9"
  lambda_code_dir              = "redis_failover_lambda/code"
  lambda_layer_dir             = "redis_failover_lambda/layer"
  lambda_layer_name            = "boto3"
  lambda_name                  = "redis-failover-${var.cluster_id}-${var.namespace_id}-${var.identifier_id}"
  lambda_role                  = var.redis_failover_lambda_role
  lambda_subnet_ids            = module.vpc.private_subnet
  lambda_sg_ids                = [module.vpc.all_middleware_sg]
  lambda_environment_variables = { "cluster_name" = "${var.cluster_id}" }
  lambda_timeout               = 600

  depends_on = [
    module.redis[0],
  ]
}

resource "aws_lambda_invocation" "run_redis_failover" {
  count = var.redis_enabled ? var.redis_replica ? var.redis_remove_from_global_datastore ? 1 : 0 : 0 : 0

  function_name = module.lambda_redis_failover[0].lambda_function_name
  input         = <<JSON
  {
    "global_replication_group_id": "${module.redis[0].global_group_id}",
    "replication_group_id": "${module.redis[0].replication_group_id}",
    "replication_group_region": "${var.aws_region}"
  }
  JSON

  depends_on = [
    module.redis[0],
    module.lambda_redis_failover[0],
  ]
}

# Amazon DocumentDB
module "docdb_kms" {
  source = "../common/kms"
  count  = var.docdb_encryption_enabled ? 1 : 0

  # flags
  kms_replica = var.is_secondary_region

  # kms key configuration
  kms_key_policy          = templatefile("./kms/kms_key_policy.tftpl", { service = "docdb-${var.cluster_id}", aws_account_id = "${var.aws_account_id}" })
  kms_key_waiting_period  = var.kms_key_waiting_period
  kms_enable_key_rotation = var.kms_enable_key_rotation
  kms_enable_multi_region = var.kms_enable_multi_region
  kms_key_alias           = "alias/docdb-${var.cluster_id}"
  kms_primary_key_arn     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.mongodb-01_kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.mongodb-01_kms_key_arn : null : null
}

module "docdb" {
  source = "../common/docdb"
  count  = var.docdb_enabled ? 1 : 0

  # general
  cluster_id    = var.cluster_id
  namespace_id  = var.namespace_id
  identifier_id = var.identifier_id

  # flags
  docdb_primary                    = var.docdb_primary
  docdb_secondary                  = var.docdb_secondary
  docdb_remove_from_global_cluster = var.docdb_remove_from_global_cluster

  # cluster details
  docdb_global_cluster_id  = var.docdb_global_cluster_id
  docdb_name               = var.docdb_name
  docdb_username           = var.docdb_username
  docdb_password           = var.docdb_password
  docdb_instance_count     = var.docdb_instance_count
  docdb_instance_class     = var.docdb_instance_class
  docdb_cluster_parameters = var.docdb_cluster_parameters

  # network and security
  docdb_security_group_id  = module.vpc.all_middleware_sg
  docdb_subnet_ids         = module.vpc.private_subnet
  docdb_encryption_enabled = var.docdb_encryption_enabled
  docdb_kms_key_arn        = module.docdb_kms[0].kms_key_arn

  # maintenance, backup and restore
  docdb_backup_retention_period    = var.docdb_backup_retention_period
  docdb_backup_window              = var.docdb_backup_window
  docdb_skip_final_snapshot        = var.docdb_skip_final_snapshot
  docdb_snapshot_identifier        = var.docdb_snapshot_identifier
  docdb_apply_immediately          = var.docdb_apply_immediately
  docdb_instance_apply_immediately = var.docdb_instance_apply_immediately

  # remote state
  remote_state_bucket  = var.remote_state_bucket
  remote_state_region  = var.remote_state_region
  remote_state_key     = var.remote_state_key
  remote_state_profile = var.remote_state_profile

  depends_on = [
    module.docdb_kms[0],
  ]
}

module "lambda_docdbconf" {
  count  = var.docdb_enabled ? var.docdb_secondary ? 0 : 1 : 0
  source = "../common/lambda/"

  lambda_runtime               = "python3.9"
  lambda_code_dir              = "docdbconf_lambda/code"
  lambda_layer_dir             = "docdbconf_lambda/layer"
  lambda_layer_name            = "pymongo"
  lambda_name                  = "docdb-conf-${var.cluster_id}-${var.namespace_id}-${var.identifier_id}"
  lambda_role                  = var.docdb_lambda_role
  lambda_subnet_ids            = module.vpc.private_subnet
  lambda_sg_ids                = [module.vpc.all_middleware_sg]
  lambda_environment_variables = { "cluster_name" = "${var.cluster_id}" }
}

resource "aws_lambda_invocation" "run_docdbconf" {
  count = var.docdb_enabled ? var.docdb_secondary ? 0 : 1 : 0

  function_name = module.lambda_docdbconf[0].lambda_function_name
  input         = <<JSON
  {
    "docdb_credentials": {
      "user": "${module.docdb[0].username}",
      "password": "${module.docdb[0].password}",
      "host": "${module.docdb[0].endpoint}",
      "port": "${module.docdb[0].port}"
    },
    "action": "createUser",
    "users": [
      {
        "user": "root",
        "pwd": "${var.docdb_root_password}",
        "roles": [
          {"role": "clusterAdmin" , "db": "admin"},
          {"role": "userAdminAnyDatabase" , "db": "admin"},
          {"role": "readWriteAnyDatabase" , "db": "admin"},
          {"role": "backup" , "db": "admin"}
        ]
      },
      {
        "user": "metadata",
        "pwd": "${var.docdb_metadata_password}",
        "roles":[{"role": "dbOwner" , "db": "tnt_mbr_meta"}]
      }
    ]
  }
  JSON

  depends_on = [
    module.docdb[0],
    module.lambda_docdbconf[0],
  ]
}

# Amazon MSK
module "msk_kms" {
  source = "../common/kms"
  count  = var.msk_encryption_enabled ? 1 : 0

  # flags
  kms_replica = var.is_secondary_region

  # kms key configuration
  kms_key_policy          = templatefile("./kms/kms_key_policy.tftpl", { service = "msk-${var.cluster_id}", aws_account_id = "${var.aws_account_id}" })
  kms_key_waiting_period  = var.kms_key_waiting_period
  kms_enable_key_rotation = var.kms_enable_key_rotation
  kms_enable_multi_region = var.kms_enable_multi_region
  kms_key_alias           = "alias/msk-${var.cluster_id}"
  kms_primary_key_arn     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.kafka-01_kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.kafka-01_kms_key_arn : null : null
}

module "msk" {
  source = "./msk"
  count  = var.msk_enabled ? 1 : 0

  # general
  cluster_id     = var.cluster_id
  namespace_id   = var.namespace_id
  identifier_id  = var.identifier_id
  gsp_cluster_id = var.gsp_cluster_id

  # express broker related parameter 
  kafka_express_broker_disabled = var.msk_express_broker_disabled
  
  # flags
  msk_secondary        = var.msk_secondary
  secondary_to_primary = var.msk_secondary_to_primary
  gsp_peering_enabled  = var.gsp_peering_enabled
  setup_phase          = var.msk_setup_phase

  # properties
  kafka_version = var.msk_kafka_version

  # network settings
  vpc_id                  = module.vpc.vpc
  vpc_cidr                = var.vpc_cidr
  subnet_ids              = module.vpc.public_subnet
  availability_zone_count = var.msk_availability_zone_count
  msk_allowed_cidr_blocks = var.msk_allowed_cidr_blocks
  middleware_security_group_id = module.vpc.all_middleware_sg

  # brokers
  broker_instance_type = var.msk_broker_instance_type
  brokers_per_zone     = var.msk_brokers_per_zone

  # storage
  broker_volume_size                 = var.msk_broker_volume_size
  storage_mode                       = var.msk_storage_mode
  msk_provisioned_throughput_enabled = var.msk_provisioned_throughput_enabled

  # security settings
  encryption_in_cluster          = var.msk_encryption_enabled
  encryption_at_rest_kms_key_arn = module.msk_kms[0].kms_key_arn
  certificate_authority_arns     = var.msk_certificate_authority_arns

  # mirrormaker
  mirrormaker_plugin            = var.msk_mirrormaker_plugin_name
  mirror_source_name            = var.msk_mirror_source_name
  mirror_checkpoint_name        = var.msk_mirror_checkpoint_name
  msk_connector_excluded_topics = var.msk_connector_excluded_topics
  msk_connect_iam_role_arn      = var.msk_connect_iam_role_arn

  # MSK Replicator
  msk_replicator_enabled        = var.msk_replicator_enabled
  msk_secondary_replicator      = var.msk_secondary_replicator
  
  # remote state
  remote_state_bucket  = var.remote_state_bucket
  remote_state_region  = var.remote_state_region
  remote_state_key     = var.remote_state_key
  remote_state_profile = var.remote_state_profile

  depends_on = [
    module.msk_kms[0],
  ]
}

module "lambda_msk_conf" {
  count  = var.msk_enabled ? var.msk_setup_phase == "initial" ? 1 : 0 : 0
  source = "../common/lambda/"

  lambda_runtime               = "python3.9"
  lambda_code_dir              = "msk/msk_conf_lambda/code"
  lambda_layer_dir             = "msk/msk_conf_lambda/layer"
  lambda_layer_name            = "kafka-python"
  lambda_name                  = "msk-conf-${var.cluster_id}-${var.namespace_id}-${var.identifier_id}"
  lambda_role                  = var.msk_lambda_role_arn
  lambda_subnet_ids            = module.vpc.public_subnet
  lambda_sg_ids                = [module.msk[0].msk_sg]
  lambda_environment_variables = { "cluster_name" = "${var.cluster_id}" }

  depends_on = [
    module.msk[0],
  ]
}

resource "aws_lambda_invocation" "run_msk_conf" {
  count         = var.msk_enabled ? var.msk_setup_phase == "initial" ? 1 : 0 : 0
  function_name = module.lambda_msk_conf[0].lambda_function_name

  input = jsonencode({
    bootstrap_servers = module.msk[0].bootstrap_brokers_private_tls
  })

  depends_on = [
    module.msk[0],
    module.lambda_msk_conf[0],
  ]
}

# Random jks-passwords for mongodb and kafka
resource "random_password" "jks-password" {
  count = var.is_secondary_region ? 1 : 2

  length  = 12
  special = false
}

/*
Note: The below Terraform modules are no longer used by Guardium Insights
TODO: to be removed later

# Amazon S3
module "s3" {
  source = "../common/s3"
  count  = var.s3_enabled ? 1 : 0

  # general
  cluster_id   = var.cluster_id
  namespace_id = var.namespace_id

  # bucket details
  s3_bucket_name = var.s3_bucket_name
}

# Amazon Elastic File System
module "efs" {
  source = "../common/efs"
  count  = var.efs_enabled ? 1 : 0

  # general
  cluster_id    = var.cluster_id
  namespace_id  = var.namespace_id
  identifier_id = var.identifier_id

  # efs details
  efs_name = var.efs_name

  # network
  vpc_id        = module.vpc.vpc
  efs_subnet_id = module.vpc.private_subnet
}

# SOS Audit Logging Agent
module "sos_audit_logging" {
  source = "../common/sos-audit-logging"
  count  = var.sos_audit_logging_enabled ? 1 : 0

  cluster_id = var.cluster_id
  aws_region = var.aws_region

  kube_config_file                     = var.kube_config_file
  cluster_logging_subscription_channel = var.cluster_logging_subscription_channel
  syslog_forwarder_app_name            = var.syslog_forwarder_app_name
  syslog_forwarder_service_port        = var.syslog_forwarder_service_port
  syslog_forwarder_service_target_port = var.syslog_forwarder_service_target_port
  syslog_forwarder_replica_count       = var.syslog_forwarder_replica_count
}
*/

#### GI to DSPM vpc peering 

module "gsp_vpc_peering" {
  count  = var.gsp_cluster_vpc_enabled ? 1 : 0
  source = "./gsp_vpc_peering"

  # general
  cluster_id         = var.cluster_id
  namespace_id       = var.namespace_id
  aws_account_id     = var.aws_account_id
  aws_partition      = var.aws_partition
  aws_region         = var.aws_region
  name_prefix        = var.team
  old_subnets_toggle = var.old_subnets_toggle

  # vpc details
  vpc_cidr                = var.vpc_cidr
  vpc_newbits             = var.vpc_newbits
  middleware_vpc_id       = module.vpc.vpc
  private_route_table_ids = module.vpc.private_route_table_ids
  public_route_table_ids  = module.vpc.public_route_table_ids
  middleware_vpc_cidr     = module.vpc.cidr_block

  # security
  vpc_num_private_subnets = var.vpc_num_private_subnets
  vpc_num_public_subnets  = var.vpc_num_public_subnets

  # vpc peering
  gsp_cluster_vpc_enabled = var.gsp_cluster_vpc_enabled
  gsp_cluster_vpc_id      = var.gsp_cluster_vpc_id
  gsp_cluster_vpc_name    = var.gsp_cluster_vpc_name
}

# Transitgateway attachment with DSPM VPCs
module "gsp_tgw_peering" {
  count  = var.gsp_tgw_enabled ? 1 : 0
  source = "./gsp_tgw_peering"

  # general
  name_prefix        = var.team
  cluster_id         = var.cluster_id
  namespace_id       = var.namespace_id
  old_subnets_toggle = var.old_subnets_toggle
  aws_region         = var.aws_region

  # flags
  tgw_secondary         = var.tgw_secondary
  tgw_attach_middleware = var.tgw_attach_middleware
  transit_gateway_id    = one(module.transitgateway[*].transit_gateway_id)

  # configuration
  amazon_side_asn                 = var.tgw_amazon_side_asn
  auto_accept_shared_attachments  = var.tgw_auto_accept_shared_attachments
  default_route_table_association = var.tgw_default_route_table_association
  default_route_table_propagation = var.tgw_default_route_table_propagation
  dns_support                     = var.tgw_dns_support
  vpn_ecmp_support                = var.tgw_vpn_ecmp_support

  # tgw attachments
  vpc_id                         = module.vpc.vpc
  subnet_ids                     = module.vpc.private_subnet
  gsp_cluster_vpc_id             = var.gsp_cluster_vpc_id
  gsp_cluster_vpc_name           = var.gsp_cluster_vpc_name
  transit_gateway_route_table_id = one(module.transitgateway[*].transit_gateway_route_table_id)
  middleware_vpc_cidr            = module.vpc.cidr_block

  # tgw route tables
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation
  selected_cluster_vpc_num_private_subnets        = sum([var.cluster_vpc_num_private_subnets, var.sos_vpc_num_private_subnets])
  private_route_table_ids                         = module.vpc.private_route_table_ids

  # tgw peering
  tgw_peering_attachment_enabled = var.tgw_peering_attachment_enabled
  tga_peer_transit_gateway_id    = var.tga_peer_transit_gateway_id
  tga_peering_attachment_region  = var.tga_peering_attachment_region
  tgw_peer_attachment_rtb_id     = var.tgw_peer_attachment_rtb_id
}


#### AWS Redshift cluster

module "redshift_kms" {

  source = "../common/kms"
  count  = var.redshift_enabled ? 1 : 0
  
  # flags
  kms_replica = var.is_secondary_region

  kms_key_alias           = "alias/redshift-${var.cluster_id}"
  kms_key_waiting_period  = var.kms_key_waiting_period
  kms_enable_key_rotation = var.kms_enable_key_rotation
  kms_enable_multi_region = var.kms_enable_multi_region
  kms_primary_key_arn     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.redshift-02_kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.redshift-02_kms_key_arn : null : null
}
module "redshift" {
  source = "../common/redshift"
  count  = var.redshift_enabled ? 1 : 0
  
  # general
  is_secondary_region        = var.is_secondary_region
  cluster_id                 = var.cluster_id
  namespace_id               = var.namespace_id
  aws_dr_region              = var.aws_dr_region
  redshift_enabled           = var.redshift_enabled
  redshift_subnet_ids        = module.vpc.private_subnet
  redshift_security_group_id = module.vpc.all_middleware_sg
  identifier_id              = var.identifier_id
  redshift_db_name           = var.redshift_db_name
  #redshift_availability_zone = var.redshift_availability_zone
  redshift_user_name         = var.redshift_user_name
  redshift_log_exports       = var.redshift_log_exports
  delete_redshift_cluster    = var.delete_redshift_cluster

  # cluster configuration
  redshift_multi_az_enabled      = var.redshift_multi_az_enabled
  redshift_availability_zone_relocation_enabled = var.redshift_availability_zone_relocation_enabled
  redshift_node_type             = var.redshift_node_type
  redshift_cluster_type          = var.redshift_cluster_type
  redshift_version               = var.redshift_version
  redshift_multi_region_enabled  = var.redshift_multi_region_enabled
  redshift_allow_version_upgrade = var.redshift_allow_version_upgrade
  redshift_publicly_accessible   = var.redshift_publicly_accessible
  redshift_number_of_nodes       = var.redshift_number_of_nodes
  redshift_encryption_enabled    = var.redshift_encryption_enabled
  redshift_skip_final_snapshot   = var.redshift_skip_final_snapshot
  redshift_snapshot_destination  = var.redshift_snapshot_destination
  redshift_kms_key_arn           = module.redshift_kms[0].kms_key_arn
  snapshot_schedule_definitions  = var.redshift_snapshot_schedule_frequency
  redshift_snapshot_identifier   = var.redshift_snapshot_identifier
  # redshift_msk_iam_role          = var.redshift_msk_iam_role
  redshift_snapshot_copy_grant   = var.redshift_multi_region_enabled ? var.is_secondary_region ? data.terraform_remote_state.primary[0].outputs.redshift-02_snapshot_copy_grant : data.terraform_remote_state.secondary[0].outputs.redshift-02_snapshot_copy_grant : null 
  redshift_auto_snapshot_retention_period = var.redshift_auto_snapshot_retention_period
  redshift_manual_snapshot_retention_period = var.redshift_manual_snapshot_retention_period
  parameter_group_parameters = {
    #wlm_json_configuration = {
    #  name = "wlm_json_configuration"
    #  value = jsonencode([
    #    {
    #      query_concurrency = 15
    #    }
    #  ])
    #}
    require_ssl = {
      name  = "require_ssl"
      value = true
    }
    use_fips_ssl = {
      name  = "use_fips_ssl"
      value = true
    }
    enable_user_activity_logging = {
      name  = "enable_user_activity_logging"
      value = false
    }
    max_concurrency_scaling_clusters = {
      name  = "max_concurrency_scaling_clusters"
      value = 2
    }
    enable_case_sensitive_identifier = {
      name  = "enable_case_sensitive_identifier"
      value = true
    }
    auto_analyze = {
      name  = "auto_analyze"
      value = true
    }
    auto_mv = {
      name  = "auto_mv"
      value = true
    }
    datestyle = {
      name  = "datestyle"
      value = "ISO,MDY"
    }
    extra_float_digits = {
      name  = "extra_float_digits"
      value = 0
    }
    # max_cursor_result_set_size = {
    #   name = "max_cursor_result_set_size"
    #   value = default
    #}
    # query_group = {
    #   name = "query_group"
    #   value = default
    #}
    statement_timeout = {
      name  = "statement_timeout"
      value = 0
    }

  }
  depends_on = [module.redshift_kms]
}


module "fe-cloudfront" {
  count                  = var.cloudfront_enabled ? 1 : 0
  source                 = "../common/fe-cloudfront"
  dspm_env               = var.dspm_env
  zone_name              = var.zone_name
  dspm_fe_allowed_origin = var.dspm_fe_allowed_origin
}

module "route53" {
  count                  = var.cloudfront_enabled ? 1 : 0
  source                 = "../common/route53"
  middleware_vpc_id      = module.vpc.vpc
  cloudfront_domain_name = module.fe-cloudfront[0].cloudfront_domain_name
  zone_name              = var.zone_name

  depends_on = [module.fe-cloudfront]
}

# AWS Redshift serverless 
module "redshift_srvls_kms" {
  source = "../common/kms"
  count  = var.rss_enabled ? 1 : 0
  # flags
  kms_replica = var.is_secondary_region

  kms_key_waiting_period  = var.kms_key_waiting_period
  kms_enable_key_rotation = var.kms_enable_key_rotation
  kms_enable_multi_region = var.kms_enable_multi_region
  kms_primary_key_arn     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.redshift-srvls-01_kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.redshift-srvls-01_kms_key_arn : null : null
  kms_key_alias           = "alias/redshift-srvl-${var.cluster_id}"
}
module "redshift_serverless" {
  source = "../common/redshift-serverless"
  count  = var.rss_enabled ? 1 : 0
  # general

  cluster_id            = var.cluster_id
  namespace_id          = var.namespace_id
  rss_subnet_ids        = module.vpc.private_subnet
  rss_security_group_id = module.vpc.all_middleware_sg
  identifier_id         = 01 #var.identifier_id
  rss_enabled           = var.rss_enabled
  rss_external_db       = var.rss_external_db
  delete_rss_cluster    = var.delete_rss_cluster
  # rss namespace settings
  rss_namespace_name = var.rss_namespace_name
  rss_db_name        = var.rss_db_name
  rss_kms_key_arn    = module.redshift_srvls_kms[0].kms_key_arn
  rss_log_exports    = var.rss_log_exports
  rss_user_name      = var.rss_user_name
  # rss workgroup settings
  #rss_workgroup_name = var.rss_workgroup_name
  rss_base_capacity = var.rss_base_capacity
  rss_max_capacity  = var.rss_max_capacity
  rss_port          = var.rss_port
  #rss snapshot settings
  rss_snapshot_retention_period = var.rss_snapshot_retention_period
  rss_price_performance_target_enabled = var.rss_price_performance_target_enabled
  rss_price_performance_target_level = var.rss_price_performance_target_level
  rss_config_parameters = [
    {
      parameter_key   = "query_group"
      parameter_value = "default"
    },
    {
      parameter_key   = "max_query_execution_time"
      parameter_value = "14400"
    },
    {
      parameter_key   = "require_ssl"
      parameter_value = true
    },
    {
      parameter_key   = "use_fips_ssl"
      parameter_value = true
    },
    {
      parameter_key   = "enable_user_activity_logging"
      parameter_value = false
    },
    {
      parameter_key   = "enable_case_sensitive_identifier"
      parameter_value = true
    },
    {
      parameter_key   = "auto_mv"
      parameter_value = true
    },
    {
      parameter_key   = "datestyle"
      parameter_value = "ISO,MDY"
    }
  ]
  depends_on = [module.redshift_srvls_kms]
}

# # Redshift Lambda function to change PWD Auth mechanism
module "redshift-change-pwd-auth-mech" {
  count  = var.redshift_enabled ? 1 : 0
  source = "../common/lambda/"

  lambda_runtime               = "python3.9"
  lambda_code_dir              = "redshift-pwd-auth-mech/code"
  lambda_layer_dir             = "redshift-pwd-auth-mech/layer"
  lambda_layer_name            = "boto3"
  lambda_name                  = "redshift-change-password-auth${var.cluster_id}-${var.namespace_id}-${var.identifier_id}"
  lambda_role                  = var.redshift_lambda_role
  lambda_subnet_ids            = module.vpc.private_subnet
  lambda_sg_ids                = [module.vpc.all_middleware_sg]
  lambda_environment_variables = { "cluster_name" = "${var.cluster_id}" }
  lambda_timeout               = 600

  depends_on = [
    module.redshift[0],
    module.redshift_serverless[0]
  ]
}

resource "aws_lambda_invocation" "redshift_change_pwd_auth" {
  count = var.redshift_enabled ? var.delete_redshift_cluster ? 0 : 1 : 0
  function_name = module.redshift-change-pwd-auth-mech[0].lambda_function_name
  input = <<JSON
  {
    "producer_host": "${module.redshift[0].redshift_cluster_dns_name}",
    "producer_port": "${module.redshift[0].redshift_port}",
    "producer_user": "${module.redshift[0].redshift_user}",
    "producer_password": "${module.redshift[0].redshift_password}",
    "producer_database": "${module.redshift[0].redshift_db}",
    "producer_cluster_id": "${module.redshift[0].redshift_ClusterIdentifier}"
  }
    JSON
  depends_on = [
    module.redshift[0],
    module.redshift_serverless[0],
    module.redshift-change-pwd-auth-mech[0]
  ]
}

# Amazon EMR configurations


# EMR KMS for encryption
module "emr_kms" {
  source = "../common/kms"
  count  = var.emr_enabled && var.emr_encryption_enabled ? 1 : 0

  # kms key configuration
  kms_key_policy = templatefile("./kms/kms_key_policy.tftpl", { 
    service = "emr-${var.cluster_id}", 
    aws_account_id = "${var.aws_account_id}"
  })

  kms_replica = var.is_secondary_region
  kms_enable_multi_region = var.kms_enable_multi_region
  kms_key_waiting_period  = var.kms_key_waiting_period
  kms_enable_key_rotation = var.kms_enable_key_rotation
  kms_key_alias           = "alias/emr-${var.cluster_id}"
  kms_primary_key_arn = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.emr_kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.emr_kms_key_arn : null : null
}
# Local variables for EMR S3 bucket control
locals {
  # Determine if we should create a new bucket or use a specified one
  # Create bucket when:
  # 1. EMR is enabled (var.emr_enabled)
  # 2. No bucket name is provided (var.emr_bucket_name is null)
  emr_s3_create = var.emr_enabled && var.emr_bucket_name == null
  
  # Use specified bucket if name is provided
  emr_use_specified_bucket = var.emr_bucket_name != null
}

# EMR S3 bucket - Controlled via env.hcl
# If emr_bucket_name is provided, this module is skipped and specified bucket is used
module "emr_s3" {
  source = "../common/emr-s3"
  count  = local.emr_s3_create ? 1 : 0

  cluster_id              = var.cluster_id
  namespace_id            = var.namespace_id
  identifier_id           = var.identifier_id
  emr_tags                = var.emr_tags
  emr_encryption_enabled  = var.emr_encryption_enabled
  emr_kms_key_arn         = var.emr_encryption_enabled && length(module.emr_kms) > 0 ? module.emr_kms[0].kms_key_arn : ""
}

module "emr" {
  source = "../common/emr/"
  count  = var.emr_enabled ? 1 : 0
  
  depends_on = [module.emr_s3]

  cluster_id                            = var.cluster_id
  namespace_id                          = var.namespace_id
  identifier_id                         = var.identifier_id
  emr_release_label                     = var.emr_release_label
  
  emr_service_role                      = var.emr_service_role
  emr_instance_profile                  = var.emr_instance_profile
  emr_auto_termination_policy_timeout   = var.emr_auto_termination_policy_timeout
  vpc_id                                = module.vpc.vpc
  emr_subnet_ids                        = module.vpc.private_subnet
  emr_tgw_route_depends_on              = [
                                           module.transitgateway[0].transit_gateway_id,
                                           module.transitgateway[0].transit_gateway_route_table_id
                                          ]
  emr_termination_protection            = var.emr_termination_protection
  emr_keep_job_flow_alive_when_no_steps = var.emr_keep_job_flow_alive_when_no_steps
  emr_encryption_enabled                = var.emr_encryption_enabled
  emr_kms_key_arn                       = var.emr_encryption_enabled ? module.emr_kms[0].kms_key_arn : null
  
  # S3 bucket information - use specified bucket if provided, otherwise use created bucket
  emr_bucket_name                       = local.emr_use_specified_bucket ? var.emr_bucket_name : (local.emr_s3_create ? module.emr_s3[0].bucket_name : "")
  emr_bootstrap_scripts_location        = local.emr_use_specified_bucket ? "s3://${var.emr_bucket_name}/bootstrap/" : (local.emr_s3_create ? module.emr_s3[0].bootstrap_scripts_location : "")
  emr_warehouse_location                = local.emr_use_specified_bucket ? "s3://${var.emr_bucket_name}/iceberg-warehouse/" : (local.emr_s3_create ? module.emr_s3[0].warehouse_location : "")
  emr_logs_location                     = local.emr_use_specified_bucket ? "s3://${var.emr_bucket_name}/logs/" : (local.emr_s3_create ? module.emr_s3[0].logs_location : "")
}

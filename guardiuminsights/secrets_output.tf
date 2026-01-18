locals {
    secrets_output = {
AZ1 : join(",", [module.vpc.aws_availability_zones.names[0],module.vpc.aws_availability_zones.zone_ids[0]])
AZ2 : join(",", [module.vpc.aws_availability_zones.names[1], module.vpc.aws_availability_zones.zone_ids[1]])
AZ3 : join(",", [module.vpc.aws_availability_zones.names[2], module.vpc.aws_availability_zones.zone_ids[2]])
AZ_number_of_zones : var.vpc_num_private_subnets
cr_standby_instance : var.cr_standby_instance
middleware_vpc : module.vpc.vpc
middleware_vpc_cidr : module.vpc.cidr_block
cr_middleware_vpc_cidr : module.vpc.cidr_block
cr_monitor_vpc_cidr : "162.247.240.0/22"
secrets_manager_kms_key_arn : var.push_secrets_to_sm ? can(one(module.secrets_manager_kms[*].kms_key_arn)) ? one(module.secrets_manager_kms[*].kms_key_arn) : null : null
transit_gateway_id : one(module.transitgateway[*].transit_gateway_id)
cos-02_port : 443
redis-01_host : one(module.redis[*].primary_endpoint)
redis-01_username : var.redis_enabled ? "null" : null
redis-01_password : one(module.redis[*].auth_token)
redis-01_port : one(module.redis[*].port)
redis-01_global_group_id : var.redis_replica ? null : one(module.redis[*].global_group_id)
redis-01_kms_key_arn : var.is_secondary_region ? null : one(module.redis_kms[*].kms_key_arn)
postgres-03_port : var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].port) : null
postgres-03_host : var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].endpoint) : null
postgres-03_username : var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].username) : null
postgres-03_password : var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].password) : null
postgres-03_db : var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].postgres_db_name) : null
postgres-03_arn : var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].postgres_arn) : null
postgres-03_encrypt : var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].postgres_encrypt) : null
postgres-03_aurora_kms_key_arn : var.is_secondary_region ? null : one(module.postgres_aurora_kms[*].kms_key_arn)
postgres-03_aurora_global_cluster_id : one(module.postgres_aurora[*].postgres_aurora_global_cluster_id)
postgres-03_replica_password : var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.postgres-03_replica_password) ? data.terraform_remote_state.primary[0].outputs.postgres-03_replica_password : null : one(random_password.pg_replica_password[*].result)
mongodb-01_host : one(module.docdb[*].endpoint)
mongodb-01_global_cluster_id : one(module.docdb[*].docdb_global_cluster_id)
mongodb-01_kms_key_arn : var.is_secondary_region ? null : one(module.docdb_kms[*].kms_key_arn)
mongodb-01_port : one(module.docdb[*].port)
mongodb-01_username : one(module.docdb[*].username)
mongodb-01_password : one(module.docdb[*].password)
mongodb-01_admin_username : var.docdb_enabled ? "root" : null
mongodb-01_admin_password : var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.mongodb-01_admin_password) ? data.terraform_remote_state.primary[0].outputs.mongodb-01_admin_password : null : var.docdb_root_password
mongodb-01_meta_user : var.docdb_enabled ? "metadata" : null
mongodb-01_meta_user_secret : var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.mongodb-01_meta_user_secret) ? data.terraform_remote_state.primary[0].outputs.mongodb-01_meta_user_secret : null : var.docdb_metadata_password
mongodb-01_jks_password : var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.mongodb-01_jks_password) ? data.terraform_remote_state.primary[0].outputs.mongodb-01_jks_password : null : random_password.jks-password[1].result
kafka-01_superuser_name : one(module.msk[*].kafka_admin_user)
kafka-01_superuser_pass : one(module.msk[*].kafka_admin_password)
kafka-01_bootstrap_servers_saslssl : one(module.msk[*].bootstrap_brokers_sasl_scram)
kafka-01_bootstrap_servers_internal: one(module.msk[*].bootstrap_brokers_private_tls)
kafka-01_conf_message : length(module.msk) > 0 ? var.msk_setup_phase == "initial" ? one(resource.aws_lambda_invocation.run_msk_conf[*].result) : "{\"statusCode\": 200, \"body\": \"Done\"}" : "{\"statusCode\": 404, \"body\": \"Not Run\"}"
kafka-01_jks_password : var.msk_enabled ? random_password.jks-password[0].result : null
kafka-01_kms_key_arn : var.is_secondary_region ? null : one(module.msk_kms[*].kms_key_arn)
kafka-01_express_broker_enabled :  var.msk_enabled ? var.msk_express_broker_disabled ? "false" : "true" : null
kafka-01_source_sg_id : var.msk_enabled ? var.msk_replicator_enabled ? null : one(module.msk[*].msk_sg) : null
transit_gateway_route_table_id : one(module.transitgateway[*].transit_gateway_route_table_id)
redshift-02_port : var.redshift_enabled ? one(module.redshift[*].redshift_port) : null
redshift-02_host : var.redshift_enabled ? one(module.redshift[*].redshift_cluster_dns_name) : null
redshift-02_username : var.redshift_enabled ? one(module.redshift[*].redshift_user) : null
redshift-02_password : var.redshift_enabled ? one(module.redshift[*].redshift_password) : null
redshift-02_db : var.redshift_enabled ? one(module.redshift[*].redshift_db) : null
redshift-02_namespaceid : var.redshift_enabled ? format("'%s'", one(module.redshift[*].redshift_cluster_namespaceid)) : null
redshift-02_accountid : var.redshift_enabled ? format("'%s'", one(module.redshift[*].redshift_cluster_accountid)) : null
redshift-02_kms_key_arn : can(one(module.redshift_kms[*].kms_key_arn)) ? one(module.redshift_kms[*].kms_key_arn) : null
redshift-srvls-01_port : var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_port) : null
redshift-srvls-01_host : var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_endpoint) : null
redshift-srvls-01_username : var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_user) : null
redshift-srvls-01_password : var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_password) : null
redshift-srvls-01_db : var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_db) : null
redshift-srvls-01_namespaceid : var.rss_enabled ? format("'%s'", one(module.redshift_serverless[*].redshift_srvls_namespaceid)) : null
redshift-srvls-01_accountid : var.rss_enabled ? format("'%s'", one(module.redshift_serverless[*].redshift_srvls_accountid)) : null
redshift-srvls-01_externaldb : var.rss_enabled ? var.rss_external_db : null
redshift-srvls-01_kms_key_arn : var.is_secondary_region ? null : one(module.redshift_srvls_kms[*].kms_key_arn)
redshift-02_multiplehost : var.redshift_enabled ? jsonencode({
    "0" : {
      "primary_redshift_conn_creds" : {
        "HOSTNAME" : one(module.redshift[*].redshift_cluster_dns_name)
        "DATABASE_UID" : one(module.redshift[*].redshift_user)
        "DATABASE_NAME" : one(module.redshift[*].redshift_db)
        "DATABASE_PASSWORD" : one(module.redshift[*].redshift_password)
        "DATABASE_SSL_SERVER_CERT_PATH" : "/etc/pki/tls/certs/insights-redshift/ca.arm"
        "PORT" : tostring(one(module.redshift[*].redshift_port))
        "Type" : "Primary"
      },
      "variable_redshift_conn_creds_1" : {
        "HOSTNAME" : one(module.redshift[*].redshift_cluster_dns_name)
        "DATABASE_UID" : one(module.redshift[*].redshift_user)
        "DATABASE_NAME" : one(module.redshift[*].redshift_db)
        "DATABASE_PASSWORD" : one(module.redshift[*].redshift_password)
        "DATABASE_SSL_SERVER_CERT_PATH" : "/etc/pki/tls/certs/insights-redshift/ca.arm"
        "PORT" : tostring(one(module.redshift[*].redshift_port))
        "Type" : "Consumer"
      }
    }}) : null
redshift-02_snapshot_copy_grant : can(one(module.redshift[*].redshift_snapshot_copy_grant)) ? one(module.redshift[*].redshift_snapshot_copy_grant) : null
dspm_micro_frontend_assets_endpoint : var.cloudfront_enabled ? one(module.fe-cloudfront[*].cloudfront_domain_name) : null
dspm_micro_frontend_assets_tag : var.cloudfront_enabled ? "main" : null
redshift_change_pwd_auth_message : one(resource.aws_lambda_invocation.redshift_change_pwd_auth[*].result)
emr_kms_key_arn : var.is_secondary_region ? null : var.emr_enabled && var.emr_encryption_enabled ? module.emr_kms[0].kms_key_arn : null
emr_master_public_dns : var.emr_enabled ? one(module.emr[*].emr_master_public_dns) : null
emr_port : var.emr_enabled ? one(module.emr[*].emr_port) : null
emr_warehouse_location : var.emr_enabled ? one(module.emr[*].emr_warehouse_location) : null
    }
}
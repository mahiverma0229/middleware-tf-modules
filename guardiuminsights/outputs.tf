# Amazon VPC outputs
output "AZ1" {
  value = join(",", [module.vpc.aws_availability_zones.names[0], module.vpc.aws_availability_zones.zone_ids[0]])
}

output "AZ2" {
  value = join(",", [module.vpc.aws_availability_zones.names[1], module.vpc.aws_availability_zones.zone_ids[1]])
}

output "AZ3" {
  value = join(",", [module.vpc.aws_availability_zones.names[2], module.vpc.aws_availability_zones.zone_ids[2]])
}

output "AZ_number_of_zones" {
  value = var.vpc_num_private_subnets
}

output "cr_standby_instance" {
  value = var.cr_standby_instance
}

output "middleware_vpc" {
  value = module.vpc.vpc
}

output "middleware_vpc_cidr" {
  value = module.vpc.cidr_block
}

output "cr_middleware_vpc_cidr" {
  value = module.vpc.cidr_block
}

output "cr_monitor_vpc_cidr" {
  value = "162.247.240.0/22"
}

# AWS Secrets Manager
output "secrets_manager_kms_key_arn" {
  value = var.push_secrets_to_sm ? can(one(module.secrets_manager_kms[*].secrets_manager_kms_key_arn)) ? one(module.secrets_manager_kms[*].secrets_manager_kms_key_arn) : null : null
  sensitive = true
}

# AWS Transit Gateway outputs
output "transit_gateway_id" {
  value = one(module.transitgateway[*].transit_gateway_id)
}

# Amazon S3 outputs
output "cos-02_host" {
  #value = length(module.s3) > 0 ? "https://s3.amazonaws.com" : ""
  value = ""
}

output "cos-02_port" {
  value = 443
}
# output "cos-02_region" {
#   value = one(module.s3[*].region)
# }

# output "cos-02_access_key" {
#   value     = one(module.s3[*].iam_access_key_id)
#   sensitive = true
# }

# output "cos-02_secret_key" {
#   value     = one(module.s3[*].iam_access_key_secret)
#   sensitive = true
# }

# Amazon ElastiCache Redis outputs
output "redis-01_host" {
  value = one(module.redis[*].primary_endpoint)
}

output "redis-01_username" {
  value = var.redis_enabled ? "null" : null
}

output "redis-01_password" {
  value     = one(module.redis[*].auth_token)
  sensitive = true
}

output "redis-01_port" {
  value = one(module.redis[*].port)
}

output "redis-01_global_group_id" {
  value = var.redis_replica ? null : one(module.redis[*].global_group_id)
}

output "redis-01_kms_key_arn" {
  value     = var.is_secondary_region ? null : one(module.redis_kms[*].kms_key_arn)
  sensitive = true
}

# Amazon RDS PostgreSQL/Amazon Aurora PostgreSQL outputs
output "postgres-03_port" {
  value = var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].port) : null
}

output "postgres-03_host" {
  value = var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].endpoint) : null
}
output "postgres-03_reader_host" {
  value = var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].reader_endpoint) : null
}

output "postgres-03_username" {
  value = var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].username) : null
}

output "postgres-03_password" {
  value     = var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].password) : null
  sensitive = true
}

output "postgres-03_db" {
  value     = var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].postgres_db_name) : null
  sensitive = true
}

output "postgres-03_arn" {
  value = var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].postgres_arn) : null
}

output "postgres-03_encrypt" {
  value = var.postgres_03_aurora_enabled ? one(module.postgres_aurora[*].postgres_encrypt) : null
}

output "postgres-03_aurora_kms_key_arn" {
  value     = var.is_secondary_region ? null : one(module.postgres_aurora_kms[*].kms_key_arn)
  sensitive = true
}

output "postgres-03_aurora_global_cluster_id" {
  value = one(module.postgres_aurora[*].postgres_aurora_global_cluster_id)
}

output "postgres-03_replica_password" {
  value     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.postgres-03_replica_password) ? data.terraform_remote_state.primary[0].outputs.postgres-03_replica_password : null : one(random_password.pg_replica_password[*].result)
  sensitive = true
}

# Amazon DocumentDB outputs
output "mongodb-01_host" {
  value = one(module.docdb[*].endpoint)
}

output "mongodb-01_global_cluster_id" {
  value = one(module.docdb[*].docdb_global_cluster_id)
}

output "mongodb-01_kms_key_arn" {
  value     = var.is_secondary_region ? null : one(module.docdb_kms[*].kms_key_arn)
  sensitive = true
}

output "mongodb-01_port" {
  value = one(module.docdb[*].port)
}

output "mongodb-01_username" {
  value = one(module.docdb[*].username)
}

output "mongodb-01_password" {
  value     = one(module.docdb[*].password)
  sensitive = true
}

output "mongodb-01_admin_username" {
  value = var.docdb_enabled ? "root" : null
}

output "mongodb-01_admin_password" {
  value     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.mongodb-01_admin_password) ? data.terraform_remote_state.primary[0].outputs.mongodb-01_admin_password : null : var.docdb_root_password
  sensitive = true
}

output "mongodb-01_meta_user" {
  value = var.docdb_enabled ? "metadata" : null
}

output "mongodb-01_meta_user_secret" {
  value     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.mongodb-01_meta_user_secret) ? data.terraform_remote_state.primary[0].outputs.mongodb-01_meta_user_secret : null : var.docdb_metadata_password
  sensitive = true
}
/*
output "mongodb-01_auth_mechanism" {
  value = var.docdb_enabled ? "SCRAM-SHA-1" : null
}

output "mongodb-01_conn_options" {
  value = var.docdb_enabled ? "?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false&maxIdleTimeMS=45000" : null
}
*/
output "mongodb-01_conf_message" {
  value     = one(resource.aws_lambda_invocation.run_docdbconf[*].result)
  sensitive = true
}

output "mongodb-01_jks_password" {
  value     = var.is_secondary_region ? can(data.terraform_remote_state.primary[0].outputs.mongodb-01_jks_password) ? data.terraform_remote_state.primary[0].outputs.mongodb-01_jks_password : null : random_password.jks-password[1].result
  sensitive = true
}

# Amazon MSK ouptuts
output "kafka-01_superuser_name" {
  value     = one(module.msk[*].kafka_admin_user)
  sensitive = true
}

output "kafka-01_superuser_pass" {
  value     = one(module.msk[*].kafka_admin_password)
  sensitive = true
}

output "kafka-01_bootstrap_servers_saslssl" {
  value = one(module.msk[*].bootstrap_brokers_sasl_scram)
}

# Commented as the endpoint is required for edge. Uncomment if edge support is enabled.
# output "kafka-01_bootstrap_servers_external" {
#   value = var.msk_express_broker_disabled ? (module.msk[*].bootstrap_brokers_public_tls) : null
# }

output "kafka-01_bootstrap_servers_internal" {
  value = one(module.msk[*].bootstrap_brokers_private_tls)
}

# Commented as the endpoint is required for edge. Uncomment if edge support is enabled.
# output "kafka-01_bootstrap_servers_external_ips" {
#   value = var. msk_express_broker_disabled ? var.msk_setup_phase != "final" ? null : one(module.msk[*].kafka_public_ips) : null
# }

output "kafka-01_conf_message" {
  value = length(module.msk) > 0 ? var.msk_setup_phase == "initial" ? one(resource.aws_lambda_invocation.run_msk_conf[*].result) : "{\"statusCode\": 200, \"body\": \"Done\"}" : "{\"statusCode\": 404, \"body\": \"Not Run\"}"
}

output "kafka-01_jks_password" {
  value     = var.msk_enabled ? random_password.jks-password[0].result : null
  sensitive = true
}

output "kafka-01_kms_key_arn" {
  value     = var.is_secondary_region ? null : one(module.msk_kms[*].kms_key_arn)
  sensitive = true
}

output "kafka-01_express_broker_enabled"{
  value     =  var.msk_enabled ? var.msk_express_broker_disabled ? "false" : "true" : null
}

# MSK Replicator
output "kafka-01_source_sg_id"{
  value     =  var.msk_enabled ? one(module.msk[*].msk_sg) : null 
}

output "kafka-01_cluster_arn"{
  value     =  var.msk_enabled ? one(module.msk[*].kafka-01_cluster_arn) : null
}

output "kafka-01_public_subnet_id"{
  value     =  var.msk_enabled ? one(module.vpc[*].public_subnet) : null
}


/*
Note: The below outputs are of Terraform modules that are no longer used by Guardium Insights
TODO: to be removed later

# Amazon Elastic File System outputs
output "efs_file_system_id" {
  value = one(module.efs[*].efs_file_system_id)
}

output "efs_access_point_id" {
  value = one(module.efs[*].efs_access_point_id)
}

# SOS Audit Logging Agent outputs
output "sos_audit_logging_status" {
  value = one(module.sos_audit_logging[*].sos_audit_logging_status)
}
*/
output "transit_gateway_route_table_id" {
  value = one(module.transitgateway[*].transit_gateway_route_table_id)
}

#Amazon Redshift outputs
output "redshift-02_port" {
  value = var.redshift_enabled ? one(module.redshift[*].redshift_port) : null
}
output "redshift-02_host" {
  value = var.redshift_enabled ? one(module.redshift[*].redshift_cluster_dns_name) : null
}
output "redshift-02_username" {
  value     = var.redshift_enabled ? one(module.redshift[*].redshift_user) : null
  sensitive = true
}
output "redshift-02_password" {
  value     = var.redshift_enabled ? one(module.redshift[*].redshift_password) : null
  sensitive = true
}
output "redshift-02_db" {
  value     = var.redshift_enabled ? one(module.redshift[*].redshift_db) : null
  sensitive = true
}
output "redshift-02_namespaceid" {
  value = var.redshift_enabled ? format("'%s'", one(module.redshift[*].redshift_cluster_namespaceid)) : null
}
output "redshift-02_accountid" {
  value = var.redshift_enabled ? format("'%s'", one(module.redshift[*].redshift_cluster_accountid)) : null
}
output "redshift-02_crt" {
  value = "cert"
}
output "redshift-02_kms_key_arn" {
  value      = can(one(module.redshift_kms[*].kms_key_arn)) ? one(module.redshift_kms[*].kms_key_arn) : null
  sensitive = true
}
//output "redshift-02_datshr_message" {
//  value     = one(resource.aws_lambda_invocation.run_redshift_datashare[*].result)
//  sensitive = true
//}
//output "redshift-02_secondary_region_datshr_message" {
//  value     = var.redshift_enabled ? var.is_secondary_region ? var.redshift_secondary_datshr ?one(resource.aws_lambda_invocation.run_lambda_redshift_failover[*].result) : null : null : null
//  sensitive = true
//}
#Amazon Redshift Serverless outputs
output "redshift-srvls-01_port" {
  value = var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_port) : null
}
output "redshift-srvls-01_host" {
  value = var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_endpoint) : null
}
output "redshift-srvls-01_username" {
  value     = var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_user) : null
  sensitive = true
}
output "redshift-srvls-01_password" {
  value     = var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_password) : null
  sensitive = true
}
output "redshift-srvls-01_db" {
  value     = var.rss_enabled ? one(module.redshift_serverless[*].redshift_srvls_db) : null
  sensitive = true
}
output "redshift-srvls-01_namespaceid" {
  value     = var.rss_enabled ? format("'%s'", one(module.redshift_serverless[*].redshift_srvls_namespaceid)) : null
  sensitive = true
}
output "redshift-srvls-01_accountid" {
  value     = var.rss_enabled ? format("'%s'", one(module.redshift_serverless[*].redshift_srvls_accountid)) : null
  sensitive = true
}
output "redshift-srvls-01_externaldb" {
  value = var.rss_enabled ? var.rss_external_db : null
}
output "redshift-srvls-01_crt" {
  value = "cert"
}
output "redshift-srvls-01_kms_key_arn" {
  value     = var.is_secondary_region ? null : one(module.redshift_srvls_kms[*].kms_key_arn)
  sensitive = true
}
output "redshift-02_multiplehost" {
  description = "Json for multiplehost in the secret"
  value = var.redshift_enabled ? jsonencode({
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
  sensitive = true
}
output "redshift-02_snapshot_copy_grant" {
  value = can(one(module.redshift[*].redshift_snapshot_copy_grant)) ? one(module.redshift[*].redshift_snapshot_copy_grant) : null
}
output "redshift_change_pwd_auth_message" {
  value     = one(resource.aws_lambda_invocation.redshift_change_pwd_auth[*].result)
  sensitive = true
}

#dspm microFE output
output "dspm_micro_frontend_assets_endpoint" {
  description = "dspm microfrontend domain name"
  value       = var.cloudfront_enabled ? one(module.fe-cloudfront[*].cloudfront_domain_name) : null
}

output "dspm_micro_frontend_assets_tag" {
  description = "dspm microfrontend assets tag"
  value       = var.cloudfront_enabled ? "main" : null
}

output "emr_kms_key_arn" {
  description = "The ARN of the KMS key used for EMR encryption"
  value  = var.is_secondary_region ? null : var.emr_enabled && var.emr_encryption_enabled ? module.emr_kms[0].kms_key_arn : null
  sensitive = true
}

output "emr_master_public_dns" {
   description = "To fetch the master DNS of spark instance (can be used for private access within VPC)"
   value       = var.emr_enabled ? one(module.emr[*].emr_master_public_dns) : null
}

output "emr_port" {
   description = "Port used for EMR master node communication"
   value       = var.emr_enabled ? one(module.emr[*].emr_port) : null
}

output "emr_warehouse_location" {
  description = "Spark warehouse location for EMR"
  value       = var.emr_enabled ? one(module.emr[*].emr_warehouse_location) : null
}


output "emr_datalake_bucket" {
  description = "S3 datalake bucket name for EMR"
  value       = local.emr_s3_create ? module.emr_s3[0].bucket_name : ""
}

output "emr_bootstrap_scripts_location" {
  description = "S3 path to EMR bootstrap scripts"
  value       = local.emr_s3_create ? module.emr_s3[0].bootstrap_scripts_location : ""
}

output "emr_logs_location" {
  description = "S3 logs location for EMR"
  value       = local.emr_s3_create ? module.emr_s3[0].logs_location : ""
}

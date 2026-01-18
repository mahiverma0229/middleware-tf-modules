# Guardium Insights Middleware Terraform Outputs

This document provides a comprehensive list of all Guardium Insights middleware Terraform outputs that gets populated into the vault.
- [Amazon VPC Outputs](./TF_outputs_readme.md#amazon-vpc-outputs)
- [AWS Transit Gateway Outputs](./TF_outputs_readme.md#aws-transit-gateway-outputs)
- [Amazon S3 Outputs](./TF_outputs_readme.md#amazon-s3-outputs)
- [Amazon ElastiCache Redis Outputs](./TF_outputs_readme.md#amazon-elasticache-redis-outputs)
- [Amazon RDS PostgreSQL Outputs](./TF_outputs_readme.md#amazon-rds-postgresql-outputs)
- [Amazon Aurora PostgreSQL Outputs](./TF_outputs_readme.md#amazon-aurora-postgresql-outputs)
- [Amazon DocumentDB Outputs](./TF_outputs_readme.md#amazon-documentdb-outputs)
- [Amazon MSK Outputs](./TF_outputs_readme.md#amazon-msk-outputs)

### Amazon VPC Outputs
| Output | Description | Region Scope | Cluster Region(s) |
| :--- | :--- | :--- | :--- |
| AZ1 | The availability zone one name and ID. | Both Single-Region & Multi-Region | Primary, Secondary |
| AZ2 | The availability zone two name and ID. | Both Single-Region & Multi-Region | Primary, Secondary |
| AZ3 | The availability zone three name and ID. | Both Single-Region & Multi-Region | Primary, Secondary |
| AZ_number_of_zones | The number of availability zones. | Both Single-Region & Multi-Region | Primary, Secondary |
| middleware_vpc | The ID of the middleware VPC. | Both Single-Region & Multi-Region | Primary, Secondary |
| middleware_vpc_cidr | The CIDR block of the middleware VPC. | Both Single-Region & Multi-Region | Primary, Secondary |
| cr_middleware_vpc_cidr | The CIDR block of the CR middleware VPC. | Both Single-Region & Multi-Region | Primary, Secondary |
| cr_monitor_vpc_cidr | The CIDR block of the CR monitor VPC. | Both Single-Region & Multi-Region | Primary, Secondary |

### AWS Transit Gateway Outputs
| Output | Description | Region Scope | Cluster Region(s) |
| :--- | :--- | :--- | :--- |
| transit_gateway_id | The ID of the Transit Gateway. | Both Single-Region & Multi-Region | Primary, Secondary |

### Amazon S3 Outputs
| Output | Description | Region Scope | Cluster Region(s) |
| :--- | :--- | :--- | :--- |
| cos-02_host | The value of this is **s3.us-east-1.amazonaws.com** and **s3.us-west-2.amazonaws.com** for primary and secondary Regions respectively. This is used to make the API call to S3 service. | Both Single-Region & Multi-Region | Primary, Secondary |
| cos-02_port | Since the S3 API is exposed over internet, the value of this is set as **443** for HTTPS calls. | Both Single-Region & Multi-Region | Primary, Secondary |

### Amazon ElastiCache Redis Outputs
| Output | Description | Region Scope | Cluster Region(s) |
| :--- | :--- | :--- | :--- |
| redis-01_global_group_id | The ID of the Amazon ElastiCache Redis global replication group. | Multi-Region | Primary |
| redis-01_host | The address of the endpoint for the primary node in the replication group.| Both Single-Region & Multi-Region | Primary, Secondary |
| redis-01_kms_key_arn | The Amazon Resource Name (ARN) of the customer managed KMS key used for encrypting the Amazon ElastiCache Redis. | Both Single-Region & Multi-Region | Primary |
| redis-01_password | The Amazon ElastiCache Redis password used to access password protected server. | Both Single-Region & Multi-Region | Primary, Secondary |
| redis-01_port | The Amazon ElastiCache Redis port number on which each of the cache nodes will accept connections. | Both Single-Region & Multi-Region | Primary, Secondary |
| redis-01_username | The value is **null** as the redis-client does not require a username to establish connectivity with the server. | Both Single-Region & Multi-Region | Primary, Secondary |

### Amazon RDS PostgreSQL Outputs
| Output | Description | Region Scope | Cluster Region(s) |
| :--- | :--- | :--- | :--- |
| postgres-03_arn | The Amazon Resource Name (ARN) of the Amazon RDS PostgreSQL instance. | Single-Region | Primary |
| postgres-03_db | Name of the database engine to be used for Amazon RDS PostgreSQL instance. | Single-Region | Primary |
| postgres-03_encrypt | Specifies whether the Amazon RDS PostgreSQL instance is encrypted. | Single-Region | Primary |
| postgres-03_host | The DNS address of the Amazon RDS PostgreSQL instance. | Single-Region | Primary |
| postgres-03_password | Amazon RDS PostgreSQL master DB user password. | Single-Region | Primary |
| postgres-03_port | The port on which the Amazon RDS PostgreSQL DB accepts connections. | Single-Region | Primary |
| postgres-03_replica_password | The randomly generated password value used by the risk-service to generate the admin password to be later consumed by the service. | Single-Region | Primary |
| postgres-03_username | Amazon RDS PostgreSQL master DB username. | Single-Region | Primary |

### Amazon Aurora PostgreSQL Outputs
| Output | Description | Region Scope | Cluster Region(s) |
| :--- | :--- | :--- | :--- |
| postgres-03_arn | The Amazon Resource Name (ARN) of the Amazon Aurora PostgreSQL cluster. | Both Single-Region & Multi-Region | Primary, Secondary |
| postgres-03_aurora_global_cluster_id | The ID of the Amazon Aurora PostgreSQL global cluster. | Multi-Region | Primary |
| postgres-03_aurora_kms_key_arn | The Amazon Resource Name (ARN) of the customer managed KMS key used for encrypting the Amazon Aurora PostgreSQL cluster. | Both Single-Region & Multi-Region | Primary |
| postgres-03_db | Name of the database engine to be used for Amazon Aurora PostgreSQL cluster. | Both Single-Region & Multi-Region | Primary, Secondary |
| postgres-03_encrypt | Specifies whether the Amazon Aurora PostgreSQL cluster is encrypted. | Both Single-Region & Multi-Region | Primary, Secondary |
| postgres-03_host | The DNS address of the Amazon Aurora PostgreSQL cluster. | Both Single-Region & Multi-Region | Primary, Secondary |
| postgres-03_password | Amazon Aurora PostgreSQL master DB user password. | Both Single-Region & Multi-Region | Primary, Secondary |
| postgres-03_port | The port on which the Amazon Aurora PostgreSQL DB accepts connections. | Both Single-Region & Multi-Region | Primary, Secondary |
| postgres-03_replica_password | The randomly generated password value used by the risk-service to generate the admin password to be later consumed by the service. | Both Single-Region & Multi-Region | Primary, Secondary |
| postgres-03_username | Amazon Aurora PostgreSQL master DB username. | Both Single-Region & Multi-Region | Primary, Secondary |

### Amazon DocumentDB Outputs
| Output | Description | Region Scope | Cluster Region(s) |
| :--- | :--- | :--- | :--- |
| mongodb-01_admin_password | Amazon DocumentDB root user password. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_admin_username | Amazon DocumentDB root username. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_auth_mechanism | Amazon DocumentDB authentication mechanism. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_conf_message | Amazon DocumentDB lambda configuration message. | Both Single-Region & Multi-Region | Primary |
| mongodb-01_conn_optins | Amazon DocumentDB connection options. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_global_cluster_id | The ID of the Amazon DocumentDB global cluster. | Multi-Region | Primary |
| mongodb-01_host | The DNS address of the Amazon DocumentDB cluster. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_jks_password | Amazon DocumentDB JKS password. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_kms_key_arn | The Amazon Resource Name (ARN) of the customer managed KMS key used for encrypting the Amazon DocumentDB cluster. | Both Single-Region & Multi-Region | Primary |
| mongodb-01_meta_user | Amazon DocumentDB meta username. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_meta_user_secret | Amazon DocumentDB meta user password. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_password | Amazon DocumentDB master password. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_port | The port on which the Amazon DocumentDB accepts connections. | Both Single-Region & Multi-Region | Primary, Secondary |
| mongodb-01_username | Amazon DocumentDB master username. | Both Single-Region & Multi-Region | Primary, Secondary |

### Amazon MSK Outputs
| Output | Description | Region Scope | Cluster Region(s) |
| :--- | :--- | :--- | :--- |
| kafka-01_bootstrap_servers_saslssl | DNS names (or IP addresses) and SASL SCRAM port pairs of the Amazon MSK cluster. | Both Single-Region & Multi-Region | Primary, Secondary |
| kafka-01_ca_crt | ACM Certificate Authority Amazon Resource Names (ARNs) used for Amazon MSK cluster client authentication. | Both Single-Region & Multi-Region | Primary, Secondary |
| kafka-01_jks_password | Amazon MSK JKS password. | Both Single-Region & Multi-Region | Primary, Secondary |
| kafka-01_kms_key_arn | The Amazon Resource Name (ARN) of the customer managed KMS key used for encrypting the Amazon MSK cluster. | Both Single-Region & Multi-Region | Primary |
| kafka-01_superuser_name | Amazon MSK cluster admin username. | Both Single-Region & Multi-Region | Primary, Secondary |
| kafka-01_superuser_pass | Amazon MSK cluster admin password. | Both Single-Region & Multi-Region | Primary, Secondary |

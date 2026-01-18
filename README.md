## Overview

This folder contains Terraform modules that are used across our organization's infrastructure-as-code (IAC) deployments. These modules are designed to provide reusable and scalable infrastructure patterns for various use cases. This document provides details on each module available in the "common" folder, including their purpose, usage, and configuration.

The common folder contains the following Terraform modules:
- [aurora-postgresql](README.md#aurora-postgresql)
- [docdb](README.md#docdb)
- [efs](README.md#efs)
- [falconsystem](README.md#falconsystem)
- [kms](README.md#kms)
- [lambda](README.md#lambda)
- [newrelic-infra-agent](README.md#newrelic-infra-agent)
- [opersearch](README.md#opersearch)
- [postgres](README.md#postgres)
- [rabbitmq](README.md#rabbitmq)
- [redis](README.md#redis)
- [redis_multiregion](README.md#redis_multiregion)
- [s3](README.md#s3)
- [sos-audit-logging](README.md#sos-audit-logging)
- [transitgateway](README.md#transitgateway)
- [vpc](README.md#vpc)

## Modules
- ## aurora-postgresql

  Terraform module which creates Amazon Aurora PostgreSQL resources on AWS.

- ## docdb

  Terraform module which creates Amazon DocumentDB resources on AWS.

- ## efs

  Terraform module which creates Amazon Elastic File System resources on AWS.

- ## falconsystem

  Terraform module to setup Falcon.

- ## kms

  Terraform module which creates AWS KMS resources on AWS.

  ### Example Usage

  ##### AWS KMS customer managed single-Region key

  ```hcl
  module "kms" {
    source                  = "../common/kms"
    kms_key_alias           = "alias/example-key"
  }
  
  # Pass it to the middleware KMS key ARN variable to use the created KMS key to encrypt a middleware service.
  module "docdb" {
    source = "../common/docdb"
    ...
    docdb_kms_key_arn = module.kms[0].kms_key_arn
    ...
    depends_on = [
      module.kms[0],
    ]
  }
  ```

  ##### AWS KMS customer-managed multi-Region primary key and replica key

  ```hcl
  data "terraform_remote_state" "primary" {
    count   = var.is_secondary ? 1 : 0
    backend = "s3"
    config  = {
      ...
    }
  }

  module "kms" {
    source        = "../common/kms"
    kms_key_alias = "alias/example-key"
    # NOTE: The value of variable kms_enable_multi_region must be true.
    # In the secondary region, variable kms_replica must be set to true and pass the multi-Region primary key's ARN
    # from Terraform primary state output as the primary key ARN for the replica key.
    kms_replica             = var.is_secondary
    kms_enable_multi_region = true
    kms_primary_key_arn     = var.is_secondary ? can(data.terraform_remote_state.primary[0].outputs.kms_key_arn) ? data.terraform_remote_state.primary[0].outputs.kms_key_arn : null : null
  }

  # Pass it to the middleware KMS key ARN variable to use the created KMS key to encrypt a middleware service.
  module "docdb" {
    source = "../common/docdb"
    ...
    docdb_kms_key_arn = module.kms[0].kms_key_arn
    ...
    depends_on = [
      module.kms[0],
    ]
  }
  ```

  ### Resources
  This is the list of resources that the module may create. This module defines 3 resources.
  
  | Resource | Description |
  | --- | --- |
  | [aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | Manages a single-Region or multi-Region primary KMS key. |
  | [aws_kms_replica_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_replica_key) | Manages a KMS multi-Region replica key. |
  | [aws_kms_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | Provides an alias for a KMS customer master key. |

  ### Inputs

  #### Required Inputs
  This module has no required variables.

  #### Optional Inputs
  These variables have default values and don't have to be set to use this module. You may set these variables to override their default values.

  | Variable | Type | Default | Description |
  | --- | --- | --- | --- |
  | kms_replica | ```bool``` | false | Specify **true** in the secondary region to create the KMS multi-Region replica key. |
  | kms_key_description | ```string``` | "Managed by Terraform" | Specify the description of the KMS key. |
  | kms_key_usage | ```string``` | "ENCRYPT_DECRYPT" | Specify the intended use of the key. Valid values are ENCRYPT_DECRYPT, SIGN_VERIFY, or GENERATE_VERIFY_MAC. You choose the key usage when you create the KMS key, and you cannot change it. To know more about KMS key usage, see [Selecting the key usage](https://docs.aws.amazon.com/kms/latest/developerguide/key-types.html#symm-asymm-choose-key-usage). |
  | kms_customer_master_key_spec | ```string``` | "SYMMETRIC_DEFAULT" | Specify whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values are SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, HMAC_256, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1. You choose the key spec when you create the KMS key, and you cannot change it. To know more about KMS key spec, see [Selecting the key spec](https://docs.aws.amazon.com/kms/latest/developerguide/key-types.html#symm-asymm-choose-key-spec). |
  | kms_key_policy | ```string``` | null | Provide a custom KMS key policy as a valid JSON document using [templatefile()](https://developer.hashicorp.com/terraform/language/functions/templatefile) or [jsonencode()](https://developer.hashicorp.com/terraform/language/functions/jsonencode). If a key policy is not specified, AWS gives the KMS key a [default key policy](https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-default.html). |
  | kms_key_waiting_period | ```number``` | 30 | Specify the waiting period before deleting the KMS key. To know more about KMS key waiting period see, [Deleting keys](https://docs.aws.amazon.com/kms/latest/developerguide/deleting-keys.html#deleting-keys-how-it-works). |
  | kms_key_is_enabled | ```bool``` | true | Set the value to true to enable the KMS key, or false to disable it. |
  | kms_enable_key_rotation | ```bool``` | false | Set the value to true to enable the KMS key rotation, or false to disable it.  To know more about AWS KMS key rotation, see [Rotating AWS KMS keys](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html). |
  | kms_enable_multi_region | ```bool``` | false | Set the value to true to make the KMS key multi-Region,  or false to make it single-Region. Note that a single-Region (regional) key cannot be converted to a multi-Region key after creation. To know more about AWS KMS multi-Region keys, see [Multi-Region keys in AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/multi-region-keys-overview.html). |
  | kms_primary_key_arn | ```string``` | null | Specify ARN of the multi-Region primary key to replicate. When specifying kms_primary_key_arn, kms_replica needs to be set to true. |
  | kms_key_alias | ```string``` | null | Provide an alias for the KMS customer master key. |

  ### Outputs
  | Output | Description |
  | --- | --- |
  | kms_key_arn | The ARN of KMS key created. |

  Please make sure to configure the module with appropriate values for your use case. For more details on how to use this module, refer to the [Terraform documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) or the module's source code.

- ## lambda

  Terraform module which creates AWS Lambda resources on AWS.

- ## newrelic-infra-agent

  Terraform module to setup New Relic Agent.

- ## opersearch

  Terraform module which creates Amazon OpenSearch resources on AWS.

- ## postgres

  Terraform module which creates Amazon RDS PostgreSQL resources on AWS.

- ## rabbitmq

  Terraform module which creates Amazon MQ resources on AWS.

- ## redis

  Terraform module which creates Amazon ElastiCache Redis resources on AWS.

- ## redis_multiregion

  Terraform module which creates Amazon ElastiCache Redis resources on AWS with multi-Region support.

- ## s3

  Terraform module which creates Amazon S3 resources on AWS.

- ## sos-audit-logging

  Terraform module to setup SOS Audit Logging.

- ## transitgateway

  Terraform module which creates AWS Transit Gateway resources on AWS.

- ## vpc

  Terraform module which creates Amazon VPC resources on AWS.



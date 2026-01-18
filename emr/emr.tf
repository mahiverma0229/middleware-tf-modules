locals {
  # Use passed-in bucket information from emr-s3 module
  bootstrap_scripts_location = var.emr_bootstrap_scripts_location
  iceberg_warehouse_location = replace(var.emr_warehouse_location, "s3://", "s3a://")
  logs_location = var.emr_logs_location
  
  # Spark defaults with warehouse configuration
  spark_defaults_with_warehouse = [
    for config in var.emr_configurations : {
      classification = config.classification
      properties = config.classification == "spark-defaults" ? merge(
        config.properties,
        {
          "spark.sql.catalog.spark_catalog.warehouse" = local.iceberg_warehouse_location
        }
      ) : config.properties
    }
  ]
  
  # Default bootstrap actions using dynamic location
  emr_bootstrap_actions = length(var.emr_bootstrap_actions) > 0 ? var.emr_bootstrap_actions : [
    {
      Name = "bootstrap"
      Path = "${local.bootstrap_scripts_location}/archive_emr_bootstrap_system.sh"
      Args = []
    }
  ]
  
  # Default steps using dynamic location
  emr_steps = length(var.emr_steps) > 0 ? var.emr_steps : [
    {
      Name = "spark-connect-restart"
      ActionOnFailure = "CONTINUE"
      Jar = "s3://us-east-1.elasticmapreduce/libs/script-runner/script-runner.jar"
      Properties = ""
      Args = ["${local.bootstrap_scripts_location}/spark-connect-restart.sh"]
      Type = "CUSTOM_JAR"
    }
  ]
}

resource "aws_emr_security_configuration" "emr_security_config" {
  count = var.emr_encryption_enabled ? 1 : 0
  name = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-security-config"
  
  configuration = jsonencode({
    EncryptionConfiguration = {
      EnableInTransitEncryption = false
      EnableAtRestEncryption = true
      
      AtRestEncryptionConfiguration = {
        S3EncryptionConfiguration = {
          EncryptionMode = "SSE-KMS"
          AwsKmsKey = var.emr_kms_key_arn
        }
        
        LocalDiskEncryptionConfiguration = {
          EncryptionKeyProviderType = "AwsKms"
          AwsKmsKey = var.emr_kms_key_arn
          EnableEbsEncryption = true
        }
      }
    }
  })
}

resource "aws_emr_cluster" "emr_cluster" {
  name                       = var.emr_name != null ? var.emr_name : "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-emr"
  release_label              = var.emr_release_label 
  log_uri                    = local.logs_location
  service_role               = var.emr_service_role 
  scale_down_behavior        = var.emr_scale_down_behavior
  unhealthy_node_replacement = var.emr_unhealthy_node_replacement 
  auto_termination_policy {
    idle_timeout = var.emr_auto_termination_policy_timeout
  }
  depends_on                        = [ var.emr_tgw_route_depends_on ] 
  termination_protection            = var.emr_termination_protection 
  keep_job_flow_alive_when_no_steps = var.emr_keep_job_flow_alive_when_no_steps

  ec2_attributes {
    instance_profile                  = var.emr_instance_profile 
    emr_managed_master_security_group = aws_security_group.emr_master_sg.id
    emr_managed_slave_security_group  = aws_security_group.emr_slave_sg.id
    service_access_security_group     = aws_security_group.emr_service_access_sg.id
    key_name                          = var.emr_key_name
    subnet_id                         = var.emr_subnet_ids[0]
  }
  applications           = [for app in var.emr_applications : app.name]
  tags                   = var.emr_tags 
  security_configuration = var.emr_encryption_enabled ? aws_emr_security_configuration.emr_security_config[0].name : null

  # Core instance fleet configuration
  core_instance_fleet {
    name = "Core"
    target_on_demand_capacity = 1
    target_spot_capacity = 0
    
    instance_type_configs {
      instance_type = var.emr_instance_type
      weighted_capacity = 4
      bid_price_as_percentage_of_on_demand_price = 100
      
      ebs_config {
        size = var.emr_ebs_config_size
        type = var.emr_ebs_config_type
        volumes_per_instance = var.emr_ebs_config_volumes_per_instance
      }
    }
    
    launch_specifications {
      on_demand_specification {
        allocation_strategy = "lowest-price"
      }
    }
  }
  
  # Master instance fleet configuration
  master_instance_fleet {
    name = "Primary"
    target_on_demand_capacity = 3
    target_spot_capacity = 0
    
    instance_type_configs {
      instance_type = var.emr_instance_type
      weighted_capacity = 1
      bid_price_as_percentage_of_on_demand_price = 100
      
      ebs_config {
        size = var.emr_ebs_config_size
        type = var.emr_ebs_config_type
        volumes_per_instance = var.emr_ebs_config_volumes_per_instance
      }
    }
    
    launch_specifications {
      on_demand_specification {
        allocation_strategy = "lowest-price"
      }
    }
  }
  lifecycle {
    ignore_changes = [
      master_instance_fleet,
      core_instance_fleet,
      configurations,
      configurations_json,
      tags,
      step,
      log_uri,
      ec2_attributes,
      placement_group_config,
    ]
  }
  

  configurations_json = jsonencode(local.spark_defaults_with_warehouse)
  dynamic "bootstrap_action" {
    for_each = local.emr_bootstrap_actions
    content {
      name = bootstrap_action.value.Name
      path = bootstrap_action.value.Path
      args = bootstrap_action.value.Args
    }
  }
  
  dynamic "step" {
    for_each = local.emr_steps
    content {
      action_on_failure = step.value.ActionOnFailure
      name              = step.value.Name
      hadoop_jar_step {
        jar        = step.value.Jar
        args       = step.value.Args
        properties = step.value.Properties != "" ? { Properties = step.value.Properties } : {}
      }
    }
  }
}
 


resource "aws_emr_managed_scaling_policy" "emr_managed_scaling_policy" {
  cluster_id = aws_emr_cluster.emr_cluster.id
  compute_limits {
    unit_type                       = var.emr_managed_scaling_policy_unit_type
    minimum_capacity_units          = var.emr_managed_scaling_policy_minimum_capacity_units
    maximum_capacity_units          = var.emr_managed_scaling_policy_maximum_capacity_units
    maximum_ondemand_capacity_units = var.emr_managed_scaling_policy_maximum_ondemand_capacity_units
    maximum_core_capacity_units     = var.emr_managed_scaling_policy_maximum_core_capacity_units
  }
}


resource "aws_security_group" "emr_master_sg" {
  name        = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-emr-master-sg"
  description = "Security Master Group for emr cluster"
  vpc_id      = var.vpc_id
  tags        = var.emr_tags

  ingress {
    protocol    = "udp"
    from_port   = 0
    to_port     = 65535
    self        = true
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    self        = true
  }
  ingress {
    protocol    = "tcp"
    from_port   = 15002
    to_port     = 15002
    cidr_blocks = ["10.0.0.0/8"] 
    description = "Allow access to EMR to communicate with master nodes on port 15002"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    self        = true
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
 lifecycle {
    create_before_destroy = true
    ignore_changes = [ingress, egress]
  }
   
  timeouts {
    delete = "2m"
  }
   
  revoke_rules_on_delete = true
}

resource "aws_security_group" "emr_slave_sg" {
  name        = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-emr-slave-sg"
  description = "Security Slave Group for emr cluster"
  vpc_id      = var.vpc_id
  tags        = var.emr_tags

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    self = true
  }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    self = true
  }

  ingress {
    protocol    = "udp"
    from_port   = 0
    to_port     = 65535
    self = true
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [ingress, egress]
  }
  
  timeouts {
    delete = "2m"
  }
  
  revoke_rules_on_delete = true
  
}
resource "aws_security_group" "emr_service_access_sg" {
  name        = "${var.cluster_id}-${var.namespace_id}-${var.identifier_id}-emr-service-access-sg"
  description = "Security Group for EMR service access"
  vpc_id      = var.vpc_id
  tags        = var.emr_tags
    # Allow all outbound traffic
  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  lifecycle {
    create_before_destroy = true
    ignore_changes = [ingress, egress]
  }
  
  timeouts {
    delete = "2m"
  }
  
  revoke_rules_on_delete = true
  
}

resource "aws_security_group_rule" "security_access_ingress_master_tcp" {
  security_group_id        = aws_security_group.emr_service_access_sg.id
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_master_sg.id
}

# Master ingress rules for slave communication
resource "aws_security_group_rule" "master_ingress_slave_udp" {
  security_group_id        = aws_security_group.emr_master_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  source_security_group_id = aws_security_group.emr_slave_sg.id
}

resource "aws_security_group_rule" "master_ingress_slave_tcp" {
  security_group_id        = aws_security_group.emr_master_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_slave_sg.id
}

resource "aws_security_group_rule" "master_ingress_slave_icmp" {
  security_group_id        = aws_security_group.emr_master_sg.id
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = aws_security_group.emr_slave_sg.id
}
# Allow service access to communicate with master nodes
resource "aws_security_group_rule" "service_access_to_master" {
  security_group_id        = aws_security_group.emr_master_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_service_access_sg.id
}

# Slave ingress rules for master communication
resource "aws_security_group_rule" "slave_ingress_master_tcp" {
  security_group_id        = aws_security_group.emr_slave_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_master_sg.id
}

resource "aws_security_group_rule" "slave_ingress_master_icmp" {
  security_group_id        = aws_security_group.emr_slave_sg.id
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = aws_security_group.emr_master_sg.id
}

resource "aws_security_group_rule" "slave_ingress_master_udp" {
  security_group_id        = aws_security_group.emr_slave_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  source_security_group_id = aws_security_group.emr_master_sg.id
}

# Allow service access to communicate with slave nodes
resource "aws_security_group_rule" "service_access_to_slave" {
  security_group_id        = aws_security_group.emr_slave_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_service_access_sg.id
}

# Explicitly define the egress rule from service access to slave on port 8443
# This is to ensure Terraform manages this rule that EMR creates automatically
resource "aws_security_group_rule" "service_access_egress_to_slave_8443" {
  security_group_id        = aws_security_group.emr_service_access_sg.id
  type                     = "egress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_slave_sg.id
  description              = "Allow EMR service access to communicate with slave nodes on port 8443 (egress)"
}

# Explicitly define the ingress rule from service access to master on port 8443
# This is to ensure Terraform manages this rule that EMR creates automatically
resource "aws_security_group_rule" "service_access_to_master_8443" {
  security_group_id        = aws_security_group.emr_master_sg.id
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_service_access_sg.id
  description              = "Allow EMR service access to communicate with master nodes on port 8443"
}

resource "aws_emr_instance_fleet" "task" {
  cluster_id = aws_emr_cluster.emr_cluster.id
  
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = var.emr_ebs_config_size
      type                 = var.emr_ebs_config_type
      volumes_per_instance = var.emr_ebs_config_volumes_per_instance
    }
    instance_type     = var.emr_instance_type
    weighted_capacity = 1
  }
  
  # Optional: Add additional instance types for better spot instance availability
  instance_type_configs {
    bid_price_as_percentage_of_on_demand_price = 100
    ebs_config {
      size                 = var.emr_ebs_config_size
      type                 = var.emr_ebs_config_type
      volumes_per_instance = var.emr_ebs_config_volumes_per_instance
    }
    instance_type     = "r5.xlarge"
    weighted_capacity = 1
  }
  
  launch_specifications {
    spot_specification {
      timeout_duration_minutes = 60
      timeout_action          = "TERMINATE_CLUSTER"
      allocation_strategy     = "price-capacity-optimized"
    }
    on_demand_specification {
      allocation_strategy = "lowest-price"
    }
  }
  
  name                      = "Task Fleet"
  target_on_demand_capacity = 1
  target_spot_capacity      = 0
  lifecycle {
    ignore_changes = [
      target_on_demand_capacity,
      target_spot_capacity,
    ]
  }
}

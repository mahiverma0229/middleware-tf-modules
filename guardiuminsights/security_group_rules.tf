locals {
  security_group_rules = {
    ingress = merge(
      // ensure there are no duplicates, if the same port is used add to the conditional via anytrue(list), etc.

      true ?
      {
        port_443 = {
          description = "Access to Opensearch / S3 / and RabbitMQ Mgmt"
          protocol    = "tcp"
          from_port   = 443
          to_port     = 443
          cidr        = "10.0.0.0/8"
        }
      } : {}
      ,

      anytrue([var.postgres_03_aurora_enabled]) ?
      {
        postgres = {
          description = "Access to Postgres"
          protocol    = "tcp"
          from_port   = var.postgres_03_port
          to_port     = var.postgres_03_port
          cidr        = "10.0.0.0/8"
        }
      } : {}
      ,
      var.msk_enabled ?
      {
        msk = {
          description = "Access to MSK from Lambda"
          protocol    = "tcp"
          from_port   = 9094
          to_port     = 9094
          cidr        = "10.0.0.0/8"
        }
      } : {}
      ,

      true ?
      {
        rabbitmq = {
          description = "Access to Rabbitmq"
          protocol    = "tcp"
          from_port   = 5671
          to_port     = 5671
          cidr        = "10.0.0.0/8"
        }
      } : {}
      ,
      var.docdb_enabled ?
      {
        docdb = {
          description = "Access to docdb"
          protocol    = "tcp"
          from_port   = 27017
          to_port     = 27017
          cidr        = "10.0.0.0/8"
        }
      } : {}
      ,
      var.redis_enabled ?
      {
        redis = {
          description = "Access to redis"
          protocol    = "tcp"
          from_port   = var.redis_port
          to_port     = var.redis_port
          cidr        = "10.0.0.0/8"
        }
      } : {}
      ,
      var.redshift_enabled ?
      {
        redshift = {
          description = "Access to redshift"
          protocol    = "tcp"
          from_port   = var.redshift_port
          to_port     = var.redshift_port
          cidr        = "10.0.0.0/8"
        }
      } : {}
      ,
      var.rss_enabled ?
      {
        rss = {
          description = "Access to redshift serverless"
          protocol    = "tcp"
          from_port   = var.rss_port
          to_port     = var.rss_port
          cidr        = "10.0.0.0/8"
        }
      } : {}
    ), // merge egress
    egress = {
      allow_all_out = {
        description = "allow all"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        cidr        = "0.0.0.0/0"
      }
    }

  }
}

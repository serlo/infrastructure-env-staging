locals {
  api = {
    image_tags = {
      database_layer = "0.3.32"
      server         = "0.28.2"
      cache_worker   = "0.4.2"
    }
  }
}

module "api_redis" {
  source = "github.com/serlo/infrastructure-modules-shared.git//redis?ref=v11.0.0"

  namespace     = kubernetes_namespace.api_namespace.metadata.0.name
  chart_version = "12.6.2"
  image_tag     = "6.0.10"
  node_pool     = module.cluster.node_pools.non-preemptible
}

module "api" {
  source = "github.com/serlo/infrastructure-modules-api.git//?ref=v8.0.0"

  namespace         = kubernetes_namespace.api_namespace.metadata.0.name
  image_tag         = local.api.image_tags.server
  image_pull_policy = "IfNotPresent"
  node_pool         = module.cluster.node_pools.non-preemptible

  environment = "staging"

  cache_worker = {
    enable_cronjob = true
    image_tag      = local.api.image_tags.cache_worker
  }
  google_spreadsheet_api = {
    active_donors = var.api_active_donors_google_spreadsheet_id
    motivation    = var.api_motivation_google_spreadsheet_id
    secret        = var.api_active_donors_google_api_key
  }
  rocket_chat_api = {
    user_id    = var.rocket_chat_user_id
    auth_token = var.rocket_chat_auth_token
    url        = "https://community.serlo.org/"
  }
  mailchimp_api = {
    key = var.athene2_php_newsletter_key
  }
  redis_url = "redis://redis-master:6379"

  database_layer = {
    image_tag = local.api.image_tags.database_layer

    database_url             = "mysql://serlo:${var.athene2_database_password_default}@${module.mysql.database_private_ip_address}:3306/serlo"
    database_max_connections = 25
    sentry_dsn               = "https://849cde772c90451c807ed96a318a935a@o115070.ingest.sentry.io/5649015"
  }

  server = {
    hydra_host = module.hydra.admin_uri
    swr_queue_dashboard = {
      username = var.api_swr_queue_dashboard_username
      password = var.api_swr_queue_dashboard_password
    }
    sentry_dsn = "https://dd6355782e894e048723194b237baa39@o115070.ingest.sentry.io/5385534"

    enmeshed = {
      host           = "https://enmeshed.serlo-staging.dev"
      server_secret  = var.enmeshed_api_key
      webhook_secret = var.enmeshed_api_key
    }
  }

  swr_queue_worker = {
    concurrency = 1
  }
}

module "api_server_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v11.0.0"

  name      = "api"
  namespace = kubernetes_namespace.api_namespace.metadata.0.name
  host      = "api.${local.domain}"
  backend = {
    service_name = module.api.server_service_name
    service_port = module.api.server_service_port
  }
  enable_tls  = true
  enable_cors = true
}

resource "kubernetes_namespace" "api_namespace" {
  metadata {
    name = "api"
  }
}

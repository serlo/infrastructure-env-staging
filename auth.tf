locals {
  ory_chart_version = "0.23.3"

  hydra = {
    image_tag = "v1.11.8"
  }

  kratos = {
    image_tag = "0.11.1-custom"
  }
}

module "hydra" {
  source = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=v15.7.0"

  namespace     = kubernetes_namespace.hydra_namespace.metadata.0.name
  chart_version = local.ory_chart_version
  image_tag     = local.hydra.image_tag
  node_pool     = module.cluster.node_pools.preemptible

  dsn         = "postgres://${var.postgres_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/hydra"
  url_login   = "https://${local.domain}/auth/oauth/login"
  url_logout  = "https://${local.domain}/auth/oauth/logout"
  url_consent = "https://${local.domain}/auth/oauth/consent"
  host        = "hydra.${local.domain}"
}

module "kratos" {
  source = "github.com/serlo/infrastructure-modules-shared.git//kratos?ref=v15.7.0"

  namespace         = kubernetes_namespace.kratos_namespace.metadata.0.name
  dsn               = "postgres://${local.postgres_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/kratos"
  host              = "kratos.${local.domain}"
  smtp_password     = var.athene2_php_smtp_password
  chart_version     = local.ory_chart_version
  image_tag         = local.kratos.image_tag
  domain            = local.domain
  nbp_client_secret = var.kratos_nbp_client_secret
}

resource "kubernetes_namespace" "hydra_namespace" {
  metadata {
    name = "hydra"
  }
}

resource "kubernetes_namespace" "kratos_namespace" {
  metadata {
    name = "kratos"
  }
}

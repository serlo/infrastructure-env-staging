locals {
  ory_chart_version = "0.23.3"

  hydra = {
    image_tag = "v1.11.8"
  }

  kratos = {
    image_tag = "v0.10.1"
  }
}

module "hydra" {
  source = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=v15.0.0"

  namespace     = kubernetes_namespace.hydra_namespace.metadata.0.name
  chart_version = local.ory_chart_version
  image_tag     = local.hydra.image_tag
  node_pool     = module.cluster.node_pools.preemptible

  # TODO: add extra user for hydra
  dsn         = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/hydra"
  url_login   = "https://de.${local.domain}/auth/hydra/login"
  url_logout  = "https://de.${local.domain}/auth/hydra/logout"
  url_consent = "https://de.${local.domain}/auth/hydra/consent"
  host        = "hydra.${local.domain}"
}

module "kratos" {
  source = "github.com/serlo/infrastructure-modules-shared.git//kratos?ref=v15.0.0"

  namespace = kubernetes_namespace.kratos_namespace.metadata.0.name
  # TODO: add extra user for kratos
  dsn  = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/kratos"
  host = "kratos.${local.domain}"
  # TODO: rename
  smtp_password = var.athene2_php_smtp_password
  chart_version = local.ory_chart_version
  image_tag     = local.kratos.image_tag
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

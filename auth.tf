locals {
  ory_chart_version = "0.23.3"

  hydra = {
    image_tag = "v1.11.8"
  }

  kratos = {
    image_tag = "next"
  }
}

module "hydra" {
  source = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=v15.1.0"

  namespace     = kubernetes_namespace.hydra_namespace.metadata.0.name
  chart_version = local.ory_chart_version
  image_tag     = local.hydra.image_tag
  node_pool     = module.cluster.node_pools.preemptible

  # TODO: add extra user for hydra
  dsn         = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/hydra"
  url_login   = "https://${local.domain}/auth/oauth/login"
  url_logout  = "https://${local.domain}/auth/oauth/logout"
  url_consent = "https://${local.domain}/auth/oauth/consent"
  host        = "hydra.${local.domain}"
}

module "kratos" {
  source = "github.com/serlo/infrastructure-modules-shared.git//kratos?ref=v15.1.0"

  namespace = kubernetes_namespace.kratos_namespace.metadata.0.name
  # TODO: add extra user for kratos
  dsn           = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/kratos"
  host          = "kratos.${local.domain}"
  smtp_password = var.athene2_php_smtp_password
  chart_version = local.ory_chart_version
  image_tag     = local.kratos.image_tag
  domain        = local.domain
}
module "kratos-import-users" {
  source = "github.com/serlo/infrastructure-modules-shared.git//kratos-import-users?ref=v15.1.0"

  namespace = kubernetes_namespace.kratos_namespace.metadata.0.name
  node_pool = module.cluster.node_pools.non-preemptible
  schedule  = "0 3 * * *"
  depends_on = [
    module.kratos
  ]
  database = {
    host     = module.mysql.database_private_ip_address
    username = "serlo_readonly"
    password = var.athene2_database_password_readonly
    name     = "serlo"
  }
  # any way to get this service name dynamically from kratos helm chart?
  kratos_host = "http://kratos-admin"
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

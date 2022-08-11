locals {
  ory_chart_version = "0.23.3"

  hydra = {
    image_tag = "v1.11.8"
  }

  kratos = {
    image_tag = "v0.10.1"
  }

  keycloak = {
    chart_version = "5.2.0"
    image_tag     = "14.0.0"
  }
}

module "hydra" {
  source = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=v14.2.10"

  namespace     = kubernetes_namespace.hydra_namespace.metadata.0.name
  chart_version = local.ory_chart_version
  image_tag     = local.hydra.image_tag
  node_pool     = module.cluster.node_pools.preemptible

  # TODO: add extra user for hydra
  dsn         = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/hydra"
  url_login   = "http://localhost:3000/api/hydra/login"
  url_logout  = "http://localhost:3000/api/hydra/logout"
  url_consent = "http://localhost:3000/api/hydra/consent"
  host        = "hydra.${local.domain}"
}

module "kratos" {
  source = "github.com/serlo/infrastructure-modules-shared.git//kratos?ref=v14.2.10"

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
  source    = "github.com/serlo/infrastructure-modules-shared.git//kratos-import-users?ref=v14.2.10"
  namespace = kubernetes_namespace.kratos_namespace.metadata.0.name
  node_pool = module.cluster.node_pools.non-preemptible
  schedule  = "0 4 * * *"
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

module "keycloak" {
  source = "github.com/serlo/infrastructure-modules-shared.git//keycloak?ref=v14.2.10"

  namespace     = kubernetes_namespace.keycloak_namespace.metadata.0.name
  chart_version = local.keycloak.chart_version
  image_tag     = local.keycloak.image_tag
  node_pool     = module.cluster.node_pools.non-preemptible

  host = "keycloak.${local.domain}"
  # TODO: add extra user for keycloak
  database = {
    host     = module.gcloud_postgres.database_private_ip_address
    user     = module.kpi.kpi_database_username_default
    password = var.kpi_kpi_database_password_default
    database = "keycloak"
  }
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

resource "kubernetes_namespace" "keycloak_namespace" {
  metadata {
    name = "keycloak"
  }
}

locals {
  # TODO: not sure if it is a good idea to update hydra and kratos at the same time
  # in v0.23.2 the admin container takes long to be ready, which leads to a timeout in terraform
  # and terraform thinks it is tainted
  ory_chart_version = "0.23.2"

  hydra = {
    image_tag = "v1.11.8"
  }

  kratos = {
    image_tag = "v0.9.0-alpha.2"
  }

  keycloak = {
    chart_version = "5.2.0"
    image_tag     = "14.0.0"
  }
}

module "hydra" {
  source = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=v13.1.0"

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
  # TODO: use a tag when released
  source = "github.com/serlo/infrastructure-modules-shared.git//kratos?ref=kratos"

  namespace = kubernetes_namespace.kratos_namespace.metadata.0.name
  # TODO: add extra user for kratos
  dsn  = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/kratos"
  host = "kratos.${local.domain}"
  # TODO: rename
  smtp_password = var.athene2_php_smtp_password
  chart_version = local.ory_chart_version
  image_tag     = local.kratos.image_tag
}

module "keycloak" {
  source = "github.com/serlo/infrastructure-modules-shared.git//keycloak?ref=v13.1.0"

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

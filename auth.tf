locals {
  chart_version = "0.20.0"

  hydra = {
    image_tag = "v1.10.6"
  }

  kratos = {
    image_tag = "v0.8.0-alpha.1.pre.3"
  }
}

module "hydra" {
  source = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=v5.2.0"

  namespace = kubernetes_namespace.hydra_namespace.metadata.0.name
  # TODO: add extra user for hydra
  dsn           = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/hydra"
  url_login     = "https://de.${local.domain}/auth/hydra/login"
  url_logout    = "https://de.${local.domain}/auth/hydra/logout"
  url_consent   = "https://de.${local.domain}/auth/hydra/consent"
  host          = "hydra.${local.domain}"
  chart_version = local.chart_version
  image_tag     = local.hydra.image_tag
}

module "kratos" {
  source = "github.com/serlo/infrastructure-modules-shared.git//kratos?ref=v5.2.0"

  namespace = kubernetes_namespace.kratos_namespace.metadata.0.name
  # TODO: add extra user for kratos
  dsn  = "postgres://${module.kpi.kpi_database_username_default}:${var.kpi_kpi_database_password_default}@${module.gcloud_postgres.database_private_ip_address}/kratos"
  host = "kratos.${local.domain}"
  # TODO: rename
  smtp_password = var.athene2_php_smtp_password
  chart_version = local.chart_version
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

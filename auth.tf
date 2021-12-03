locals {
  chart_version = "0.21.1"

  hydra = {
    image_tag = "v1.10.7"
  }
}

module "hydra" {
  source = "github.com/serlo/infrastructure-modules-shared.git//hydra?ref=v6.0.0"

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

resource "kubernetes_namespace" "hydra_namespace" {
  metadata {
    name = "hydra"
  }
}

locals {
  kpi = {
    grafana_image_tag        = "1.6.2"
    mysql_importer_image_tag = "1.4.1"
    aggregator_image_tag     = "1.7.1"
    mfnf_importer_image_tag  = "1.0.1"
  }
}

module "kpi" {
  source = "github.com/serlo/infrastructure-modules-kpi.git//kpi?ref=v4.0.0"

  domain = local.domain

  grafana_admin_password = var.kpi_grafana_admin_password
  grafana_serlo_password = var.kpi_grafana_serlo_password

  athene2_database_host              = module.mysql.database_private_ip_address
  athene2_database_password_readonly = var.athene2_database_password_readonly

  kpi_database_host              = module.gcloud_postgres.database_private_ip_address
  kpi_database_password_default  = var.kpi_kpi_database_password_default
  kpi_database_password_readonly = var.kpi_kpi_database_password_readonly

  grafana_image        = "eu.gcr.io/serlo-shared/kpi-grafana:${local.kpi.grafana_image_tag}"
  mysql_importer_image = "eu.gcr.io/serlo-shared/kpi-mysql-importer:${local.kpi.mysql_importer_image_tag}"
  aggregator_image     = "eu.gcr.io/serlo-shared/kpi-aggregator:${local.kpi.aggregator_image_tag}"
  mfnf_importer_image  = "eu.gcr.io/serlo-shared/kpi-mfnf-importer:${local.kpi.mfnf_importer_image_tag}"
}

module "kpi_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v6.0.0"

  name      = "kpi"
  namespace = kubernetes_namespace.kpi_namespace.metadata.0.name
  host      = "stats.${local.domain}"
  backend = {
    service_name = module.kpi.grafana_service_name
    service_port = module.kpi.grafana_service_port
  }
  enable_tls = true
}

resource "kubernetes_namespace" "kpi_namespace" {
  metadata {
    name = "kpi"
  }
}

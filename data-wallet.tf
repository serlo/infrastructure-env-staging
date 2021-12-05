locals {
  data_wallet = {
    chart_versions = {
      mongodb = "10.23.13"
    }

    image_tags = {
      enmeshed = "2.1.1"
      mongodb  = "4.4.8"
    }
  }
}

module "data_wallet" {
  source = "../infrastructure-modules-shared/enmeshed" # TODO

  namespace              = kubernetes_namespace.data_wallet_namespace.metadata.0.name
  chart_versions         = local.data_wallet.chart_versions
  image_tags             = local.data_wallet.image_tags
  host                   = "enmeshed.${local.domain}"
  platform_client_id     = var.enmeshed_platform_client_id     // TODO: update source
  platform_client_secret = var.enmeshed_platform_client_secret // TODO: update source
  api_url                = "api.${local.domain}"
  api_key                = var.api_key_for_enmeshed_connector // TODO: update source and chose a real key
}

resource "kubernetes_namespace" "data_wallet_namespace" {
  metadata {
    name = "data-wallet"
  }
}

module "enmeshed_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v6.0.0"

  name      = "enmeshed"
  namespace = kubernetes_namespace.data_wallet_namespace.metadata.0.name
  host      = "enmeshed.${local.domain}"
  backend = {
    service_name = module.data_wallet.enmeshed_connector_service_name
    service_port = module.data_wallet.enmeshed_connector_service_port
  }
  enable_tls = true
}

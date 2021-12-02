locals {
  data_wallet = {
    image_tags = {
      enmeshed = "2.1.1"
      mongodb  = "4.4.8"
    }
  }
}

module "data_wallet" {
  source = "../infrastructure-modules-shared/enmeshed" # TODO

  namespace  = kubernetes_namespace.enmeshed_namespace.metadata.0.name
  image_tags = local.data_wallet.image_tags
  host       = "enmeshed.${local.domain}"


}
# TODO: maybe change it to data_wallet_namespace
resource "kubernetes_namespace" "enmeshed_namespace" {
  metadata {
    # TODO: maybe change it to data-wallet
    name = "enmeshed"
  }
}

module "enmeshed_ingress" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress?ref=v6.0.0"

  name      = "enmeshed"
  namespace = kubernetes_namespace.enmeshed_namespace.metadata.0.name
  host      = "enmeshed.${local.domain}"
  backend = {
    service_name = module.data_wallet.enmeshed_connector_service_name
    service_port = module.data_wallet.enmeshed_connector_service_port
  }
  enable_tls = true
}

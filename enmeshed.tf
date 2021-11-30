locals {
  enmeshed = {
    image_tags = {
      enmeshed = "2.1.1"
      mongodb  = "4.4.8"
    }
  }
}

module "enmeshed" {
  source = "../infrastructure-modules-shared/enmeshed" # TODO

  namespace  = kubernetes_namespace.enmeshed_namespace.metadata.0.name
  image_tags = local.enmeshed.image_tags
  host       = "enmeshed.${local.domain}"
}

resource "kubernetes_namespace" "enmeshed_namespace" {
  metadata {
    name = "enmeshed"
  }
}

#####################################################################
# settings for staging
#####################################################################
locals {
  domain  = "serlo-staging.dev"
  project = "serlo-staging"

  credentials_path = "secrets/serlo-staging-terraform-15240e38ec22.json"
  service_account  = "terraform@serlo-staging.iam.gserviceaccount.com"
  region           = "europe-west3"

  cluster_machine_type = "n1-standard-2"

  serlo_org_images = {
    server = {
      httpd             = "eu.gcr.io/serlo-shared/serlo-org-httpd:3.3.4"
      php               = "eu.gcr.io/serlo-shared/serlo-org-php:3.3.4"
      notifications_job = "eu.gcr.io/serlo-shared/serlo-org-notifications-job:1.0.2"
    }
    editor_renderer        = "eu.gcr.io/serlo-shared/serlo-org-legacy-editor-renderer:1.0.0"
    legacy_editor_renderer = "eu.gcr.io/serlo-shared/serlo-org-editor-renderer:2.0.9"
    varnish                = "eu.gcr.io/serlo-shared/varnish:6.0"
  }

  athene2_php_definitions-file_path = "secrets/athene2/definitions.staging.php"

  athene2_database_instance_name = "${local.project}-mysql-instance-10072019-1"

  kpi_grafana_admin_password = var.kpi_grafana_admin_password

  kpi_database_instance_name    = "${local.project}-postgres-instance-10072019-2"
  kpi_database_username_default = "serlo"

  ingress_tls_certificate_path = "secrets/serlo_org_selfsigned.crt"
  ingress_tls_key_path         = "secrets/serlo_org_selfsigned.key"
}

#####################################################################
# providers
#####################################################################
provider "cloudflare" {
  version = "~> 2.0"
  email   = var.cloudflare_email
  api_key = var.cloudflare_token
}

provider "google" {
  version     = "~> 2.18"
  project     = "${local.project}"
  credentials = "${file("${local.credentials_path}")}"
}

provider "google-beta" {
  version     = "~> 2.18"
  project     = "${local.project}"
  credentials = "${file("${local.credentials_path}")}"
}

provider "kubernetes" {
  version          = "~> 1.8"
  host             = "${module.gcloud.host}"
  load_config_file = false

  client_certificate     = base64decode(module.gcloud.client_certificate)
  client_key             = base64decode(module.gcloud.client_key)
  cluster_ca_certificate = base64decode(module.gcloud.cluster_ca_certificate)
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}

provider "template" {
  version = "~> 2.1"
}

#####################################################################
# modules
#####################################################################
module "gcloud" {
  source                   = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud?ref=15666ddbd5b93c74c28781fec90a7b03b99b6377"
  project                  = local.project
  clustername              = "${local.project}-cluster"
  location                 = "europe-west3-a"
  region                   = local.region
  machine_type             = local.cluster_machine_type
  issue_client_certificate = true
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"

  providers = {
    google      = "google"
    google-beta = "google-beta"
  }
}

module "gcloud_mysql" {
  source                     = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_mysql?ref=15666ddbd5b93c74c28781fec90a7b03b99b6377"
  database_instance_name     = local.athene2_database_instance_name
  database_connection_name   = "${local.project}:${local.region}:${local.athene2_database_instance_name}"
  database_region            = local.region
  database_name              = "serlo"
  database_tier              = "db-f1-micro"
  database_private_network   = module.gcloud.network
  private_ip_address_range   = module.gcloud.private_ip_address_range
  database_password_default  = var.athene2_database_password_default
  database_password_readonly = var.athene2_database_password_readonly

  providers = {
    google      = "google"
    google-beta = "google-beta"
  }
}

module "gcloud_postgres" {
  source                   = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_postgres?ref=15666ddbd5b93c74c28781fec90a7b03b99b6377"
  database_instance_name   = local.kpi_database_instance_name
  database_connection_name = "${local.project}:${local.region}:${local.kpi_database_instance_name}"
  database_region          = local.region
  database_name            = "kpi"
  database_private_network = module.gcloud.network
  private_ip_address_range = module.gcloud.private_ip_address_range

  database_password_postgres = var.kpi_kpi_database_password_postgres
  database_username_default  = module.kpi.kpi_database_username_default
  database_password_default  = var.kpi_kpi_database_password_default
  database_username_readonly = module.kpi.kpi_database_username_readonly
  database_password_readonly = var.kpi_kpi_database_password_readonly

  providers = {
    google      = "google"
    google-beta = "google-beta"
  }
}

module "athene2_dbsetup" {
  source                    = "github.com/serlo/infrastructure-modules-serlo.org.git//athene2_dbsetup?ref=436e7d7ae36a55c6839645af51e99879bf8120a6"
  namespace                 = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  database_password_default = var.athene2_database_password_default
  database_host             = module.gcloud_mysql.database_private_ip_address
  # currently disable dbsetup via shared bucket in staging.
  # gcloud_service_account_key  = module.gcloud_dbdump_reader.account_key
  # gcloud_service_account_name = module.gcloud_dbdump_reader.account_name
  gcloud_service_account_key  = ""
  gcloud_service_account_name = ""

  providers = {
    kubernetes = "kubernetes"
    null       = "null"
  }
}

module "serlo_org" {
  source = "github.com/serlo/infrastructure-modules-serlo.org.git//?ref=3c22beaf999d156fb5083c6a0909a680955cb0f1"

  namespace         = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  image_pull_policy = "IfNotPresent"

  server = {
    app_replicas = 1
    images       = local.serlo_org_images.server

    domain                = local.domain
    definitions_file_path = local.athene2_php_definitions-file_path

    recaptcha = {
      key    = var.athene2_php_recaptcha_key
      secret = var.athene2_php_recaptcha_secret
    }

    smtp_password = var.athene2_php_smtp_password
    mailchimp_key = var.athene2_php_newsletter_key

    enable_tracking = var.athene2_php_tracking_switch

    database = {
      host     = module.gcloud_mysql.database_private_ip_address
      username = "serlo"
      password = var.athene2_database_password_default
    }

    database_readonly = {
      username = "serlo_readonly"
      password = var.athene2_database_password_readonly
    }

    upload_secret   = file("secrets/serlo-org-6bab84a1b1a5.json")
    hydra_admin_uri = ""
    feature_flags   = "['donation-banner' => true]"
  }

  editor_renderer = {
    app_replicas = 1
    image        = local.serlo_org_images.editor_renderer
  }

  legacy_editor_renderer = {
    app_replicas = 1
    image        = local.serlo_org_images.legacy_editor_renderer
  }

  varnish = {
    app_replicas = 1
    image        = local.serlo_org_images.varnish
  }

  providers = {
    kubernetes = "kubernetes"
    random     = "random"
    template   = "template"
  }
}

module "kpi" {
  source = "github.com/serlo/infrastructure-modules-kpi.git//kpi?ref=v1.3.0"
  domain = local.domain

  grafana_admin_password = var.kpi_grafana_admin_password
  grafana_serlo_password = var.kpi_grafana_serlo_password

  athene2_database_host              = module.gcloud_mysql.database_private_ip_address
  athene2_database_password_readonly = var.athene2_database_password_readonly

  kpi_database_host              = module.gcloud_postgres.database_private_ip_address
  kpi_database_password_default  = var.kpi_kpi_database_password_default
  kpi_database_password_readonly = var.kpi_kpi_database_password_readonly

  grafana_image        = "eu.gcr.io/serlo-shared/kpi-grafana:1.0.1"
  mysql_importer_image = "eu.gcr.io/serlo-shared/kpi-mysql-importer:1.2.1"
  aggregator_image     = "eu.gcr.io/serlo-shared/kpi-aggregator:1.3.2"
}

module "ingress-nginx" {
  source               = "github.com/serlo/infrastructure-modules-shared.git//ingress-nginx?ref=5ce903f3b00082ac99b5a591914c3004d01fe7b2"
  namespace            = kubernetes_namespace.ingress_nginx_namespace.metadata.0.name
  ip                   = module.gcloud.staticip_regional_address
  nginx_image          = "quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.24.1"
  tls_certificate_path = local.ingress_tls_certificate_path
  tls_key_path         = local.ingress_tls_key_path

  providers = {
    kubernetes = "kubernetes"
  }
}

module "cloudflare" {
  source  = "github.com/serlo/infrastructure-modules-env-shared.git//cloudflare?ref=0013c09924b3a06c5cc48d77f65cce72193b5633"
  domain  = local.domain
  ip      = module.gcloud.staticip_regional_address
  zone_id = "ffbc61a7597fd0177bbeb8fff6fa31c8"

  providers = {
    cloudflare = "cloudflare"
  }
}

#####################################################################
# ingress
#####################################################################

resource "kubernetes_ingress" "kpi_ingress" {
  metadata {
    name      = "kpi-ingress"
    namespace = kubernetes_namespace.kpi_namespace.metadata.0.name

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "stats.${local.domain}"

      http {
        path {
          path = "/"

          backend {
            service_name = module.kpi.grafana_service_name
            service_port = module.kpi.grafana_service_port
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "athene2_ingress" {
  metadata {
    name      = "athene2-ingress"
    namespace = kubernetes_namespace.serlo_org_namespace.metadata.0.name

    annotations = {
      "kubernetes.io/ingress.class"             = "nginx",
      "nginx.ingress.kubernetes.io/auth-type"   = "basic",
      "nginx.ingress.kubernetes.io/auth-secret" = "basic-auth-ingress-secret",
      "nginx.ingress.kubernetes.io/auth-realm"  = "Authentication Required"
    }
  }

  spec {
    backend {
      service_name = module.serlo_org.service_name
      service_port = module.serlo_org.service_port
    }
  }
}

resource "kubernetes_secret" "basic_auth_ingress_secret" {

  metadata {
    name      = "basic-auth-ingress-secret"
    namespace = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  }

  data = {
    auth = "serloteam:$apr1$L6BuktMk$qfh8xvsWsPi3uXB0fIiu1/"
  }
}

#####################################################################
# namespaces
#####################################################################
resource "kubernetes_namespace" "serlo_org_namespace" {
  metadata {
    name = "serlo-org"
  }
}

resource "kubernetes_namespace" "kpi_namespace" {
  metadata {
    name = "kpi"
  }
}

resource "kubernetes_namespace" "ingress_nginx_namespace" {
  metadata {
    name = "ingress-nginx"
  }
}

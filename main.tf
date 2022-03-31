#####################################################################
# settings for staging
#####################################################################
locals {
  domain  = "serlo-staging.dev"
  project = "serlo-staging"

  credentials_path = "secrets/serlo-staging-terraform-15240e38ec22.json"
  service_account  = "terraform@serlo-staging.iam.gserviceaccount.com"

  region = "europe-west3"
  zone   = "europe-west3-a"

  cluster_machine_type = "n1-highcpu-2"

  mysql_database_instance_name = "${local.project}-mysql-2021-07-15"
  kpi_database_instance_name   = "${local.project}-postgres-2020-01-19-3"
}

#####################################################################
# modules
#####################################################################
module "cluster" {
  source   = "github.com/serlo/infrastructure-modules-gcloud.git//cluster?ref=v4.0.0"
  name     = "${local.project}-cluster"
  project  = local.project
  location = local.zone
  region   = local.region

  node_pools = {
    preemptible = {
      machine_type       = local.cluster_machine_type
      preemptible        = true
      initial_node_count = 2
      min_node_count     = 2
      max_node_count     = 10
    }
    non-preemptible = {
      machine_type       = local.cluster_machine_type
      preemptible        = false
      initial_node_count = 0
      min_node_count     = 0
      max_node_count     = 10
    }
  }
}

module "mysql" {
  source                     = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_mysql?ref=v4.0.0"
  database_instance_name     = local.mysql_database_instance_name
  database_version           = "MYSQL_5_7"
  database_connection_name   = "${local.project}:${local.region}:${local.mysql_database_instance_name}"
  database_region            = local.region
  database_name              = "serlo"
  database_tier              = "db-n1-standard-1"
  database_private_network   = module.cluster.network
  database_password_default  = var.athene2_database_password_default
  database_password_readonly = var.athene2_database_password_readonly
}

module "gcloud_postgres" {
  source                   = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_postgres?ref=v4.0.0"
  database_instance_name   = local.kpi_database_instance_name
  database_connection_name = "${local.project}:${local.region}:${local.kpi_database_instance_name}"
  database_region          = local.region
  database_names           = ["kpi", "hydra"]
  database_private_network = module.cluster.network

  database_password_postgres = var.kpi_kpi_database_password_postgres
  database_username_default  = module.kpi.kpi_database_username_default
  database_password_default  = var.kpi_kpi_database_password_default
  database_username_readonly = module.kpi.kpi_database_username_readonly
  database_password_readonly = var.kpi_kpi_database_password_readonly
}

module "athene2_dbsetup" {
  source                      = "github.com/serlo/infrastructure-modules-serlo.org.git//athene2_dbsetup?ref=v4.0.0"
  namespace                   = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  node_pool                   = module.cluster.node_pools.preemptible
  database_password_default   = var.athene2_database_password_default
  database_host               = module.mysql.database_private_ip_address
  gcloud_service_account_key  = module.gcloud_dbdump_reader.account_key
  gcloud_service_account_name = module.gcloud_dbdump_reader.account_name
  dbsetup_image               = "eu.gcr.io/serlo-shared/athene2-dbsetup-cronjob:2.0.1"
}

module "gcloud_dbdump_reader" {
  source = "github.com/serlo/infrastructure-modules-gcloud.git//gcloud_dbdump_reader?ref=v4.0.0"
}

module "ingress-nginx" {
  source = "github.com/serlo/infrastructure-modules-shared.git//ingress-nginx?ref=v11.0.2"

  namespace   = kubernetes_namespace.ingress_nginx_namespace.metadata.0.name
  node_pool   = module.cluster.node_pools.non-preemptible
  ip          = module.cluster.address
  domain      = "*.${local.domain}"
  nginx_image = "quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.24.1"
}

module "cloudflare" {
  source  = "github.com/serlo/infrastructure-modules-env-shared.git//cloudflare?ref=v4.1.0"
  domain  = local.domain
  ip      = module.cluster.address
  zone_id = "0067b08b108fbcf88ddaeaae4ac3d6ac"
}

#####################################################################
# namespaces
#####################################################################
resource "kubernetes_namespace" "ingress_nginx_namespace" {
  metadata {
    name = "ingress-nginx"
  }
}

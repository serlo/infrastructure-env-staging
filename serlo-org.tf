locals {
  serlo_org = {
    image_tags = {
      server = {
        httpd             = "7.1.1"
        php               = "7.1.1"
        notifications_job = "2.1.0"
      }
      editor_renderer        = "6.2.2"
      legacy_editor_renderer = "2.1.0"
      frontend               = "4.2.2"
    }
    varnish_image                     = "eu.gcr.io/serlo-shared/varnish:6.0"
    athene2_php_definitions-file_path = "secrets/athene2/definitions.dev.php"
  }
}
module "serlo_org" {
  source = "github.com/serlo/infrastructure-modules-serlo.org.git//?ref=c06694b40ac37bb2d5180dc7d05cd2cc521d4793"

  namespace         = kubernetes_namespace.serlo_org_namespace.metadata.0.name
  image_pull_policy = "IfNotPresent"

  server = {
    app_replicas = 1
    image_tags   = local.serlo_org.image_tags.server

    domain                = local.domain
    definitions_file_path = local.serlo_org.athene2_php_definitions-file_path

    resources = {
      httpd = {
        limits = {
          cpu    = "200m"
          memory = "200Mi"
        }
        requests = {
          cpu    = "100m"
          memory = "100Mi"
        }
      }
      php = {
        limits = {
          cpu    = "700m"
          memory = "600Mi"
        }
        requests = {
          cpu    = "400m"
          memory = "200Mi"
        }
      }
    }

    recaptcha = {
      key    = var.athene2_php_recaptcha_key
      secret = var.athene2_php_recaptcha_secret
    }

    smtp_password = var.athene2_php_smtp_password
    mailchimp_key = var.athene2_php_newsletter_key

    enable_tracking   = var.athene2_php_tracking_switch
    enable_basic_auth = true
    enable_cronjobs   = true
    enable_mail_mock  = true

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
    hydra_admin_uri = module.hydra.admin_uri
    feature_flags   = "['client-frontend' => true, 'frontend-content' => true, 'frontend-diff' => true, 'frontend-editor' => true, 'frontend-legacy-content' => true, 'key-value-store' => true]"
    redis_hosts     = "['redis-master.redis']"
    kafka_host      = ""
  }

  editor_renderer = {
    app_replicas = 1
    image_tag    = local.serlo_org.image_tags.editor_renderer
  }

  legacy_editor_renderer = {
    app_replicas = 1
    image_tag    = local.serlo_org.image_tags.legacy_editor_renderer
  }

  frontend = {
    app_replicas = 1
    image_tag    = local.serlo_org.image_tags.frontend
  }

  varnish = {
    app_replicas = 1
    image        = local.serlo_org.varnish_image
    memory       = "100M"
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

resource "kubernetes_namespace" "serlo_org_namespace" {
  metadata {
    name = "serlo-org"
  }
}

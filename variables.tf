variable "athene2_database_password_default" {
  description = "Password for default username in athene2 database."
}

variable "athene2_database_password_readonly" {
  description = "Password for 'readonly user' in athene2 database."
}

variable "kpi_grafana_admin_password" {
  description = "Admin password for grafana."
}

variable "postgres_database_username_default" {
  default = "serlo"
}

variable "kpi_kpi_database_password_postgres" {
  description = "Password for postgres postgres user."
}

variable "kpi_kpi_database_password_default" {
  description = "Password for default postgres user."
}

variable "kpi_kpi_database_password_readonly" {
  description = "Password for readonly postgres user."
}

variable "cloudflare_token" {
  description = "API Token for cloudflare account."
}

variable "athene2_php_smtp_password" {
  description = "Password for smtp"
}

variable "athene2_php_tracking_switch" {
  description = "Flag whether to activate tracking or not -> usually only set to true in production"
  default     = "false"
}

variable "athene2_php_recaptcha_key" {
  description = "Key for recaptcha"
}

variable "athene2_php_recaptcha_secret" {
  description = "Secret for recaptcha"
}

variable "athene2_php_newsletter_key" {
  description = "Key for newsletter"
}

variable "kpi_grafana_serlo_password" {
  description = "Password for grafana serlo user"
}

variable "api_active_donors_google_api_key" {
  type = string
}

variable "api_active_donors_google_spreadsheet_id" {
  type = string
}

variable "api_motivation_google_spreadsheet_id" {
  type = string
}

variable "rocket_chat_user_id" {
  type = string
}

variable "rocket_chat_auth_token" {
  type = string
}

variable "api_swr_queue_dashboard_username" {
  type = string
}

variable "api_swr_queue_dashboard_password" {
  type = string
}

variable "kratos_nbp_client" {
  type = object({
    id     = string
    secret = string
  })
}

variable "enmeshed_platform_client_id" {
  type = string
}

variable "enmeshed_platform_client_secret" {
  type = string
}

variable "enmeshed_api_key" {
  description = "API key the Enmeshed Connector uses to authenticate requests."
  type        = string
}

variable "openai_api_key" {
  type = string
}

terraform {
  backend "gcs" {
    bucket      = "serlo_staging_terraform"
    prefix      = "state"
    credentials = "secrets/serlo-staging-terraform-15240e38ec22.json"
  }
}

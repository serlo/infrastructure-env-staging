#
# Purpose:
#   ease the bootstraping and hide some terraform magic
#

export cloudsql_credential_filename = serlo-staging-cloudsql-f5977dd586e0.json
export env_name = staging
export gcloud_env_name = serlo_staging
export mysql_instance=10072019-1
export postgres_instance=10072019-2

include mk/gcloud.mk
include mk/terraform.mk

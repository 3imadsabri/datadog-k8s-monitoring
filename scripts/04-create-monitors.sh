#!/usr/bin/env bash
# Crée les 4 monitors Datadog avec Terraform (Monitoring as Code).
# Prérequis :
#   export TF_VAR_datadog_api_key=<clé d'API>
#   export TF_VAR_datadog_app_key=<clé d'application>
#   export TF_VAR_alert_email=<adresse qui reçoit les alertes>
set -euo pipefail
cd "$(dirname "$0")/../terraform"
: "${TF_VAR_datadog_api_key:?Exportez TF_VAR_datadog_api_key}"
: "${TF_VAR_datadog_app_key:?Exportez TF_VAR_datadog_app_key}"
: "${TF_VAR_alert_email:?Exportez TF_VAR_alert_email}"

terraform init -input=false
terraform validate
terraform apply -auto-approve -input=false
terraform output

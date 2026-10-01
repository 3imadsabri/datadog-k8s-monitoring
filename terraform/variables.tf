variable "datadog_api_key" {
  description = "Clé d'API Datadog (TF_VAR_datadog_api_key)"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Clé d'application Datadog (TF_VAR_datadog_app_key)"
  type        = string
  sensitive   = true
}

variable "datadog_api_url" {
  description = "URL de l'API du site Datadog"
  type        = string
  default     = "https://api.datadoghq.eu/"
}

variable "alert_email" {
  description = "Adresse e-mail qui reçoit les alertes"
  type        = string
}

variable "cluster_name" {
  description = "Nom du cluster (datadog.clusterName dans datadog-values.yaml)"
  type        = string
  default     = "liora-k3s"
}

variable "namespace" {
  description = "Namespace Kubernetes de l'application"
  type        = string
  default     = "liora"
}

variable "cpu_threshold" {
  description = "Seuil critique d'utilisation CPU (%)"
  type        = number
  default     = 60
}

variable "ram_threshold" {
  description = "Seuil critique d'utilisation RAM (%)"
  type        = number
  default     = 80
}

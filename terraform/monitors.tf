locals {
  notify = "@${var.alert_email}"
  tags   = ["env:exam", "team:monitoring", "managed-by:terraform", "kube_cluster_name:${var.cluster_name}"]
}

# 1. CPU des nœuds du cluster > 60 %
resource "datadog_monitor" "cpu_high" {
  name    = "[${var.cluster_name}] CPU > ${var.cpu_threshold}% sur {{host.name}}"
  type    = "metric alert"
  query   = "avg(last_5m):100 - avg:system.cpu.idle{kube_cluster_name:${var.cluster_name}} by {host} > ${var.cpu_threshold}"
  message = <<-EOT
    {{#is_alert}}CPU critique sur le nœud {{host.name}} du cluster ${var.cluster_name} : {{value}} % (seuil ${var.cpu_threshold} %).{{/is_alert}}
    {{#is_warning}}CPU élevé sur le nœud {{host.name}} : {{value}} %.{{/is_warning}}
    {{#is_recovery}}CPU revenu à la normale sur {{host.name}}.{{/is_recovery}}
    ${local.notify}
  EOT

  monitor_thresholds {
    critical          = var.cpu_threshold
    warning           = var.cpu_threshold - 10
    critical_recovery = var.cpu_threshold - 5
  }

  require_full_window = false
  include_tags        = true
  tags                = local.tags
}

# 2. RAM des nœuds du cluster > 80 %
resource "datadog_monitor" "ram_high" {
  name    = "[${var.cluster_name}] RAM > ${var.ram_threshold}% sur {{host.name}}"
  type    = "metric alert"
  query   = "avg(last_5m):( 1 - avg:system.mem.pct_usable{kube_cluster_name:${var.cluster_name}} by {host} ) * 100 > ${var.ram_threshold}"
  message = <<-EOT
    {{#is_alert}}RAM critique sur le nœud {{host.name}} du cluster ${var.cluster_name} : {{value}} % utilisés (seuil ${var.ram_threshold} %).{{/is_alert}}
    {{#is_warning}}RAM élevée sur le nœud {{host.name}} : {{value}} % utilisés.{{/is_warning}}
    {{#is_recovery}}RAM revenue à la normale sur {{host.name}}.{{/is_recovery}}
    ${local.notify}
  EOT

  monitor_thresholds {
    critical          = var.ram_threshold
    warning           = var.ram_threshold - 10
    critical_recovery = var.ram_threshold - 5
  }

  require_full_window = false
  include_tags        = true
  tags                = local.tags
}

# 3. Pod dans un état autre que Running (Pending, Failed, Unknown)
resource "datadog_monitor" "pod_not_running" {
  name    = "[${var.cluster_name}] Pod non Running dans ${var.namespace} : {{pod_name.name}}"
  type    = "query alert"
  query   = "max(last_5m):sum:kubernetes_state.pod.status_phase{kube_namespace:${var.namespace},!pod_phase:running,!pod_phase:succeeded} by {pod_name,pod_phase} > 0"
  message = <<-EOT
    {{#is_alert}}Le pod {{pod_name.name}} du namespace ${var.namespace} n'est pas Running (phase : {{pod_phase.name}}).{{/is_alert}}
    {{#is_recovery}}Le pod {{pod_name.name}} n'est plus en anomalie.{{/is_recovery}}
    ${local.notify}
  EOT

  monitor_thresholds {
    critical = 0
  }

  notify_no_data      = false
  timeout_h           = 1 # un pod supprimé n'envoie plus de données : l'alerte se résout seule après 1 h
  require_full_window = false
  include_tags        = true
  tags                = local.tags
}

# 4. Réplicas indisponibles (pod Running mais pas prêt : CrashLoopBackOff, échec de readiness...)
resource "datadog_monitor" "replicas_unavailable" {
  name    = "[${var.cluster_name}] Réplicas indisponibles : {{kube_deployment.name}}"
  type    = "query alert"
  query   = "max(last_5m):sum:kubernetes_state.deployment.replicas_unavailable{kube_namespace:${var.namespace}} by {kube_deployment} > 0"
  message = <<-EOT
    {{#is_alert}}Le déploiement {{kube_deployment.name}} (namespace ${var.namespace}) a {{value}} réplica(s) indisponible(s).{{/is_alert}}
    {{#is_recovery}}Tous les réplicas de {{kube_deployment.name}} sont de nouveau disponibles.{{/is_recovery}}
    ${local.notify}
  EOT

  monitor_thresholds {
    critical = 0
  }

  notify_no_data      = false
  require_full_window = false
  include_tags        = true
  tags                = local.tags
}

output "monitor_ids" {
  value = {
    cpu_high             = datadog_monitor.cpu_high.id
    ram_high             = datadog_monitor.ram_high.id
    pod_not_running      = datadog_monitor.pod_not_running.id
    replicas_unavailable = datadog_monitor.replicas_unavailable.id
  }
}

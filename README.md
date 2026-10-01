# Monitoring d'une infrastructure Kubernetes avec Datadog

Projet d'évaluation du module **Datadog DevOps** : déployer l'application
[apm-datadog](https://github.com/datascientest/apm-datadog) dans un cluster Kubernetes, collecter
les **traces APM** des appels GET, POST, PUT et DELETE du service `notes`, et alerter par e-mail
quand le CPU dépasse 60 %, la RAM 80 %, ou qu'un pod n'est pas `Running`.

## Architecture

```
                         Cluster k3s "liora-k3s" (1 nœud)
 ┌───────────────────────────────────────────────────────────────────────────┐
 │ namespace liora                                                           │
 │   notes  x2  ──HTTP──▶ calendar x2          notes ──SQL──▶ db (PostgreSQL) │
 │   (NodePort 30080)       (ClusterIP 9090)                  (PVC 1 Gi)       │
 │      │ traces (ddtrace) ──▶ hostIP:8126                                    │
 │ namespace datadog                                                         │
 │   datadog-agent (DaemonSet : agent + trace-agent + process-agent)         │
 │   datadog-cluster-agent (kube-state-metrics core)                          │
 └──────────────────────────────┬────────────────────────────────────────────┘
                                │ métriques, logs, traces
                                ▼
                     Datadog EU (datadoghq.eu)  ── monitors (Terraform) ──▶ e-mail
```

| Exigence de l'énoncé | Réalisation |
|---|---|
| Déployer l'application dans Kubernetes (Kompose) | `kompose/` (sortie brute de `kompose convert`) puis manifests corrigés dans `k8s/` |
| Traces des appels GET, POST, PUT, DELETE de `notes` | `ddtrace-run` + `DD_AGENT_HOST=status.hostIP` + `datadog.apm.portEnabled` ; trafic : `scripts/generate-traffic.sh` |
| Alerte e-mail CPU > 60 % | monitor `cpu_high` (`terraform/monitors.tf`) |
| Alerte e-mail RAM > 80 % | monitor `ram_high` |
| Alerte e-mail pod non `Running` | monitors `pod_not_running` (phase Pending/Failed/Unknown) et `replicas_unavailable` (CrashLoopBackOff, readiness) |
| 2 réplicas de `notes` et 2 de `calendar` | `replicas: 2` dans `k8s/20-calendar.yaml` et `k8s/30-notes.yaml` |
| Fichiers de configuration et logs des pods | `k8s/`, `datadog/`, `terraform/`, `app/` et `logs/` (`scripts/collect-logs.sh`) |
| PDF de la démarche avec captures | `docs/exercice_datadog_sabri_imad.pdf` |

## Prérequis

- Un serveur **Ubuntu 22.04/24.04** avec au moins **2 vCPU et 4 Go de RAM** (k3s + agent Datadog + 5 pods).
- Un compte **Datadog** sur le site **EU** (essai gratuit de 14 jours) avec :
  - une **clé d'API** (*Organization Settings > API Keys*) ;
  - une **clé d'application** (*Organization Settings > Application Keys*) pour Terraform.

## Déploiement

```bash
git clone https://github.com/3imadsabri/datadog-k8s-monitoring.git
cd datadog-k8s-monitoring

# 1. Outils : k3s, Helm, Docker, Terraform, stress-ng
./scripts/00-install-prereqs.sh

# 2. Images notes et calendar, importées dans k3s
./scripts/01-build-images.sh

# 3. Application : PostgreSQL, calendar x2, notes x2
./scripts/02-deploy-app.sh

# 4. Agent Datadog (Helm) - la clé est saisie sans s'afficher à l'écran
read -s -p "DD_API_KEY: " DD_API_KEY && export DD_API_KEY
./scripts/03-install-datadog.sh

# 5. Monitors (Terraform)
read -s -p "APP KEY: " TF_VAR_datadog_app_key && export TF_VAR_datadog_app_key
export TF_VAR_datadog_api_key=$DD_API_KEY
export TF_VAR_alert_email=<adresse e-mail>
./scripts/04-create-monitors.sh
```

## Générer des traces

```bash
./scripts/generate-traffic.sh 30            # 30 tours de POST, GET, PUT, DELETE
```

Les traces apparaissent dans **APM > Traces** (service `notes`, env `exam`) ; les appels avec
`add_date=y` montrent la trace distribuée `notes → calendar`.

## Tester les alertes

```bash
./scripts/test-alerts.sh cpu           # CPU à 90 % pendant 8 min  -> alerte CPU
./scripts/test-alerts.sh ram           # RAM à ~88 % pendant 8 min -> alerte RAM
./scripts/test-alerts.sh pod           # image inexistante -> pod Pending -> alerte pod
./scripts/test-alerts.sh pod-restore   # retour à la normale -> e-mail de rétablissement
```

## Logs des pods

```bash
./scripts/collect-logs.sh               # écrit logs/*.log, l'état du cluster et le statut de l'agent
```

## Structure

```
app/          code de l'application (repris de datascientest/apm-datadog) + Dockerfiles allégés
kompose/      docker-compose d'origine et sortie brute de kompose convert (point de départ)
k8s/          manifests Kubernetes appliqués (kustomization.yaml)
datadog/      valeurs Helm de l'agent Datadog
terraform/    monitors Datadog (Monitoring as Code)
scripts/      installation, déploiement, trafic, tests d'alerte, collecte de logs
logs/         logs des pods et statut de l'agent
docs/         rapport PDF et captures d'écran
```

## Nettoyage

```bash
cd terraform && terraform destroy -auto-approve && cd ..
helm uninstall datadog-agent -n datadog
kubectl delete -k k8s/
```

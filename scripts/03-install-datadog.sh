#!/usr/bin/env bash
# Installe l'agent Datadog (DaemonSet + Cluster Agent) avec Helm.
# Prérequis : export DD_API_KEY=<votre clé d'API Datadog>
set -euo pipefail
cd "$(dirname "$0")/.."
: "${DD_API_KEY:?Exportez DD_API_KEY avant de lancer ce script}"

kubectl create namespace datadog --dry-run=client -o yaml | kubectl apply -f -
kubectl -n datadog create secret generic datadog-secret \
  --from-literal api-key="$DD_API_KEY" --dry-run=client -o yaml | kubectl apply -f -

helm repo add datadog https://helm.datadoghq.com >/dev/null 2>&1 || true
helm repo update datadog
helm upgrade --install datadog-agent datadog/datadog \
  -n datadog -f datadog/datadog-values.yaml --wait --timeout 10m

kubectl -n datadog get pods -o wide
AGENT_POD=$(kubectl -n datadog get pods -l app=datadog-agent -o jsonpath='{.items[0].metadata.name}')
kubectl -n datadog exec "$AGENT_POD" -c agent -- agent status | sed -n '/APM Agent/,/====/p' | head -25

#!/usr/bin/env bash
# Enregistre les logs de tous les pods de l'application et de l'agent Datadog dans logs/.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=logs
mkdir -p "$OUT"

{
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="
  kubectl get nodes -o wide
  echo
  kubectl -n liora get deploy,pods,svc,pvc -o wide
  echo
  kubectl -n datadog get pods -o wide
} > "$OUT/etat-cluster.txt"

for pod in $(kubectl -n liora get pods -o name); do
  name=${pod#pod/}
  for c in $(kubectl -n liora get "$pod" -o jsonpath='{.spec.initContainers[*].name} {.spec.containers[*].name}'); do
    kubectl -n liora logs "$pod" -c "$c" --timestamps > "$OUT/liora_${name}_${c}.log" 2>&1 || true
  done
done

AGENT_POD=$(kubectl -n datadog get pods -l app=datadog-agent -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -n "$AGENT_POD" ]; then
  kubectl -n datadog exec "$AGENT_POD" -c agent -- agent status > "$OUT/datadog-agent-status.txt" 2>&1 || true
  kubectl -n datadog logs "$AGENT_POD" -c trace-agent --tail=300 > "$OUT/datadog-trace-agent.log" 2>&1 || true
fi

ls -la "$OUT"

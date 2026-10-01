#!/usr/bin/env bash
# Déploie PostgreSQL, calendar (x2) et notes (x2) dans le namespace liora.
set -euo pipefail
cd "$(dirname "$0")/.."

kubectl apply -k k8s/
kubectl -n liora rollout status deploy/db --timeout=300s
kubectl -n liora rollout status deploy/calendar --timeout=300s
kubectl -n liora rollout status deploy/notes --timeout=300s
kubectl -n liora get deploy,pods,svc,pvc -o wide

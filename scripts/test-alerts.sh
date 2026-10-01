#!/usr/bin/env bash
# Déclenche volontairement les alertes pour vérifier les monitors.
# Usage : ./test-alerts.sh cpu | ram | pod | pod-restore
set -euo pipefail

case "${1:-}" in
  cpu)
    # Toutes les CPU à 90 % pendant 8 minutes (> 60 % sur la fenêtre de 5 min)
    stress-ng --cpu 0 --cpu-load 90 --timeout 8m --metrics-brief
    ;;
  ram)
    # Réserve 88 % de la mémoire disponible pendant 8 minutes (> 80 %)
    stress-ng --vm 1 --vm-bytes 88% --vm-keep --timeout 8m --metrics-brief
    ;;
  pod)
    # Image inexistante sur un réplica de calendar -> ErrImagePull / ImagePullBackOff (phase Pending)
    kubectl -n liora set image deploy/calendar calendar=liora/calendar:inexistante
    sleep 20
    kubectl -n liora get pods -o wide
    echo "Alerte attendue d'ici 1 à 3 minutes. Restaurer avec : $0 pod-restore"
    ;;
  pod-restore)
    kubectl -n liora rollout undo deploy/calendar
    kubectl -n liora rollout status deploy/calendar --timeout=180s
    kubectl -n liora get pods -o wide
    ;;
  *)
    echo "Usage : $0 cpu | ram | pod | pod-restore" >&2
    exit 1
    ;;
esac

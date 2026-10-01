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
    # Réserve la mémoire disponible moins 12 % du total pendant 8 minutes -> ~88 % utilisés (> 80 %)
    total_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    avail_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    bytes_kb=$(( avail_kb - total_kb * 12 / 100 ))
    echo "Réservation de $(( bytes_kb / 1024 )) Mo (disponible : $(( avail_kb / 1024 )) Mo / total : $(( total_kb / 1024 )) Mo)"
    stress-ng --vm 1 --vm-bytes "${bytes_kb}K" --vm-keep --timeout 8m --metrics-brief
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

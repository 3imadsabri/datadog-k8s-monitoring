#!/usr/bin/env bash
# Construit les images notes et calendar puis les importe dans le containerd de k3s
# (pas besoin de registre : les pods utilisent imagePullPolicy: IfNotPresent).
set -euo pipefail
cd "$(dirname "$0")/../app"

VERSION="${VERSION:-1.0.0}"

for svc in notes calendar; do
  sudo docker build -f "Dockerfile.${svc}" -t "liora/${svc}:${VERSION}" .
  sudo docker save "liora/${svc}:${VERSION}" | sudo k3s ctr -n k8s.io images import -
done

sudo k3s ctr -n k8s.io images ls | grep liora/

#!/usr/bin/env bash
# Installe k3s, Helm, Docker, Terraform et stress-ng sur un serveur Ubuntu 22.04/24.04.
set -euo pipefail

sudo apt-get update -y
sudo apt-get install -y docker.io stress-ng curl git
sudo usermod -aG docker "$USER" || true

if ! command -v k3s >/dev/null; then
  curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
fi

if ! command -v helm >/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

if ! command -v terraform >/dev/null; then
  sudo snap install terraform --classic
fi

mkdir -p "$HOME/.kube"
cp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

kubectl get nodes -o wide
echo "OK - outils installés. Reconnectez-vous (ou 'newgrp docker') pour utiliser docker sans sudo."

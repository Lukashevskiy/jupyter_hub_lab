#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "[1/3] Build single-user image"
docker build -t jupyter-custom-gpu:latest -f Dockerfile .

echo "[2/3] Ensure host directories exist"
sudo mkdir -p /srv/jupyterhub/home /srv/jupyterhub/opt-packages
sudo chmod 0777 /srv/jupyterhub/opt-packages

echo "[3/3] Start JupyterHub"
docker compose up -d --build

echo "JupyterHub: http://localhost:8000"

#!/usr/bin/env bash
set -euo pipefail

command -v kubectl >/dev/null || { echo "kubectl not found"; exit 1; }
command -v helm >/dev/null || { echo "helm not found"; exit 1; }
command -v docker >/dev/null || { echo "docker not found"; exit 1; }

kubectl version --client
helm version
docker version --format '{{.Server.Version}}'

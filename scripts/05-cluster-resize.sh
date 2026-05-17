#!/usr/bin/env bash
set -euo pipefail

RELEASE="${1:-data-exp-medium}"
REPLICAS="${2:-2}"

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  source .env
  set +a
else
  echo ".env not found. Copy .env.example to .env first."
  exit 1
fi

echo "Resizing ${RELEASE} workers to replicas=${REPLICAS}"

kubectl scale statefulset "${RELEASE}-worker" \
  -n "${COMPUTE_NAMESPACE}" \
  --replicas="${REPLICAS}"

kubectl rollout status statefulset "${RELEASE}-worker" -n "${COMPUTE_NAMESPACE}" || true
kubectl get pods -n "${COMPUTE_NAMESPACE}" -l app.kubernetes.io/instance="${RELEASE}"

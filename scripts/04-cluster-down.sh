#!/usr/bin/env bash
set -euo pipefail

RELEASE="${1:-data-exp-medium}"

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  source .env
  set +a
else
  echo ".env not found. Copy .env.example to .env first."
  exit 1
fi

echo "Scaling down Spark cluster: ${RELEASE}"

kubectl scale deployment "${RELEASE}-connect" -n "${COMPUTE_NAMESPACE}" --replicas=0 || true
kubectl scale statefulset "${RELEASE}-worker" -n "${COMPUTE_NAMESPACE}" --replicas=0 || true
kubectl scale deployment "${RELEASE}-master" -n "${COMPUTE_NAMESPACE}" --replicas=0 || true

kubectl get pods -n "${COMPUTE_NAMESPACE}" -l app.kubernetes.io/instance="${RELEASE}"

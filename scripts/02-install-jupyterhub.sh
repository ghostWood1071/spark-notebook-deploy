#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if [ -f .env ]; then
  set -a
  source .env
  set +a
else
  echo ".env not found. Copy .env.example to .env first."
  exit 1
fi

kubectl apply -f k8s/00-namespaces.yaml
kubectl apply -f k8s/01-jupyter-auth-secret.yaml

helm repo add jupyterhub https://hub.jupyter.org/helm-chart/ || true
helm repo update

TMP_VALUES="$(mktemp)"
cp helm/jupyterhub-values.yaml "${TMP_VALUES}"

# Simple replacement without requiring yq.
sed -i "s|notebook.k8s.tailnet|${JUPYTER_HOST}|g" "${TMP_VALUES}"
sed -i "s|ghostwood/spark-jupyter-client|${JUPYTER_IMAGE%:*}|g" "${TMP_VALUES}"
sed -i "s|tag: \"1.0.0\"|tag: \"${JUPYTER_IMAGE##*:}\"|g" "${TMP_VALUES}"

helm upgrade --install jupyterhub jupyterhub/jupyterhub \
  --namespace "${JUPYTER_NAMESPACE}" \
  --create-namespace \
  --values "${TMP_VALUES}"

rm -f "${TMP_VALUES}"

kubectl get pods -n "${JUPYTER_NAMESPACE}"
kubectl get ingress -n "${JUPYTER_NAMESPACE}" || true

#!/usr/bin/env bash
set -euo pipefail

SIZE="${1:-medium}"
RELEASE="${2:-data-exp-${SIZE}}"

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
kubectl apply -f k8s/02-spark-s3-secret.yaml

VALUES_FILE="charts/spark-shared-cluster/values-${SIZE}.yaml"

if [ ! -f "${VALUES_FILE}" ]; then
  echo "Invalid size '${SIZE}'. Expected one of: small, medium, large."
  exit 1
fi

helm upgrade --install "${RELEASE}" charts/spark-shared-cluster \
  --namespace "${COMPUTE_NAMESPACE}" \
  --create-namespace \
  -f charts/spark-shared-cluster/values.yaml \
  -f "${VALUES_FILE}" \
  --set image.repository="${SPARK_CLUSTER_IMAGE%:*}" \
  --set image.tag="${SPARK_CLUSTER_IMAGE##*:}" \
  --set spark.hiveMetastoreUris="${HIVE_METASTORE_URIS}" \
  --set spark.s3aEndpoint="${S3A_ENDPOINT}" \
  --set spark.warehouseDir="${SPARK_WAREHOUSE_DIR}"

echo
echo "Spark cluster is starting..."
kubectl get pods -n "${COMPUTE_NAMESPACE}" -l app.kubernetes.io/instance="${RELEASE}"
echo
echo "Spark Connect endpoint:"
echo "  sc://${RELEASE}-connect.${COMPUTE_NAMESPACE}.svc.cluster.local:15002"

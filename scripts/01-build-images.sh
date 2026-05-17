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

echo "Building Spark cluster image: ${SPARK_CLUSTER_IMAGE}"
docker build \
  --build-arg SPARK_BASE_IMAGE="${SPARK_BASE_IMAGE}" \
  --build-arg SPARK_VERSION="${SPARK_VERSION}" \
  -t "${SPARK_CLUSTER_IMAGE}" \
  spark-cluster-image

echo "Building Jupyter image: ${JUPYTER_IMAGE}"
docker build \
  --build-arg SPARK_BASE_IMAGE="${SPARK_BASE_IMAGE}" \
  --build-arg PYSPARK_VERSION="${PYSPARK_VERSION}" \
  -t "${JUPYTER_IMAGE}" \
  jupyter-image

echo "Done."
echo "If needed:"
echo "  docker push ${SPARK_CLUSTER_IMAGE}"
echo "  docker push ${JUPYTER_IMAGE}"

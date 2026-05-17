#!/usr/bin/env bash
set -euo pipefail

export SPARK_HOME="${SPARK_HOME:-/opt/spark}"

: "${SPARK_MASTER_URL:?SPARK_MASTER_URL is required, example spark://data-exp-medium-master.compute.svc.cluster.local:7077}"

export SPARK_WORKER_CORES="${SPARK_WORKER_CORES:-2}"
export SPARK_WORKER_MEMORY="${SPARK_WORKER_MEMORY:-4g}"
export SPARK_WORKER_WEBUI_PORT="${SPARK_WORKER_WEBUI_PORT:-8081}"

echo "[spark-worker] master=${SPARK_MASTER_URL}"
echo "[spark-worker] cores=${SPARK_WORKER_CORES} memory=${SPARK_WORKER_MEMORY}"

exec "${SPARK_HOME}/bin/spark-class" org.apache.spark.deploy.worker.Worker \
  --webui-port "${SPARK_WORKER_WEBUI_PORT}" \
  --cores "${SPARK_WORKER_CORES}" \
  --memory "${SPARK_WORKER_MEMORY}" \
  "${SPARK_MASTER_URL}"

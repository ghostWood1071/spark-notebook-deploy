#!/usr/bin/env bash
set -euo pipefail

export SPARK_HOME="${SPARK_HOME:-/opt/spark}"
export SPARK_MASTER_HOST="${SPARK_MASTER_HOST:-$(hostname -f)}"
export SPARK_MASTER_PORT="${SPARK_MASTER_PORT:-7077}"
export SPARK_MASTER_WEBUI_PORT="${SPARK_MASTER_WEBUI_PORT:-8080}"

echo "[spark-master] SPARK_HOME=${SPARK_HOME}"
echo "[spark-master] host=${SPARK_MASTER_HOST} port=${SPARK_MASTER_PORT} ui=${SPARK_MASTER_WEBUI_PORT}"

exec "${SPARK_HOME}/bin/spark-class" org.apache.spark.deploy.master.Master \
  --host "${SPARK_MASTER_HOST}" \
  --port "${SPARK_MASTER_PORT}" \
  --webui-port "${SPARK_MASTER_WEBUI_PORT}"

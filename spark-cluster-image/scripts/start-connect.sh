#!/usr/bin/env bash
set -euo pipefail

export SPARK_HOME="${SPARK_HOME:-/opt/spark}"

: "${SPARK_MASTER_URL:?SPARK_MASTER_URL is required, example spark://data-exp-medium-master.compute.svc.cluster.local:7077}"

SPARK_CONNECT_PORT="${SPARK_CONNECT_PORT:-15002}"
POD_IP="${POD_IP:-}"
SPARK_DRIVER_HOST="${SPARK_DRIVER_HOST:-${POD_IP}}"
SPARK_DRIVER_BIND_ADDRESS="${SPARK_DRIVER_BIND_ADDRESS:-0.0.0.0}"
SPARK_DRIVER_PORT="${SPARK_DRIVER_PORT:-37077}"
SPARK_BLOCKMANAGER_PORT="${SPARK_BLOCKMANAGER_PORT:-37078}"

if [ -z "${SPARK_DRIVER_HOST}" ]; then
  SPARK_DRIVER_HOST="$(hostname -i | awk '{print $1}')"
fi

echo "[spark-connect] driver_host=${SPARK_DRIVER_HOST}"
echo "[spark-connect] driver_bind_address=${SPARK_DRIVER_BIND_ADDRESS}"
echo "[spark-connect] driver_port=${SPARK_DRIVER_PORT}"
echo "[spark-connect] blockmanager_port=${SPARK_BLOCKMANAGER_PORT}"
SPARK_CONNECT_BIND_ADDRESS="${SPARK_CONNECT_BIND_ADDRESS:-0.0.0.0}"

HIVE_METASTORE_URIS="${HIVE_METASTORE_URIS:-thrift://hive-metastore.metastore.svc.cluster.local:9083}"
SPARK_WAREHOUSE_DIR="${SPARK_WAREHOUSE_DIR:-s3a://warehouse/}"
S3A_ENDPOINT="${S3A_ENDPOINT:-http://minio-svc-private.storage.svc.cluster.local:9000}"

AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-}"

SPARK_CONNECT_JAR="$(ls ${SPARK_HOME}/jars/spark-connect_*.jar 2>/dev/null | head -n 1 || true)"

echo "[spark-connect] SPARK_HOME=${SPARK_HOME}"
echo "[spark-connect] master=${SPARK_MASTER_URL}"
echo "[spark-connect] port=${SPARK_CONNECT_PORT}"
echo "[spark-connect] hive=${HIVE_METASTORE_URIS}"
echo "[spark-connect] warehouse=${SPARK_WAREHOUSE_DIR}"
echo "[spark-connect] s3a_endpoint=${S3A_ENDPOINT}"

if [ -z "${SPARK_CONNECT_JAR}" ]; then
  echo "[spark-connect] spark-connect jar not found in ${SPARK_HOME}/jars."
  echo "[spark-connect] Your Spark image must include Spark Connect server jar."
  echo "[spark-connect] If missing, rebuild your Spark image with spark-connect package for your Spark/Scala version."
  exit 1
fi

exec "${SPARK_HOME}/bin/spark-submit" \
  --class org.apache.spark.sql.connect.service.SparkConnectServer \
  --name spark-connect-shared-server \
  --master "${SPARK_MASTER_URL}" \
  --conf spark.scheduler.mode=FAIR \
  --conf spark.driver.host="${SPARK_DRIVER_HOST}" \
  --conf spark.driver.bindAddress="${SPARK_DRIVER_BIND_ADDRESS}" \
  --conf spark.driver.port="${SPARK_DRIVER_PORT}" \
  --conf spark.blockManager.port="${SPARK_BLOCKMANAGER_PORT}" \
  --conf spark.port.maxRetries=32 \
  --conf spark.scheduler.allocation.file=/opt/spark/conf/fairscheduler.xml \
  --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension \
  --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog \
  --conf spark.sql.catalogImplementation=hive \
  --conf spark.hadoop.hive.metastore.uris="${HIVE_METASTORE_URIS}" \
  --conf spark.sql.warehouse.dir="${SPARK_WAREHOUSE_DIR}" \
  --conf spark.hadoop.fs.s3a.endpoint="${S3A_ENDPOINT}" \
  --conf spark.hadoop.fs.s3a.access.key="${AWS_ACCESS_KEY_ID}" \
  --conf spark.hadoop.fs.s3a.secret.key="${AWS_SECRET_ACCESS_KEY}" \
  --conf spark.hadoop.fs.s3a.path.style.access=true \
  --conf spark.hadoop.fs.s3a.connection.ssl.enabled=false \
  --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
  --conf spark.eventLog.enabled="${SPARK_EVENT_LOG_ENABLED:-false}" \
  --conf spark.eventLog.dir="${SPARK_EVENT_LOG_DIR:-s3a://spark-event-logs/}" \
  --conf spark.connect.grpc.binding.address="${SPARK_CONNECT_BIND_ADDRESS}" \
  --conf spark.connect.grpc.binding.port="${SPARK_CONNECT_PORT}" \
  "${SPARK_CONNECT_JAR}"

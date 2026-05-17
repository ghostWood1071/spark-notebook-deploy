# JupyterHub + Shared Spark Cluster on Kubernetes

Mục tiêu:

- JupyterHub multi-user.
- Notebook chỉ là client/workspace.
- Spark compute chạy thành cluster riêng có thể bật/tắt/resize.
- User connect tới Spark cluster qua Spark Connect.
- Spark cluster dùng Standalone master/worker.
- Fair scheduler được bật trong Spark Connect server application.
- Data layer: Hive Metastore + Delta Lake + S3A/MinIO.

> Lưu ý quan trọng:
> - Notebook không còn làm Spark driver nặng.
> - Spark Connect server là driver/application kết nối tới Spark Standalone master.
> - Workers chạy executor.
> - Fair scheduler chia tài nguyên giữa jobs trong cùng SparkContext của Spark Connect server.
> - Việc gán pool per-user bằng Spark Connect client thuần còn hạn chế. Code này bật fair scheduler ở server và tạo sẵn pool. Nếu muốn ép pool theo user một cách chặt chẽ, nên thêm gateway/wrapper phía server.

## Cấu trúc

```text
jupyter-spark-shared-cluster/
├── .env.example
├── Makefile
├── README.md
├── k8s/
│   ├── 00-namespaces.yaml
│   ├── 01-jupyter-auth-secret.yaml
│   └── 02-spark-s3-secret.yaml
├── spark-cluster-image/
│   ├── Dockerfile
│   ├── conf/
│   │   └── fairscheduler.xml
│   └── scripts/
│       ├── start-master.sh
│       ├── start-worker.sh
│       └── start-connect.sh
├── jupyter-image/
│   ├── Dockerfile
│   └── platform_sdk.py
├── charts/
│   └── spark-shared-cluster/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-small.yaml
│       ├── values-medium.yaml
│       ├── values-large.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── configmap.yaml
│           ├── master.yaml
│           ├── worker.yaml
│           ├── connect.yaml
│           └── serviceaccount.yaml
├── helm/
│   └── jupyterhub-values.yaml
├── scripts/
│   ├── 00-prereq.sh
│   ├── 01-build-images.sh
│   ├── 02-install-jupyterhub.sh
│   ├── 03-cluster-up.sh
│   ├── 04-cluster-down.sh
│   └── 05-cluster-resize.sh
└── examples/
    └── notebook_bootstrap.py
```

## 0. Chỉnh `.env`

```bash
cp .env.example .env
vim .env
```

Các biến quan trọng:

```bash
SPARK_BASE_IMAGE=ghostwood/mbs-spark:1.0.7-protobuf
SPARK_CLUSTER_IMAGE=ghostwood/spark-shared-cluster:1.0.0
JUPYTER_IMAGE=ghostwood/spark-jupyter-client:1.0.0

SPARK_VERSION=3.5.3
PYSPARK_VERSION=3.5.3

JUPYTER_HOST=notebook.k8s.tailnet

HIVE_METASTORE_URIS=thrift://hive-metastore.metastore.svc.cluster.local:9083
S3A_ENDPOINT=http://minio-svc-private.storage.svc.cluster.local:9000
SPARK_WAREHOUSE_DIR=s3a://warehouse/
```

## 1. Tạo namespace + secrets

```bash
kubectl apply -f k8s/00-namespaces.yaml
kubectl apply -f k8s/01-jupyter-auth-secret.yaml
kubectl apply -f k8s/02-spark-s3-secret.yaml
```

Sửa password trong `k8s/01-jupyter-auth-secret.yaml` trước khi dùng thật.

## 2. Build images

```bash
bash scripts/01-build-images.sh
```

Nếu dùng cluster không pull được từ Docker Hub thì build rồi load image vào từng node.

## 3. Cài JupyterHub

```bash
bash scripts/02-install-jupyterhub.sh
```

Truy cập:

```text
http://notebook.k8s.tailnet
```

Login demo:

```text
admin / Admin@123456
user1 / User1@123456
user2 / User2@123456
```

## 4. Bật Spark cluster size medium

```bash
bash scripts/03-cluster-up.sh medium data-exp-medium
```

Cluster sẽ tạo:

```text
data-exp-medium-master
data-exp-medium-worker
data-exp-medium-connect
```

Spark Connect endpoint:

```text
sc://data-exp-medium-connect.compute.svc.cluster.local:15002
```

## 5. Notebook connect cluster

Trong Jupyter notebook:

```python
from platform_sdk import clusters, connect_cluster, enable_sql_magic

clusters()
spark = connect_cluster("medium")
enable_sql_magic(spark)
```

Test PySpark:

```python
df = spark.createDataFrame([(1, "Alice"), (2, "Bob")], ["id", "name"])
df.show()
```

Test Spark SQL:

```python
df.createOrReplaceTempView("people")
spark.sql("select * from people").show()
```

Test magic:

```sql
%%sql
select * from people
```

Test Delta/Hive:

```sql
%%sql
CREATE DATABASE IF NOT EXISTS demo
```

```sql
%%sql
CREATE TABLE IF NOT EXISTS demo.people (
  id BIGINT,
  name STRING
)
USING DELTA
```

```sql
%%sql
INSERT INTO demo.people VALUES (1, 'Alice'), (2, 'Bob')
```

```sql
%%sql
SELECT * FROM demo.people
```

## 6. Resize cluster

```bash
bash scripts/05-cluster-resize.sh data-exp-medium 4
```

Lệnh trên scale worker replicas lên 4.

## 7. Tắt cluster

```bash
bash scripts/04-cluster-down.sh data-exp-medium
```

## 8. Gợi ý production

Bản này là nền tảng chạy được cho lab/nội bộ. Production hơn thì nên bổ sung:

- OIDC/Keycloak thay cho simple password.
- HTTPS bằng cert-manager.
- NetworkPolicy.
- ResourceQuota theo namespace/team.
- MinIO policy theo user/team/prefix.
- Spark History Server + event log dir.
- Cluster Manager API để user bật/tắt/resize từ UI thay vì chạy script.

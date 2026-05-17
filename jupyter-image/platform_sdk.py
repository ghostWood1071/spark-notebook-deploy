import json
import os
from typing import Dict, Optional

from IPython.core.magic import register_cell_magic
from pyspark.sql import SparkSession


DEFAULT_CLUSTERS = {
    "small": {
        "endpoint": "sc://data-exp-small-connect.compute.svc.cluster.local:15002",
        "description": "1 worker, small data experiments"
    },
    "medium": {
        "endpoint": "sc://data-exp-medium-connect.compute.svc.cluster.local:15002",
        "description": "2 workers, default shared experiment cluster"
    },
    "large": {
        "endpoint": "sc://data-exp-large-connect.compute.svc.cluster.local:15002",
        "description": "4 workers, heavier experiments"
    }
}


def _load_clusters() -> Dict[str, Dict[str, str]]:
    raw = os.environ.get("SPARK_CLUSTERS_JSON")
    if not raw:
        return DEFAULT_CLUSTERS

    try:
        return json.loads(raw)
    except Exception as exc:
        raise RuntimeError(f"Invalid SPARK_CLUSTERS_JSON: {exc}") from exc


def clusters() -> Dict[str, Dict[str, str]]:
    data = _load_clusters()
    print("Available Spark clusters:")
    for name, item in data.items():
        print(f"- {name}: {item.get('endpoint')} | {item.get('description', '')}")
    return data


def connect_cluster(
    name: str = "medium",
    app_name: Optional[str] = None,
    shuffle_partitions: Optional[int] = 200,
):
    data = _load_clusters()

    if name not in data:
        raise ValueError(f"Unknown cluster '{name}'. Available: {list(data.keys())}")

    endpoint = data[name]["endpoint"]
    username = (
        os.environ.get("JUPYTERHUB_USER")
        or os.environ.get("USER")
        or "unknown-user"
    )

    final_app_name = app_name or f"notebook-{username}-{name}"

    builder = (
        SparkSession.builder
        .remote(endpoint)
        .appName(final_app_name)
    )

    spark = builder.getOrCreate()

    if shuffle_partitions is not None:
        spark.sql(f"SET spark.sql.shuffle.partitions={int(shuffle_partitions)}")

    print(f"Connected to Spark cluster: {name}")
    print(f"Endpoint: {endpoint}")
    print(f"App name: {final_app_name}")

    return spark


def enable_sql_magic(spark):
    @register_cell_magic
    def sql(line, cell):
        df = spark.sql(cell)
        show_rows = 100
        truncate = False

        tokens = line.strip().split()
        for token in tokens:
            if token.startswith("--rows="):
                show_rows = int(token.split("=", 1)[1])
            if token == "--truncate":
                truncate = True

        df.show(show_rows, truncate=truncate)
        return df

    print("Enabled %%sql magic. Example:")
    print("%%sql")
    print("SELECT current_timestamp()")


def safe_show(df, n: int = 20):
    return df.limit(n).show(n, truncate=False)

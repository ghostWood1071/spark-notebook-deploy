from platform_sdk import clusters, connect_cluster, enable_sql_magic

clusters()

spark = connect_cluster("medium", shuffle_partitions=200)
enable_sql_magic(spark)

print("Test:")
spark.sql("SELECT current_timestamp() AS now").show(truncate=False)

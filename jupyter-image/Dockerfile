ARG SPARK_BASE_IMAGE=ghostwood/spark-notebook:0.0.1
FROM ${SPARK_BASE_IMAGE}

USER root

ARG PYSPARK_VERSION=3.5.7

RUN set -eux; \
    if [ -d /opt/spark ]; then \
      echo "SPARK_HOME already /opt/spark"; \
    elif [ -d /usr/local/spark ]; then \
      ln -s /usr/local/spark /opt/spark; \
    else \
      echo "Cannot find Spark home. Expected /opt/spark or /usr/local/spark"; \
      exit 1; \
    fi

RUN pip install --no-cache-dir \
    jupyterhub \
    jupyterlab \
    notebook \
    ipykernel \
    pandas \
    pyarrow \
    matplotlib \
    "pyspark[connect]==${PYSPARK_VERSION}"

ENV SPARK_HOME=/opt/spark
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=python3
ENV PYTHONPATH="/opt/platform:${PYTHONPATH}"

COPY platform_sdk.py /opt/platform/platform_sdk.py

RUN mkdir -p /home/jovyan/work \
    && chmod -R 777 /home/jovyan /opt/platform

WORKDIR /home/jovyan/work

CMD ["jupyterhub-singleuser"]

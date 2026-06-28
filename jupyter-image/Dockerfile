FROM quay.io/jupyter/base-notebook:python-3.11

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    openjdk-17-jre-headless \
    && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

RUN pip install --no-cache-dir \
    jupyterhub \
    jupyterlab \
    notebook \
    ipykernel \
    pandas \
    pyarrow \
    matplotlib \
    grpcio \
    grpcio-status \
    googleapis-common-protos \
    "pyspark[connect]==3.5.7"

USER root

RUN mkdir -p /opt/platform

COPY platform_sdk.py /opt/platform/platform_sdk.py

RUN chmod -R 755 /opt/platform

ENV PYTHONPATH="/opt/platform:${PYTHONPATH}"
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

USER ${NB_UID}

WORKDIR /home/jovyan/work

CMD ["jupyterhub-singleuser"]
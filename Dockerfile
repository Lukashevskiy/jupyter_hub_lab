FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash \
      ca-certificates \
      curl \
      git \
      tini \
      nano \
      less \
      && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash jovyan && \
    mkdir -p /home/jovyan/work /opt/packages && \
    chown -R 1000:1000 /home/jovyan /opt/packages

RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel && \
    python3 -m pip install --no-cache-dir \
      jupyterhub==4.0.2 \
      jupyterlab==4.0.13 \
      notebook==7.0.8 \
      ipykernel \
      numpy \
      pandas \
      matplotlib \
      scikit-learn

USER jovyan
WORKDIR /home/jovyan/work

ENV PYTHONPATH="/opt/packages"

CMD ["jupyterhub-singleuser", "--ip=0.0.0.0", "--port=8888", "--ServerApp.default_url=/lab"]

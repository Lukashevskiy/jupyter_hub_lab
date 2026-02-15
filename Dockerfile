FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash \
      bash-completion \
      ca-certificates \
      curl \
      git \
      tini \
      nano \
      less \
      vim \
      tmux \
      htop \
      tree \
      procps \
      iproute2 \
      iputils-ping \
      net-tools \
      dnsutils \
      jq \
      rsync \
      zip \
      unzip \
      wget \
      file \
      lsof \
      strace \
      sudo \
      && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 -s /bin/bash jovyan && \
    mkdir -p /home/jovyan/work /opt/packages && \
    chown -R 1000:1000 /home/jovyan /opt/packages && \
    echo "jovyan ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jovyan && \
    chmod 0440 /etc/sudoers.d/jovyan

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

RUN printf '%s\n' \
  'export PS1="\\u@\\h:\\w\\$ "' \
  'export TERM=xterm-256color' \
  'alias ll="ls -alF"' \
  'alias la="ls -A"' \
  'alias l="ls -CF"' \
  'alias gs="git status"' \
  'alias ..="cd .."' \
  'if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi' \
  >> /home/jovyan/.bashrc

CMD ["jupyterhub-singleuser", "--ip=0.0.0.0", "--port=8888", "--ServerApp.default_url=/lab"]

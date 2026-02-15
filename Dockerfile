# Базовый образ с предустановленным PyTorch + CUDA 12.1
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV PYTHONUNBUFFERED=1

USER root

# Системные зависимости (без интерактивных запросов)
RUN apt-get update && \
    apt-get install -y --no-install-recommends tzdata nodejs npm && \
    ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    apt-get install -y --no-install-recommends \
        python3 python3-venv python3-dev python3-pip \
        build-essential cmake git curl wget gfortran \
        libopenblas-dev liblapack-dev libblas-dev \
        libgl1 libglib2.0-0 libsm6 libxext6 libxrender-dev libx11-dev \
        libjpeg-dev zlib1g-dev libpng-dev libtiff5-dev \
        sudo nano less vim htop \
        gcc g++ gdb valgrind strace ltrace \
        libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя и директорий
RUN useradd -m -u 1000 -G sudo jovyan && \
    echo "jovyan ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/notebook && \
    chmod 0440 /etc/sudoers.d/notebook

RUN mkdir -p /opt/venv/base /opt/packages/lib/python3.10/site-packages && \
    chown -R jovyan:jovyan /opt/venv /opt/packages /home/jovyan && \
    chmod -R 755 /opt/venv /opt/packages

ENV NB_USER=jovyan
ENV NB_UID=1000
ENV HOME=/home/${NB_USER}

USER jovyan
WORKDIR ${HOME}

# Виртуальное окружение и библиотеки
RUN python3 -m venv /opt/venv/base && \
    /opt/venv/base/bin/pip install --no-cache-dir --upgrade pip setuptools wheel

RUN /opt/venv/base/bin/pip install --no-cache-dir --default-timeout=100 \
    jupyterlab notebook ipywidgets ipykernel jupyter-server-proxy

RUN /opt/venv/base/bin/pip install --no-cache-dir --default-timeout=100 \
    pandas numpy scikit-learn scipy

RUN /opt/venv/base/bin/pip install --no-cache-dir --default-timeout=100 \
    matplotlib seaborn plotly bokeh opencv-python pillow

RUN /opt/venv/base/bin/pip install --no-cache-dir --default-timeout=100 \
    sentencepiece accelerate datasets evaluate transformers

RUN /opt/venv/base/bin/pip install --no-cache-dir --default-timeout=100 \
    requests tqdm ipython jinja2 pyyaml pydantic

# Ядра Jupyter
RUN /opt/venv/base/bin/python -m ipykernel install \
    --name=base-env \
    --display-name="Python (Base)" \
    --user

RUN python3 -m venv /opt/venv/algo && \
    /opt/venv/algo/bin/pip install --no-cache-dir ipykernel numpy && \
    /opt/venv/algo/bin/python -m ipykernel install \
    --name=algo-env \
    --display-name="Python (Algorithms)" \
    --user

# Переменные окружения
ENV VIRTUAL_ENV=/opt/venv/base
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"
ENV PYTHONPATH="/opt/packages/lib/python3.10/site-packages:${PYTHONPATH}"

RUN mkdir -p ${HOME}/work && \
    echo "export PYTHONPATH=\"/opt/packages/lib/python3.10/site-packages:\${PYTHONPATH}\"" >> ${HOME}/.bashrc && \
    echo "source ${VIRTUAL_ENV}/bin/activate" >> ${HOME}/.bashrc

WORKDIR ${HOME}/work

CMD ["jupyterhub-singleuser", "--ip=0.0.0.0", "--port=8888", "--NotebookApp.default_url=/lab"]
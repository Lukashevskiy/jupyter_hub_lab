# JupyterHub Lab (Docker + User Containers + GPU)

Этот проект поднимает JupyterHub в Docker и запускает отдельный контейнер для каждого пользователя.

Что реализовано:
- отдельный контейнер на пользователя через `DockerSpawner`
- отдельная рабочая папка каждого пользователя на хосте: `/srv/jupyterhub/home/<username>`
- общая папка Python-пакетов для всех пользователей: `/srv/jupyterhub/opt-packages`
- доступ к терминалу в JupyterLab
- поддержка GPU в user-контейнерах (через `nvidia-container-toolkit`)

## Структура

- `docker-compose.yml` — запуск Hub-контейнера
- `Dockerfile.hub` — образ Hub с `dockerspawner` и `nativeauthenticator`
- `Dockerfile` — образ single-user сервера (`jupyter-custom-gpu:latest`)
- `jupyterhub_config.py` — конфиг JupyterHub/Spawner
- `run.sh` — быстрый запуск

## Требования

На сервере должны быть установлены:
- Docker Engine + Docker Compose plugin
- NVIDIA driver
- NVIDIA Container Toolkit (если нужен GPU)

Проверки:

```bash
docker --version
docker compose version
nvidia-smi
docker run --rm --gpus all nvidia/cuda:12.1.1-runtime-ubuntu22.04 nvidia-smi
```

Если последняя команда падает, сначала чините GPU runtime в Docker.

## Первый запуск

Выполнить из папки проекта:

```bash
cd /home/dmitriyl/jupyter_hub_lab
```

### Вариант 1 (рекомендуется): через скрипт

```bash
./run.sh
```

Скрипт делает:
1. build user-образа `jupyter-custom-gpu:latest`
2. создание папок `/srv/jupyterhub/home` и `/srv/jupyterhub/opt-packages`
3. запуск `docker compose up -d --build`

### Вариант 2: вручную

```bash
cd /home/dmitriyl/jupyter_hub_lab

# 1) Собрать single-user образ
docker build -t jupyter-custom-gpu:latest -f Dockerfile .

# 2) Подготовить папки на хосте
sudo mkdir -p /srv/jupyterhub/home /srv/jupyterhub/opt-packages
sudo chmod 0777 /srv/jupyterhub/opt-packages

# 3) Поднять JupyterHub
docker compose up -d --build
```

Открыть в браузере:
- `http://<SERVER_IP>:8000`

## Проверка, что всё работает

### Проверка Hub

```bash
docker compose ps
docker compose logs --tail=200 jupyterhub
```

Ожидаемо: Hub запущен и слушает `:8000`.

### Проверка user-контейнера

1. Зарегистрируйте пользователя через UI (NativeAuthenticator) и войдите.
2. Нажмите старт сервера.
3. Проверьте контейнеры:

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

Должен появиться контейнер вида `jupyter-<username>` с образом `jupyter-custom-gpu:latest`.

### Проверка GPU в user-контейнере

```bash
docker exec -it jupyter-<username> python -c "import torch; print(torch.cuda.is_available())"
```

Ожидаемо: `True`.

## Как ставить Python-библиотеки “на лету” для всех

Общий путь пакетов настроен через:
- `PIP_TARGET=/opt/packages`
- `PYTHONPATH=/opt/packages:$PYTHONPATH`

То есть установка из терминала JupyterLab пользователя:

```bash
pip install <package>
```

попадёт в общую папку (`/srv/jupyterhub/opt-packages` на хосте) и станет доступна другим пользователям.

Проверка внутри user-контейнера:

```bash
python -c "import sys; print([p for p in sys.path if '/opt/packages' in p])"
```

## Полезные команды

Перезапуск Hub:

```bash
docker compose restart jupyterhub
```

Полный пересбор/перезапуск:

```bash
docker compose down
docker build -t jupyter-custom-gpu:latest -f Dockerfile .
docker compose up -d --build
```

Остановить всё:

```bash
docker compose down
```

## Частые проблемы и решения

### 1) `pull access denied for jupyter-custom-gpu`

Причина: локальный образ не собран.

Решение:

```bash
docker build -t jupyter-custom-gpu:latest -f Dockerfile .
docker compose up -d --build jupyterhub
```

### 2) `docker: command not found` (в WSL)

Причина: Docker Desktop WSL integration выключена.

Решение: включить интеграцию дистрибутива в Docker Desktop (`Settings -> Resources -> WSL Integration`).

### 3) Пользовательский сервер не стартует

Соберите диагностику:

```bash
docker compose logs --tail=300 jupyterhub
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
```

### 4) GPU недоступна внутри user-контейнера

Проверьте:
- установлен `nvidia-container-toolkit`
- `docker run --rm --gpus all nvidia/cuda:12.1.1-runtime-ubuntu22.04 nvidia-smi` работает
- user-контейнер действительно создан после логина

## Безопасность (минимум для учебного стенда)

Сейчас проект рассчитан на локальный/внутренний контур. Для продакшн-публикации обязательно:
- HTTPS через reverse-proxy (Nginx/Traefik/Caddy)
- ограничение signup (`open_signup=False`) или ручная модерация
- бэкап `/srv/jupyterhub` и `/srv/jupyterhub/home`
- регулярные обновления образов и зависимостей

## Быстрый чек-лист

1. `docker build -t jupyter-custom-gpu:latest -f Dockerfile .`
2. `docker compose up -d --build`
3. открыть `http://<IP>:8000`
4. зарегистрироваться и войти
5. убедиться, что появился `jupyter-<username>`
6. `torch.cuda.is_available()` внутри user-контейнера

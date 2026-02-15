import os
from pathlib import Path

import dockerspawner
from docker.types import DeviceRequest
from nativeauthenticator import NativeAuthenticator

c = get_config()

# Authentication
c.JupyterHub.authenticator_class = NativeAuthenticator
c.NativeAuthenticator.open_signup = True
c.NativeAuthenticator.enable_signup = True
c.NativeAuthenticator.minimum_password_length = 8
c.Authenticator.admin_users = {"notalive"}
c.Authenticator.allow_all = True

# Hub network
c.JupyterHub.bind_url = "http://:8000"
c.JupyterHub.hub_ip = "0.0.0.0"
c.JupyterHub.hub_connect_ip = "jupyterhub"

# Spawn Docker containers per user
c.JupyterHub.spawner_class = dockerspawner.DockerSpawner
c.DockerSpawner.image = "jupyter-custom-gpu:latest"
c.DockerSpawner.network_name = "jupyterhub-net"
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.remove = True
c.DockerSpawner.debug = True

# Spawn user server with JupyterLab + terminal
c.Spawner.default_url = "/lab"

# Shared/isolated storage
notebook_dir = "/home/jovyan/work"
host_home = Path("/srv/jupyterhub/home")
host_opt_packages = Path("/srv/jupyterhub/opt-packages")

c.DockerSpawner.notebook_dir = notebook_dir
c.DockerSpawner.volumes = {
    str(host_home / "{username}"): notebook_dir,
    str(host_opt_packages): "/opt/packages",
}

# GPU enablement for user containers (requires nvidia-container-toolkit on host)
c.DockerSpawner.extra_host_config = {
    "device_requests": [DeviceRequest(count=-1, capabilities=[["gpu"]])],
}

# Runtime env for shared package directory
c.Spawner.environment = {
    "PYTHONPATH": "/opt/packages:${PYTHONPATH}",
    "PIP_TARGET": "/opt/packages",
    "PIP_DISABLE_PIP_VERSION_CHECK": "1",
}


def pre_spawn_hook(spawner):
    username = spawner.user.name
    user_home = host_home / username
    user_home.mkdir(parents=True, exist_ok=True)

    host_opt_packages.mkdir(parents=True, exist_ok=True)

    # Ensure singleuser container user (uid=1000) can write to mounted folders.
    os.chown(user_home, 1000, 1000)
    os.chmod(user_home, 0o775)
    os.chmod(host_opt_packages, 0o777)


c.Spawner.pre_spawn_hook = pre_spawn_hook

# Timeouts
c.Spawner.start_timeout = 300
c.Spawner.http_timeout = 120

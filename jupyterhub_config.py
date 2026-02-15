import os
import subprocess
import dockerspawner
from nativeauthenticator import NativeAuthenticator

# Аутентификация
c.JupyterHub.authenticator_class = NativeAuthenticator
c.NativeAuthenticator.open_signup = True
c.NativeAuthenticator.enable_signup = True
c.Authenticator.admin_users = {'notalive'}
c.Authenticator.allow_all = True
c.NativeAuthenticator.minimum_password_length = 8

# Сетевая связность
c.JupyterHub.hub_connect_ip = 'jupyterhub'
c.JupyterHub.hub_connect_port = 8081

# Спавнер
c.JupyterHub.spawner_class = dockerspawner.DockerSpawner
c.DockerSpawner.image = 'jupyter-custom-gpu:latest'  # ← ваш кастомный образ
c.DockerSpawner.network_name = 'jupyterhub-net'

# Volumes
notebook_dir = '/home/jovyan/work'
host_home = '/srv/jupyterhub/home'
host_opt_packages = '/srv/jupyterhub/opt-packages'

c.DockerSpawner.notebook_dir = notebook_dir
c.DockerSpawner.volumes = {
    f'{host_home}/{{username}}': notebook_dir,
    host_opt_packages: '/opt/packages',
}

# Pre-spawn hook для создания директорий
def pre_spawn_hook(spawner):
    username = spawner.user.name
    host_path = os.path.join(host_home, username)
    if not os.path.exists(host_path):
        os.makedirs(host_path, exist_ok=True)
        spawner.log.info(f"✓ Created home directory: {host_path}")
    try:
        subprocess.check_call(['chown', '-R', '1000:100', host_path])
        spawner.log.info(f"✓ Set ownership 1000:100 on {host_path}")
    except Exception as e:
        spawner.log.error(f"✗ Failed to set ownership on {host_path}: {e}")

c.Spawner.pre_spawn_hook = pre_spawn_hook

# Post-start для прав на /opt/packages
c.DockerSpawner.post_start_cmd = """
bash -c '
  chown -R jovyan:jovyan /opt/packages 2>/dev/null || true
  mkdir -p /opt/packages/lib/python3.10/site-packages
  echo "✓ /opt/packages ready"
'
"""

# Таймауты
c.DockerSpawner.start_timeout = 300
c.DockerSpawner.http_timeout = 120
c.DockerSpawner.poll_interval = 1
c.DockerSpawner.remove = True
c.DockerSpawner.pull_policy = 'ifnotpresent'

# Порт
c.JupyterHub.bind_url = 'http://:8000'
# Configure DockerCompose Containers as system services

Im running on a Ubuntu/Manjaro and have installed Docker from the official repository.

Then to make it simple, I’m using systemd to automatically run my containers when the server boots up /etc/systemd/system/docker-compose@.service :

```ini
[Unit]
Description=%i service with docker compose
Requires=docker.service
After=docker.service

[Service]
Restart=always
# The directory where your compose config files are stored
WorkingDirectory=/etc/docker/compose/%i

# Remove old containers, images and volumes
ExecStartPre=/usr/bin/docker-compose down -v
ExecStartPre=/usr/bin/docker-compose rm -fv
ExecStartPre=-/bin/bash -c 'docker volume ls -qf "name=%i_" | xargs docker volume rm'
ExecStartPre=-/bin/bash -c 'docker network ls -qf "name=%i_" | xargs docker network rm'
ExecStartPre=-/bin/bash -c 'docker ps -aqf "name=%i_*" | xargs docker rm'

# Compose up
ExecStart=/usr/bin/docker-compose up

# Compose down, remove containers and volumes
ExecStop=/usr/bin/docker-compose down -v

[Install]
WantedBy=multi-user.target
```

You can add a Docker compose configuration file (docker-compose.yml) and start it:

```sh
systemctl enable docker-compose@myservice
systemctl start docker-compose@myservice
```

This makes container configuration very simple and easily manageable.

---
doc_id: ops/tandoor/other
chunk_id: ops/tandoor/other#chunk-3
heading_path: ["Other", "Docker + Apache + Sub-Path"]
chunk_type: code
tokens: 535
summary: "Docker + Apache + Sub-Path"
---

## Docker + Apache + Sub-Path

The following could prove to be useful if you are not using Traefik, but instead run Apache as your reverse proxy to route all calls for a shared (sub)domain to a sub path, e.g. https://mydomain.tld/tandoor

As a side note, I am using [Blocky](https://0xerr0r.github.io/blocky/) + [Consul](https://hub.docker.com/r/hashicorp/consul) + [Registrator](https://hub.docker.com/r/gliderlabs/registrator) as a DNS solution.

The relevant Apache config:
```html
    <Location /tandoor>
        # in case you want to restrict access to specific IP addresses:
        Require local
        Require forward-dns [myhomedomain.useyourdomain.com]
        Require ip [anylocalorremoteipyouwanttowhitelist]

        # The following assumes that tandoor.service.consul.local resolves to the IP address of the Docker container.
        ProxyPass http://tandoor.service.consul.local:8080/tandoor
        ProxyPassReverse http://tandoor.service.consul.local:8080/tandoor
        RequestHeader add X-Script-Name /tandoor
        RequestHeader set X-Forwarded-Proto "https"
        ProxyPreserveHost On
    </Location>
    <Location /tandoor/static>
        Require local
        Require forward-dns [myhomedomain.useyourdomain.com]
        Require ip [anylocalorremoteipyouwanttowhitelist]

        ProxyPass http://tandoor.service.consul.local:8080/tandoor/tandoor/static
        ProxyPassReverse http://tandoor.service.consul.local:8080/tandoor/static
        RequestHeader add X-Script-Name /tandoor
        RequestHeader set X-Forwarded-Proto "https"
        ProxyPreserveHost On
    </Location>
```text
and the relevant section from the docker-compose.yml:
```yaml
   tandoor:
     restart: always
     container_name: tandoor
     image: vabene1111/recipes
     environment:
       - SCRIPT_NAME=/tandoor
       - STATIC_URL=/tandoor/static/
       - MEDIA_URL=/tandoor/media/
       - GUNICORN_MEDIA=0
       - SECRET_KEY=${YOUR_TANDOOR_SECRET_KEY}
       - POSTGRES_HOST=postgres.service.consul.local
       - POSTGRES_PORT=${POSTGRES_PORT}
       - POSTGRES_USER=${YOUR_TANDOOR_POSTGRES_USER}
       - POSTGRES_PASSWORD=${YOUR_TANDOOR_POSTGRES_PASSWORD}
       - POSTGRES_DB=${YOUR_TANDOOR_POSTGRES_DB}
     labels:
        # The following is relevant only if you are using Registrator and Consul
       - "SERVICE_NAME=tandoor"
     volumes:
       - ${YOUR_DOCKER_VOLUME_BASE_DIR}/tandoor/static:/opt/recipes/staticfiles:rw
       # Do not make this a bind mount, see https://docs.tandoor.dev/install/docker/#volumes- vs-bind-mounts
       - tandoor_nginx_config:/opt/recipes/nginx/conf.d
       - ${YOUR_DOCKER_VOLUME_BASE_DIR}}/tandoor/media:/opt/recipes/mediafiles:rw
     depends_on:
        # You will have to set up postgres accordingly
       - postgres
```text

The relevant docker-compose.yml for Registrator, Consul, and Blocky, and Autoheal:
```yaml
  consul:
    image: hashicorp/consul
    container_name: consul
    command: >
      agent -server
      -domain consul.local
      -advertise=${YOUR_DOCKER_HOST_IP_ON_THE_LAN}
      -client=0.0.0.0
      -encrypt=${SOME_SECRET_KEY}
      -datacenter=${YOUR_DC_NAME}
      -bootstrap-expect=1
      -ui
      -log-level=info
    environment:
      - "CONSUL_LOCAL_CONFIG={\"skip_leave_on_interrupt\": true, \"dns_config\": { \"service_ttl\": { \"*\": \"0s\" } } }"
    network_mode: "host"
    restart: always

  registrator:
    image: gliderlabs/registrator:latest
    container_name: registrator
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
    command: >
      -internal
      -cleanup=true
      -deregister="always"
      -resync=60
      consul://host.docker.internal:8500
    restart: always

  blocky:
    image: spx01/blocky
    container_name: blocky
    restart: unless-stopped
    healthcheck:
      interval: 30s
      timeout: 5s
      start_period: 1m
    labels:
        # The following is only relevant if you use autoheal
      autoheal: true
    # Optional the instance hostname for logging purpose
    hostname: blocky
    extra_hosts:
      - "host.docker.internal:host-gateway"
    ports:
      - "1153:53/tcp"
      - "1153:53/udp"
      - 4000:4000
    environment:
      - TZ=YOUR_TIMEZONE # Optional to synchronize the log timestamp with host
    volumes:
      # Optional to synchronize the log timestamp with host
      - /etc/localtime:/etc/localtime:ro
      # config file
      - ${YOUR_DOCKER_VOLUME_BASE_DIR}/blocky/config.yml:/app/config.yml
    networks:
        # in case you want to bind Blocky to an IP address
      your-docker-network-name:
        ipv4_address: 'some-ip-address-in-the-docker-network-subnet'

  autoheal:
    image: willfarrell/autoheal
    volumes:
        - '/var/run/docker.sock:/var/run/docker.sock'
    environment:
        - AUTOHEAL_CONTAINER_LABEL=autoheal
    restart: always
    container_name: autoheal

```text
as well as a snippet of the Blocky configuration:
```yaml
conditional:
  fallbackUpstream: false
  mapping:
    consul.local: tcp+udp:host.docker.internal:8600
```

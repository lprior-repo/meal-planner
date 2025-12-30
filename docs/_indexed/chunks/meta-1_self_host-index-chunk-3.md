---
doc_id: meta/1_self_host/index
chunk_id: meta/1_self_host/index#chunk-3
heading_path: ["Self-host", "Docker"]
chunk_type: code
tokens: 2143
summary: "Docker"
---

## Docker

### Setup Windmill on localhost

Self-host Windmill in less than a minute:

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/NQP2A8RGyoo"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

Using [Docker](https://www.docker.com/) and [Caddy](https://caddyserver.com/), Windmill can be deployed using 3 files:
([`docker-compose.yml`][windmill-docker-compose], [`Caddyfile`][windmill-caddyfile]) and a [.env][windmill-env] in a single command.

[Caddy][caddy] is the reverse proxy that will redirect traffic to both Windmill (port 8000) and the LSP (the monaco assistant) service (port 3001) and multiplayer service (port 3002).
It also redirects TCP traffic on port 25 to Windmill (port 2525) for [email triggers](./meta-17_email_triggers-index.md).
Postgres holds the entire state of Windmill, the rest is fully stateless, Windmill-LSP provides editor intellisense.

Make sure Docker is started:

- Mac: `open /Applications/Docker.app`
- Windows: `start docker`
- Linux: `sudo systemctl start docker`

and type the following commands:

```
curl https://raw.githubusercontent.com/windmill-labs/windmill/main/docker-compose.yml -o docker-compose.yml
curl https://raw.githubusercontent.com/windmill-labs/windmill/main/Caddyfile -o Caddyfile
curl https://raw.githubusercontent.com/windmill-labs/windmill/main/.env -o .env

docker compose up -d
```

Go to [http://localhost](http://localhost) et voilà. Then you can [login for the first time](#first-time-login).

### Use an external database

For more production use-cases, we recommend using the [Helm-chart](#helm-chart). However, the docker-compose on a big instance is sufficient for many use-cases.

To setup an external database, you need to set DATABASE_URL in the .env file to point your external database. You should also set the number of db replicas to 0.

:::tip

In setups where you do not have access to the PG superuser (Azure PostgreSQL, GCP Postgresql, etc), you will need to set the initial role manually. You can do so by running the following command:

```bash
curl https://raw.githubusercontent.com/windmill-labs/windmill/main/init-db-as-superuser.sql -o init-db-as-superuser.sql
psql <DATABASE_URL> -f init-db-as-superuser.sql
```

Make sure that the user used in the DATABASE_URL passed to Windmill has the role `windmill_admin` and `windmill_user`:

```sql
GRANT windmill_admin TO <user used in database_url>;
GRANT windmill_user TO <user used in database_url>;
```

:::

### Set number of replicas accordingly in docker-compose

In the docker-compose, set the number of windmill_worker and windmill_worker_native replicas to your needs.

### Enterprise Edition

To use the [Enterprise Edition](/pricing), you need pass the license key in the [instance settings](./meta-18_instance_settings-index.md#license-key). A same license key can be used for multiple instances (for dev instances make sure to turn on the 'Non-prod instance' flag from the [instance settings](./meta-18_instance_settings-index.md#non-prod-instance)).

You can then set the number of replicas of the multiplayer container to 1 in the docker-compose.

You will be provided a license key when you purchase the enterprise edition or start a trial. Start a trial from the [Pricing](/pricing) page or contact us at contact@windmill.dev to get a trial license key. You will benefit from support, SLA and all the [additional features](/pricing) of the enterprise edition.

<iframe
	style={{ aspectRatio: '16/9' }}
	src="https://www.youtube.com/embed/YAoLXwayjT8"
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	allowFullScreen
	className="border-2 rounded-lg object-cover w-full dark:border-gray-800"
></iframe>

<br />

More details at:

<div className="grid grid-cols-2 gap-6 mb-4">
	<DocCard
		title="Upgrade to Enterprise Edition"
		description="Docs on how to upgrade to the Enterprise Edition of a Self-Hosted Windmill instance."
		href="/docs/misc/plans_details#self-host"
	/>
</div>

### Security considerations

The official Windmill docker-compose enables PID namespace isolation by default:

- **PID namespace isolation** (`ENABLE_UNSHARE_PID=true`) prevents jobs from accessing parent worker process memory and environment variables

For additional security, you can enable NSJAIL sandboxing:

- **NSJAIL sandboxing** - Provides filesystem and resource isolation (requires using a `-nsjail` tagged image and setting `DISABLE_NSJAIL=false`)

#### Windows workers

If you're running Windows workers, PID namespace isolation is Linux-only. Set `ENABLE_UNSHARE_PID=false` for Windows worker services:

```yaml
windmill_worker_windows:
  environment:
    - ENABLE_UNSHARE_PID=false
```

For complete security documentation, see [Security and Process Isolation](/docs/advanced/security_isolation).

### Configuring domain and reverse proxy

To deploy Windmill to the `windmill.example.com` domain, make sure to set "Base Url" correctly in the [Instance settings](./meta-18_instance_settings-index.md#base-url).

You can use any reverse proxy as long as they behave mostly like the default provided following caddy configuration:

```
:80 {
        bind {$ADDRESS}
        reverse_proxy /ws/* http://lsp:3001
        reverse_proxy /* http://windmill_server:8000
}
```

The default docker-compose file exposes the caddy reverse-proxy on port 80 above, configured by the [caddyfile](https://raw.githubusercontent.com/windmill-labs/windmill/main/Caddyfile) curled above. Configure both the caddyfile and the docker-compose file to fit your needs. The documentation for caddy is available [here](https://caddyserver.com/docs/caddyfile).

#### Use provided Caddy to serve https

For simplicity, we recommend using an external reverse proxy such as Cloudfront or Cloudflare and point to your instance on the port you have chosen (by default, :80).

However, Caddy also supports HTTPS natively via its [tls](https://caddyserver.com/docs/caddyfile/directives/tls) directive. Multiple options are available. Caddy can obtain certificates automatically using the ACME protocol, a provided CA file, or even a custom HTTP endpoint. The simplest is to provide your own certifcate and key files. You can do so by mounting an additional volume containing those two files to the Caddy container and adding a `tls /path/to/cert.pem /path/to/key.pem` directive to the Caddy file. Make sure to expose the port `:443` instead of `:80` and Caddy will take care of the rest.

For all the above, see the commented lines in the caddy section of the docker-compose.

#### Traefik configuration

<details>
  <summary>Here is a template of a docker-compose to expose Windmill to Traefik. Make sure to replace the `traefik` network with whatever network you have it running on. Code below:</summary>

You may need to adapt this depending on if you have Traefik running or on your configuration. This also assumes you have a `letsencryptresolver` or change the name to your certificate resolver if you want to use the `websecure` entrypoint.

```yaml
version: '3.7'

services:
  db:
    deploy:
      # To use an external database, set replicas to 0 and set DATABASE_URL to the external database url in the .env file
      replicas: 1
    image: postgres:14
    restart: unless-stopped
    volumes:
      - db_data:/var/lib/postgresql/data
    expose:
      - 5432
    networks:
      - windmill
    ports:
      - 5432:5432
    environment:
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: windmill
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 10s
      timeout: 5s
      retries: 5

  windmill_server:
    image: ${WM_IMAGE}
    pull_policy: always
    deploy:
      replicas: 1
    restart: unless-stopped
    expose:
      - 8000
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - MODE=server
    networks:
      - windmill
      - traefik
    depends_on:
      db:
        condition: service_healthy
    labels:
      - traefik.enable=true
      - traefik.http.services.windmill_server.loadbalancer.server.port=8000
      #http
      - traefik.http.routers.windmill_server_http.entrypoints=web
      - traefik.http.routers.windmill_server_http.rule=Host(`windmill.yourdomain.com`)
      - traefik.http.routers.windmill_server_http.service=windmill_server
      # https
      - traefik.http.routers.windmill_server_https.entrypoints=websecure
      - traefik.http.routers.windmill_server_https.rule=Host(`windmill.yourdomain.com`)
      - traefik.http.routers.windmill_server_https.service=windmill_server
      - traefik.http.routers.windmill_server_https.tls=true
      - traefik.http.routers.windmill_server_https.tls.certresolver=letsencryptresolver

  windmill_worker:
    image: ${WM_IMAGE}
    pull_policy: always
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1'
          memory: 2048M
        # for GB, use syntax '2Gi'
    restart: unless-stopped
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - MODE=worker
      - WORKER_GROUP=default
    networks:
      - windmill
    depends_on:
      db:
        condition: service_healthy
    # to mount the worker folder to debug, KEEP_JOB_DIR=true and mount /tmp/windmill
    volumes:
      # mount the docker socket to allow to run docker containers from within the workers
      - /var/run/docker.sock:/var/run/docker.sock
      - worker_dependency_cache:/tmp/windmill/cache

  ## This worker is specialized for "native" jobs. Native jobs run in-process and thus are much more lightweight than other jobs
  windmill_worker_native:
    # Use ghcr.io/windmill-labs/windmill-ee:main for the ee
    image: ${WM_IMAGE}
    pull_policy: always
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.1'
          memory: 128M
    restart: unless-stopped
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - MODE=worker
      - WORKER_GROUP=native
    networks:
      - windmill
    depends_on:
      db:
        condition: service_healthy

  ## This worker is specialized for reports or scraping jobs. It is assigned the "reports" worker group which has an init script that installs chromium and can be targeted by using the "chromium" worker tag.
  #  windmill_worker_reports:
  #    image: ${WM_IMAGE}
  #    pull_policy: always
  #    deploy:
  #      replicas: 1
  #      resources:
  #        limits:
  #          cpus: "1"
  #          memory: 2048M
  #    restart: unless-stopped
  #    environment:
  #      - DATABASE_URL=${DATABASE_URL}
  #      - MODE=worker
  #      - WORKER_GROUP=reports
  #    networks:
  #      - windmill
  #    depends_on:
  #      db:
  #        condition: service_healthy
  #    # to mount the worker folder to debug, KEEP_JOB_DIR=true and mount /tmp/windmill
  #    volumes:
  #      # mount the docker socket to allow to run docker containers from within the workers
  #      - /var/run/docker.sock:/var/run/docker.sock
  #      - worker_dependency_cache:/tmp/windmill/cache

  lsp:
    image: ghcr.io/windmill-labs/windmill-lsp:latest
    pull_policy: always
    restart: unless-stopped
    networks:
      - windmill
      - traefik
    expose:
      - 3001
    volumes:
      - lsp_cache:/root/.cache
    labels:
      - traefik.enable=true
      - traefik.http.services.windmill_lsp.loadbalancer.server.port=3001
      #http
      - traefik.http.routers.windmill_lsp_http.entrypoints=web
      - traefik.http.routers.windmill_lsp_http.rule=Host(`windmill.yourdomain.com`) && PathPrefix(`/ws/`)
      - traefik.http.routers.windmill_lsp_http.service=windmill_lsp
      # https
      - traefik.http.routers.windmill_lsp_https.entrypoints=websecure
      - traefik.http.routers.windmill_lsp_https.rule=Host(`windmill.yourdomain.com`) && PathPrefix(`/ws/`)
      - traefik.http.routers.windmill_lsp_https.service=windmill_lsp
      - traefik.http.routers.windmill_lsp_https.tls=true
      - traefik.http.routers.windmill_lsp_https.tls.certresolver=letsencryptresolver

  multiplayer:
    image: ghcr.io/windmill-labs/windmill-multiplayer:latest
    deploy:
      replicas: 0 # Set to 1 to enable multiplayer, only available on Enterprise Edition
    restart: unless-stopped
    networks:
      - windmill
    expose:
      - 3002

volumes:
  db_data: null
  worker_dependency_cache: null
  lsp_cache: null

networks:
  windmill:
    name: windmill
  traefik:
    name: traefik
    external: true
```

</details>

### Deployment

Once you have setup your environment for deployment, you can run the following
command:

```bash
docker compose up
```

That's it! Head over to your domain and you should be greeted with the login
screen.

In practice, you want to run the Docker containers in the background so they don't shut down when you disconnect. Do this with the `--detach` or `-d` parameter as follows:

```bash
docker compose up -d
```

### Set up limits for workers and memory

From your docker-compose, you can set limits for consumption of [workers](https://github.com/windmill-labs/windmill/blob/main/docker-compose.yml#L51) and [memory](https://github.com/windmill-labs/windmill/blob/main/docker-compose.yml#L52):

```yaml
windmill_worker:
  image: ${WM_IMAGE}
  pull_policy: always
  deploy:
    replicas: 3
    resources:
      limits:
        cpus: "1"
        memory: 2048M
```

It is useful on [Enterprise Edition](/pricing) to avoid exceeding the terms of your subscription.

### Update

To update to a newer version of Windmill, all you have to do is run:

```bash
docker compose stop windmill_worker
docker compose pull windmill_server
docker compose up -d
```

Database volume is persistent, so updating the database image is safe too. Windmill provides graceful exit for jobs in workers so it will not interrupt current jobs unless they are longer than docker stop hard kill timeout (30 seconds).

It is sufficient to run `docker compose up -d` again if your Docker is already running detached, since it will pull the latest `:main` version and restart the containers.
NOTE: The previous images are not removed automatically, you should also run `docker builder prune` to clear old versions.

### Reset your instance

Windmill stores all of its state in PostgreSQL and it is enough to reset the database to reset the instance.
Hence, in the setup above, to reset your Windmill instance, it is enough to reset the PostgreSQL volumes. Run:

```
docker compose down --volumes
docker volume rm -f windmill_db_data
```

and then:

```
docker compose up -d
```

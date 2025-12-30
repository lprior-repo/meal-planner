---
doc_id: ops/install/docker
chunk_id: ops/install/docker#chunk-4
heading_path: ["Docker", "**Docker Compose**"]
chunk_type: code
tokens: 404
summary: "**Docker Compose**"
---

## **Docker Compose**

The main, and also recommended, installation option for this application is Docker Compose.

1. Choose your `docker-compose.yml` from the examples below.
2. Download the `.env` configuration file with `wget`
    ```shell
    wget https://raw.githubusercontent.com/vabene1111/recipes/develop/.env.template -O .env
    ```text
3. **Edit it accordingly** (you NEED to set `SECRET_KEY` and `POSTGRES_PASSWORD`), see [configuration page](https://docs.tandoor.dev/system/configuration/).
4. Start your container using `docker-compose up -d`.

### **Plain**

This configuration exposes the application through a containerized nginx web server on port 80 of your machine.
Be aware that having some other web server or container running on your host machine on port 80 will block this from working.

```shell
wget https://raw.githubusercontent.com/vabene1111/recipes/develop/docs/install/docker/plain/docker-compose.yml
```text

~~~yaml
{% include "./docker/plain/docker-compose.yml" %}
~~~

### **Reverse Proxy**

Most deployments will likely use a reverse proxy.

#### **Traefik**

If you use Traefik, this configuration is the one for you.

!!! info
    Traefik can be a little confusing to setup.
    Please refer to [their excellent documentation](https://doc.traefik.io/traefik/). If that does not help,
    [this little example](traefik.md) might be for you.

```shell
wget https://raw.githubusercontent.com/vabene1111/recipes/develop/docs/install/docker/traefik-nginx/docker-compose.yml
```text

~~~yaml
{% include "./docker/traefik-nginx/docker-compose.yml" %}
~~~


#### **jwilder's Nginx-proxy**

This is a docker compose example using [jwilder's nginx reverse proxy](https://github.com/jwilder/docker-gen)
in combination with [jrcs's letsencrypt companion](https://hub.docker.com/r/jrcs/letsencrypt-nginx-proxy-companion/).

Please refer to the appropriate documentation on how to setup the reverse proxy and networks.

!!! warning "Adjust client_max_body_size"
    By using jwilder's Nginx-proxy, uploads will be restricted to 1 MB file size. This can be resolved by adjusting the ```client_max_body_size``` variable in the jwilder nginx configuration.

Remember to add the appropriate environment variables to the `.env` file:

```bash
VIRTUAL_HOST=
LETSENCRYPT_HOST=
LETSENCRYPT_EMAIL=
```

```shell
wget https://raw.githubusercontent.com/vabene1111/recipes/develop/docs/install/docker/nginx-proxy/docker-compose.yml
```text

~~~yaml
{% include "./docker/nginx-proxy/docker-compose.yml" %}
~~~


#### **Apache proxy**

If you use Apache as a reverse proxy, this configuration is the one for you.

~~~yaml
{% include "./docker/apache-proxy/docker-compose.yml" %}
~~~

Keep in mind, that the port configured for the service `web_recipes` should be the same as in chapter [Required Headers: Apache](#apache).

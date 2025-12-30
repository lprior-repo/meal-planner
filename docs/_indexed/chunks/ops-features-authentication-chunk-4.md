---
doc_id: ops/features/authentication
chunk_id: ops/features/authentication#chunk-4
heading_path: ["Authentication", "External Authentication"]
chunk_type: code
tokens: 490
summary: "External Authentication"
---

## External Authentication

<!-- prettier-ignore -->
!!! warning "Security Impact"
    If you just set `REMOTE_USER_AUTH=1` without any additional configuration, _anybody_ can authenticate with _any_ username!

<!-- prettier-ignore -->
!!! Info "Community Contributed Tutorial"
    This tutorial was provided by a community member. We are not able to provide any support! Please only use, if you know what you are doing!

In order use external authentication (i.e. using a proxy auth like Authelia, Authentik, etc.) you will need to:

1. Set `REMOTE_USER_AUTH=1` in the `.env` file
2. Update your nginx configuration file

Using any of the examples above will automatically generate a configuration file inside a docker volume.
Use `docker volume inspect recipes_nginx` to find out where your volume is stored.

<!-- prettier-ignore -->
!!! warning "Configuration File Volume"
    The nginx config volume is generated when the container is first run. You can change the volume to a bind mount in the
    `docker-compose.yml`, but then you will need to manually create it. See section `Volumes vs Bind Mounts` below
    for more information.

### Configuration Example for Authelia

```
server {
  listen 80;
  server_name localhost;

  client_max_body_size 16M;

  # serve static files
  location /static/ {
    alias /static/;
  }
  # serve media files
  location /media/ {
    alias /media/;
  }

  # Authelia endpoint for authentication requests
  include /config/nginx/auth.conf;

  # pass requests for dynamic content to gunicorn
  location / {
    proxy_set_header Host $host;
    proxy_pass http://web_recipes:8080;

    # Ensure Authelia is specifically required for this endpoint
    # This line is important as it will return a 401 error if the user doesn't have access
    include /config/nginx/authelia.conf;

    auth_request_set $user $upstream_http_remote_user;
    proxy_set_header REMOTE-USER $user;
  }

  # Required to allow user to logout of authentication from within Recipes
  # Ensure the <auth_endpoint> below is changed to actual the authentication url
  location /accounts/logout/ {
    return 301 http://<auth_endpoint>/logout;
  }
}
```

Please refer to the appropriate documentation on how to set up the reverse proxy, authentication, and networks.

Ensure users have been configured for Authelia, and that the endpoint recipes is pointed to is protected but
available.

There is a good guide to the other additional files that need to be added to your nginx set up at
the [Authelia Docs](https://docs.authelia.com/deployment/supported-proxies/nginx.html).

Remember to add the appropriate environment variables to `.env` file (example for nginx proxy):

```
VIRTUAL_HOST=
LETSENCRYPT_HOST=
LETSENCRYPT_EMAIL=
PROXY_HEADER=
```

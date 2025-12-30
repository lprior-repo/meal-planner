---
doc_id: ops/install/docker
chunk_id: ops/install/docker#chunk-6
heading_path: ["Docker", "**Additional Information**"]
chunk_type: code
tokens: 668
summary: "**Additional Information**"
---

## **Additional Information**

### **Nginx Config**
Starting with Tandoor 2 the Docker container includes a nginx service. Its default configuration is pulled from the [http.d](https://github.com/TandoorRecipes/recipes/tree/develop/http.d) folder
in the repository. 

You can setup a volume to link to the ```/opt/recipes/http.d``` folder inside your container to change the configuration. Keep in mind that you will not receive any updates on the configuration 
if you manually change it/bind the folder as a volume. 


### **Required Headers**

Please be sure to supply all required headers in your nginx/Apache/Caddy/... configuration!

#### **nginx**

```nginx
location / {
    proxy_set_header Host $http_host; # try $host instead if this doesn't work
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://127.0.0.1:8080; # replace port
    proxy_redirect http://127.0.0.1:8080 https://recipes.domain.tld; # replace port and domain
}
```text

#### **Apache**

```apache
RequestHeader set X-Forwarded-Proto "https"
Header always set Access-Control-Allow-Origin "*"

ProxyPreserveHost  On
ProxyRequests Off
ProxyPass / http://localhost:8080/ # replace port
ProxyPassReverse / http://localhost:8080/ # replace port
```text

### **Setup issues on Raspberry Pi**

!!! danger
    Tandoor 2 does no longer build images for arm/v7 architectures. You can certainly get Tandoor working there but it has simply been to much effort to maintain these architectures over the past years
    to justify the continued support of this mostly deprecated platform. 

!!!info
    Always wait at least 2-3 minutes after the very first start, since migrations will take some time!


If you're having issues with installing Tandoor on your Raspberry Pi or similar device,
follow these instructions:

- Stop all Tandoor containers (`docker-compose down`)
- Delete local database folder (usually 'postgresql' in the same folder as your 'docker-compose.yml' file)
- Start Tandoor containers again (`docker-compose up -d`)
- Wait for at least 2-3 minutes and then check if everything is working now (migrations can take quite some time!)
- If not, check logs of the web_recipes container with `docker logs <container_name>` and make sure that all migrations are indeed already done

### Sub Path nginx config

If hosting under a sub-path you might want to change the default nginx config
with the following config.

```nginx
location /my_app { # change to subfolder name
    include /config/nginx/proxy.conf;
    proxy_pass https://mywebapp.com/; # change to your host name:port
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Script-Name /my_app; # change to subfolder name
    proxy_cookie_path / /my_app; # change to subfolder name
}

location /media/ {
    include /config/nginx/proxy.conf;
    alias /mediafiles/;
    client_max_body_size 16M;

}

location /static/ {
    include /config/nginx/proxy.conf;
    alias /staticfiles/;
    client_max_body_size 16M;

}
```
### Tandoor 1 vs Tandoor 2
Tandoor 1 includes gunicorn, a python WSGI server that handles python code well but is not meant to serve mediafiles. Thus, it has always been recommended to set up a nginx webserver 
(not just a reverse proxy) in front of Tandoor to handle mediafiles. The gunicorn server by default is exposed on port 8080.

Tandoor 2 now bundles nginx inside the container and exposes port 80 where mediafiles are handled by nginx and all the other requests are (mostly) passed to gunicorn.

A [GitHub Issue](https://github.com/TandoorRecipes/recipes/issues/3851) has been created to allow for discussions and FAQ's on this issue while this change is fresh. It will later be updated in the docs here if necessary.

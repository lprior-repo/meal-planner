---
doc_id: ops/install/manual
chunk_id: ops/install/manual#chunk-10
heading_path: ["Manual installation instructions", "Setup web services"]
chunk_type: code
tokens: 236
summary: "Setup web services"
---

## Setup web services

### gunicorn

Create a service that will start gunicorn at boot: `sudo nano /etc/systemd/system/gunicorn_recipes.service`

And enter these lines:

```service
[Unit]
Description=gunicorn daemon for recipes
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=3
User=recipes
Group=www-data
WorkingDirectory=/var/www/recipes
EnvironmentFile=/var/www/recipes/.env
ExecStart=/var/www/recipes/bin/gunicorn --error-logfile /tmp/gunicorn_err.log --log-level debug --capture-output --bind unix:/var/www/recipes/recipes.sock recipes.wsgi:application

[Install]
WantedBy=multi-user.target
```text

*Note*: `-error-logfile /tmp/gunicorn_err.log --log-level debug --capture-output` are useful for debugging and can be removed later

*Note2*: Fix the path in the `ExecStart` line to where you gunicorn and recipes are

Finally, run `sudo systemctl enable --now gunicorn_recipes`. You can check that the service is correctly started with `systemctl status gunicorn_recipes`

### nginx

Now we tell nginx to listen to a new port and forward that to gunicorn. `sudo nano /etc/nginx/conf.d/recipes.conf`

And enter these lines:

```nginx
server {
    listen 8002;
    #access_log /var/log/nginx/access.log;
    #error_log /var/log/nginx/error.log;

    # serve media files
    location /static/ {
        alias /var/www/recipes/staticfiles;
    }
    
    location /media/ {
        alias /var/www/recipes/mediafiles;
    }

    location / {
        proxy_set_header Host $http_host;
        proxy_pass http://unix:/var/www/recipes/recipes.sock;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```text

*Note*: Enter the correct path in static and proxy_pass lines.

Reload nginx : `sudo systemctl reload nginx`

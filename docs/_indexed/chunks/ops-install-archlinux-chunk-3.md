---
doc_id: ops/install/archlinux
chunk_id: ops/install/archlinux#chunk-3
heading_path: ["Archlinux", "Installation"]
chunk_type: code
tokens: 143
summary: "Installation"
---

## Installation
1. Clone the package, build and install with makepkg:
```shell
git clone https://aur.archlinux.org/tandoor-recipes-git.git
cd tandoor-recipes-git
makepkg -si
```text
or use your favourite AUR helper.

2. Setup a PostgreSQL database and user, as explained here: https://docs.tandoor.dev/install/manual/#setup-postgresql

3. Configure the service in `/etc/tandoor/tandoor.conf`.

4. Reinstall the package, or follow [the official instructions](https://docs.tandoor.dev/install/manual/#initialize-the-application) to have tandoor creates its DB tables.

5. Optionally configure a reverse proxy. A configuration for Nginx is provided, but you can Traefik, Apache, etc..
Edit `/etc/nginx/sites-available/tandoor.conf`. You may want to use another `server_name`, or configure TLS. Then:
```shell
cd /etc/nginx/sites-enabled
ln -s ../sites-available/tandoor.conf
systemctl restart nginx
```text

6. Enable the service
```shell
systemctl enable --now tandoor
```text

---
id: ops/tandoor/archlinux
title: "Archlinux"
category: ops
tags: ["archlinux", "tandoor", "operations"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Archlinux</title>
  <description>!!! info &quot;Community Contributed&quot; This guide was contributed by the community and is neither officially supported, nor updated or tested.</description>
  <created_at>2026-01-02T19:55:27.285158</created_at>
  <updated_at>2026-01-02T19:55:27.285158</updated_at>
  <language>en</language>
  <sections count="4">
    <section name="Features" level="2"/>
    <section name="Installation" level="2"/>
    <section name="Upgrade" level="2"/>
    <section name="Help" level="2"/>
  </sections>
  <features>
    <feature>features</feature>
    <feature>help</feature>
    <feature>installation</feature>
    <feature>upgrade</feature>
  </features>
  <dependencies>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <examples count="4">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>archlinux,tandoor,operations</tags>
</doc_metadata>
-->

# Archlinux

> **Context**: !!! info "Community Contributed" This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! info "Community Contributed"
    This guide was contributed by the community and is neither officially supported, nor updated or tested.

!!! danger "Tandoor 2 Compatibility"
    This guide has not been verified/tested for Tandoor 2, which now integrates a nginx service inside the default docker container and exposes its service on port 80 instead of 8080.

These are instructions for pacman based distributions, like ArchLinux. The package is available from the [AUR](https://aur.archlinux.org/packages/tandoor-recipes-git) or from [GitHub](https://github.com/jdecourval/tandoor-recipes-pkgbuild).

## Features
- systemd integration.
- Provide configuration for Nginx.
- Use socket activation.
- Use a non-root user.
- Apply migrations automatically.

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

## Upgrade
```shell
cd tandoor-recipes-git
git pull
makepkg -sif
```
Or use your favourite AUR helper.
You shouldn't need to do anything else. This package applies migration automatically. If PostgreSQL has been updated to a new major version, you may need to [run pg_upgrade](https://wiki.archlinux.org/title/PostgreSQL#pg_upgrade).

## Help
This package is non-official. Issues should be posted to https://github.com/jdecourval/tandoor-recipes-pkgbuild or https://aur.archlinux.org/packages/tandoor-recipes-git.


## See Also

- [Documentation Index](./COMPASS.md)

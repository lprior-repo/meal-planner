---
id: ops/tandoor/updating
title: "Updating"
category: ops
tags: ["updating", "tandoor", "operations", "docker"]
---

<!--
<doc_metadata>
  <type>guide</type>
  <category>recipes</category>
  <title>Updating</title>
  <description>The Updating process depends on your chosen method of [installation](/install/docker)</description>
  <created_at>2026-01-02T19:55:27.336434</created_at>
  <updated_at>2026-01-02T19:55:27.336434</updated_at>
  <language>en</language>
  <sections count="3">
    <section name="Docker" level="2"/>
    <section name="Manual" level="2"/>
    <section name="PostgreSQL" level="2"/>
  </sections>
  <features>
    <feature>docker</feature>
    <feature>manual</feature>
    <feature>postgresql</feature>
  </features>
  <dependencies>
    <dependency type="service">postgres</dependency>
    <dependency type="service">postgresql</dependency>
    <dependency type="service">docker</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">/install/docker</entity>
    <entity relationship="uses">/system/backup</entity>
  </related_entities>
  <examples count="9">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>intermediate</difficulty_level>
  <estimated_reading_time>2</estimated_reading_time>
  <tags>updating,tandoor,operations,docker</tags>
</doc_metadata>
-->

# Updating

> **Context**: The Updating process depends on your chosen method of [installation](/install/docker)

The Updating process depends on your chosen method of [installation](/install/docker)

While intermediate updates can be skipped when updating please make sure to
**read the release notes** in case some special action is required to update.

## Docker
For all setups using Docker the updating process look something like this

0. Before updating it is recommended to **create a [backup](/system/backup)!**
1. Stop the container using `docker compose down`
2. Pull the latest image using `docker compose pull`
3. Start the container again using `docker compose up -d`

## Manual

For all setups using a manual installation updates usually involve downloading the latest source code from GitHub.
After that make sure to run:

1. `pip install -r requirements.txt`
2. `manage.py collectstatic`
3. `manage.py migrate`
4. `cd ./vue`
5. `yarn install`
6. `yarn build`

To install latest libraries, apply all new migrations and collect new static files.

## PostgreSQL

Postgres does not automatically upgrade database files when you change versions and requires manual intervention.
One option is to manually [backup/restore](https://docs.tandoor.dev/system/updating/#postgresql) the database.

A full list of options to upgrade a database provide in the [official PostgreSQL documentation](https://www.postgresql.org/docs/current/upgrading.html).

1.  Collect information about your environment.

``` bash
grep -E 'POSTGRES|DATABASE' ~/.docker/compose/.env
docker ps -a --format 'table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}' | awk 'NR == 1 || /postgres/ || /recipes/'
```bash

2. Export the tandoor database

``` bash
docker exec -t {{database_container}} pg_dumpall -U {{djangouser}} > ~/tandoor.sql
```text

3. Stop the tandoor application
``` bash
docker compose down
```text

4. Rename the tandoor volume

``` bash
mv ./postgresql ./postgresql.old
```sql

5. Update image tag on postgres container in the docker-compose.yaml

``` yaml
db_recipes:
  restart: always
  image: postgres:16-alpine
  volumes:
    - ./postgresql:/var/lib/postgresql/data
  env_file:
    - ./.env
```text

6. Pull and rebuild database container

``` bash
docker compose pull && docker compose up -d db_recipes
```python

7. Import the database export

``` bash
cat ~/tandoor.sql | docker exec -i {{database_container}} psql postgres -U {{djangouser}}
```text

8. Install postgres extensions
``` bash
docker exec -it {{database_container}} psql postgres -U {{djangouser}}
```text
  then
``` psql
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

If anything fails, go back to the old postgres version and data directory and try again.

There are many articles and tools online that might provide a good starting point to help you upgrade [1](https://thomasbandt.com/postgres-docker-major-version-upgrade), [2](https://github.com/tianon/docker-postgres-upgrade), [3](https://github.com/vabene1111/DockerPostgresBackups).


## See Also

- [installation](/install/docker)
- [backup](/system/backup)

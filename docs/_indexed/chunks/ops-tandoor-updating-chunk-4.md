---
doc_id: ops/tandoor/updating
chunk_id: ops/tandoor/updating#chunk-4
heading_path: ["Updating", "PostgreSQL"]
chunk_type: code
tokens: 306
summary: "PostgreSQL"
---

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

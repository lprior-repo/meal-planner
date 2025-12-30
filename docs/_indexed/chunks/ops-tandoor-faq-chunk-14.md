---
doc_id: ops/tandoor/faq
chunk_id: ops/tandoor/faq#chunk-14
heading_path: ["Faq", "How can I upgrade postgres (major versions)?"]
chunk_type: prose
tokens: 243
summary: "How can I upgrade postgres (major versions)?"
---

## How can I upgrade postgres (major versions)?
Postgres requires manual intervention when updating from one major version to another. The steps are roughly

1. use `pg_dumpall` to dump your database into SQL (for Docker `docker-compose exec -T <postgres_container_name> pg_dumpall -U <postgres_user_name> -f /path/to/dump.sql`)
2. stop the DB / down the container
3. move your postgres directory in order to keep it as a backup (e.g. `mv postgres postgres_old`)
4. update postgres to the new major version (for Docker just change the version number and pull)
5. start the db / up the container (do not start tandoor as it will automatically perform the database migrations which will conflict with loading the dump)
6. if not using docker, you might need to create the same postgres user you had in the old database
7. load the postgres dump (for Docker `'/usr/local/bin/docker-compose exec -T <postgres_container_name> psql -U <postgres_user_name> <postgres_database_name> < /path/to/dump.sql`)

If anything fails, go back to the old postgres version and data directory and try again. 

There are many articles and tools online that might provide a good starting point to help you upgrade [1](https://thomasbandt.com/postgres-docker-major-version-upgrade), [2](https://github.com/tianon/docker-postgres-upgrade), [3](https://github.com/vabene1111/DockerPostgresBackups).

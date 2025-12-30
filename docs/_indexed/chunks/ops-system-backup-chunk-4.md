---
doc_id: ops/system/backup
chunk_id: ops/system/backup#chunk-4
heading_path: ["Backup", "Manual backup from docker build"]
chunk_type: code
tokens: 357
summary: "Manual backup from docker build"
---

## Manual backup from docker build
The standard docker build of tandoor uses postgresql as the back end database. This can be backed up using a function called "dumpall". This generates a .SQL file containing a list of commands for a postgresql server to use to rebuild your database. You will also need to back up the media files separately.

Making a full copy of the docker directory can work as a back up, but only if you know you will be using the same hardware, os, and postgresql version upon restore. If not, then the different version of postgresql won't be compatible with the existing tables.
You can back up from docker even when the tandoor container is failing, so long as the postgresql database has started successfully. When using this backup method, ensure that your recipes have imported successfully. One user reported only the titles and images importing on first try, requiring a second run of the import command.

the following commands assume that your docker-compose files are in a folder called "docker". replace "docker_db_recipes_1" with the name of your db container. The commands also assume you use a backup name of pgdump.sql. It's a good idea to include a date in this filename, so that successive backups do not get deleted.
To back up:
```bash
sudo docker exec -t docker_db_recipes_1 pg_dumpall -U djangouser > pgdump.sql

```

To restore:
```bash
cat pgdump.sql | sudo docker exec -i docker_db_recipes_1 psql postgres -U djangouser

```
This connects to the postgres table instead of the actual djangodb table, as the import function needs to delete the table, which can't be dropped off you're connected to it.

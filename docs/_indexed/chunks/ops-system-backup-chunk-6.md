---
doc_id: ops/system/backup
chunk_id: ops/system/backup#chunk-6
heading_path: ["Backup", "Backing up using the pgbackup container"]
chunk_type: prose
tokens: 117
summary: "Backing up using the pgbackup container"
---

## Backing up using the pgbackup container
You can add [pgbackup](https://hub.docker.com/r/prodrigestivill/postgres-backup-local) to manage the scheduling and automatic backup of your postgres database.
Modify the below to match your environment and add it to your `docker-compose.yml`

``` yaml
  pgbackup:
    container_name: pgbackup
    env_file:
      - ./.env
    environment:
      BACKUP_KEEP_DAYS: "8"
      BACKUP_KEEP_MONTHS: "6"
      BACKUP_KEEP_WEEKS: "4"
      POSTGRES_EXTRA_OPTS: -Z6 --schema=public --blobs
      SCHEDULE: '@daily'
    # Note: the tag must match the version of postgres you are using
    image: prodrigestivill/postgres-backup-local:15
    restart: unless-stopped
    volumes:
      - backups/postgres:/backups
```
You can manually initiate a backup by running `docker exec -it pgbackup ./backup.sh`

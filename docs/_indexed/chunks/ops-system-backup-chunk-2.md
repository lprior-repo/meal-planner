---
doc_id: ops/system/backup
chunk_id: ops/system/backup#chunk-2
heading_path: ["Backup", "Database"]
chunk_type: prose
tokens: 115
summary: "Database"
---

## Database
Please use any standard way of backing up your database. For most systems this can be achieved by using a dump
command that will create an SQL file with all the required data.

Please refer to your Database System documentation.

I personally use a [little script](https://github.com/vabene1111/DockerPostgresBackups) that I have created to automatically pull SQL dumps from a postgresql database.
It is **neither** well tested nor documented so use at your own risk.
I would recommend using it only as a starting place for your own backup strategy.

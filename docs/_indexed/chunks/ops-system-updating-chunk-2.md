---
doc_id: ops/system/updating
chunk_id: ops/system/updating#chunk-2
heading_path: ["Updating", "Docker"]
chunk_type: prose
tokens: 66
summary: "Docker"
---

## Docker
For all setups using Docker the updating process look something like this

0. Before updating it is recommended to **create a [backup](/system/backup)!**
1. Stop the container using `docker compose down`
2. Pull the latest image using `docker compose pull`
3. Start the container again using `docker compose up -d`

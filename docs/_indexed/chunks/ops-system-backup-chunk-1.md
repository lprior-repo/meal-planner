---
doc_id: ops/system/backup
chunk_id: ops/system/backup#chunk-1
heading_path: ["Backup"]
chunk_type: prose
tokens: 130
summary: "Backup"
---

# Backup

> **Context**: There is currently no "good" way of backing up your data implemented in the application itself. This mean that you will be responsible for backing up 

There is currently no "good" way of backing up your data implemented in the application itself.
This mean that you will be responsible for backing up your data.

It is planned to add a "real" backup feature similar to applications like homeassistant where a snapshot can be
downloaded and restored through the web interface.

!!! warning
    When developing a new backup strategy, make sure to also test the restore process!

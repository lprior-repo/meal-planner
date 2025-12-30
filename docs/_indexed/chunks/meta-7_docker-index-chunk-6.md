---
doc_id: meta/7_docker/index
chunk_id: meta/7_docker/index#chunk-6
heading_path: ["Run Docker containers", "pipe logs, monitor memory usage, kill container if job is cancelled."]
chunk_type: prose
tokens: 22
summary: "pipe logs, monitor memory usage, kill container if job is cancelled."
---

## pipe logs, monitor memory usage, kill container if job is cancelled.

msg="${1:-world}"

IMAGE="alpine:latest"
COMMAND="/bin/echo Hello $msg"

---
doc_id: meta/7_docker_quickstart/index
chunk_id: meta/7_docker_quickstart/index#chunk-6
heading_path: ["Docker quickstart", "pipe logs, monitor memory usage, kill container if job is cancelled."]
chunk_type: prose
tokens: 22
summary: "pipe logs, monitor memory usage, kill container if job is cancelled."
---

## pipe logs, monitor memory usage, kill container if job is cancelled.

msg="${1:-world}"

IMAGE="alpine:latest"
COMMAND="/bin/echo Hello $msg"

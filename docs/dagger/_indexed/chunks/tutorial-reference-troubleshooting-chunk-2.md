---
doc_id: tutorial/reference/troubleshooting
chunk_id: tutorial/reference/troubleshooting#chunk-2
heading_path: ["troubleshooting", "Dagger is unresponsive with a BuildKit error"]
chunk_type: mixed
tokens: 84
summary: "A Dagger Function may hang or become unresponsive, eventually generating a BuildKit error such as..."
---
A Dagger Function may hang or become unresponsive, eventually generating a BuildKit error such as `buildkit failed to respond` or `container state improper`.

**Solution:**

1. Stop and remove the Dagger Engine container:

```bash
DAGGER_ENGINE_DOCKER_CONTAINER="$(docker container list --all --filter 'name=^dagger-engine-*' --format '{{.Names}}')"
docker container stop "$DAGGER_ENGINE_DOCKER_CONTAINER"
docker container rm "$DAGGER_ENGINE_DOCKER_CONTAINER"
```

2. Clear unused volumes and data (optional):

```bash
docker volume prune
docker system prune
```

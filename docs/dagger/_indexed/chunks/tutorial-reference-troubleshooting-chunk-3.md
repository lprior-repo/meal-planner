---
doc_id: tutorial/reference/troubleshooting
chunk_id: tutorial/reference/troubleshooting#chunk-3
heading_path: ["troubleshooting", "Dagger is unable to resolve host names after network configuration changes"]
chunk_type: mixed
tokens: 56
summary: "If the network configuration of the host changes after the Dagger Engine container starts, Docker..."
---
If the network configuration of the host changes after the Dagger Engine container starts, Docker does not notify the Dagger Engine of the change.

**Solution:** Restart the Dagger Engine container:

```bash
DAGGER_ENGINE_DOCKER_CONTAINER="$(docker container list --all --filter 'name=^dagger-engine-*' --format '{{.Names}}')"
docker restart "$DAGGER_ENGINE_DOCKER_CONTAINER"
```

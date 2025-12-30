---
doc_id: tutorial/reference/troubleshooting
chunk_id: tutorial/reference/troubleshooting#chunk-5
heading_path: ["troubleshooting", "Errors related to code generation"]
chunk_type: mixed
tokens: 87
summary: "A Dagger Function may fail with errors like:
- `unable to start container process`
- `failed to u..."
---
A Dagger Function may fail with errors like:
- `unable to start container process`
- `failed to update codegen and runtime`
- `failed to generate code`

**Solution:**

1. Remove the `DOCKER_DEFAULT_PLATFORM` variable
2. Ensure Rosetta is disabled in Docker Desktop on Mac
3. Remove any running Dagger Engine containers:

```bash
docker rm -fv $(docker ps --filter name="dagger-engine-*" -q) && docker rmi $(docker images -q --filter reference=registry.dagger.io/engine)
```

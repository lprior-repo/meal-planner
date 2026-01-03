---
doc_id: ops/moonrepo/docker-2
chunk_id: ops/moonrepo/docker-2#chunk-39
heading_path: ["Docker integration", "Running `docker` commands"]
chunk_type: code
tokens: 74
summary: "Running `docker` commands"
---

## Running `docker` commands

When running `docker` commands, they *must* be ran from moon's workspace root (typically the repository root) so that the project graph and all `moon docker` commands resolve correctly.

```shell
docker build .
```

If you're `Dockerfile`s are located within each applicable project, use the `-f` argument.

```shell
docker run -f ./apps/client/Dockerfile .
```

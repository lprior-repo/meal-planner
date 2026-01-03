---
doc_id: ops/moonrepo/docker
chunk_id: ops/moonrepo/docker#chunk-14
heading_path: ["docker", "Install toolchain and dependencies"]
chunk_type: prose
tokens: 27
summary: "Install toolchain and dependencies"
---

## Install toolchain and dependencies
RUN moon docker setup
```

### Multi-staged

```dockerfile
#### BASE
FROM node:latest AS base

WORKDIR /app

---
doc_id: ops/guides/docker
chunk_id: ops/guides/docker#chunk-14
heading_path: ["Docker integration", "Install toolchain and dependencies"]
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

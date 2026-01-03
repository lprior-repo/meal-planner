---
doc_id: ops/moonrepo/docker
chunk_id: ops/moonrepo/docker#chunk-30
heading_path: ["docker", "CMD"]
chunk_type: prose
tokens: 18
summary: "CMD"
---

## CMD
```

### Multi-staged

```dockerfile
#### BASE
FROM node:latest AS base

WORKDIR /app

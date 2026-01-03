---
doc_id: ops/moonrepo/docker-2
chunk_id: ops/moonrepo/docker-2#chunk-30
heading_path: ["Docker integration", "CMD"]
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

---
doc_id: ops/guides/docker
chunk_id: ops/guides/docker#chunk-30
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

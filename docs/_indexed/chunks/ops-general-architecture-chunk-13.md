---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-13
heading_path: ["Meal Planner Architecture", "Docker Deployment"]
chunk_type: code
tokens: 42
summary: "Docker Deployment"
---

## Docker Deployment

Binaries are built and mounted into Windmill worker containers:

```dockerfile
FROM ghcr.io/windmill-labs/windmill-full:latest
COPY target/release/tandoor-* /usr/local/bin/
COPY target/release/fatsecret-* /usr/local/bin/
```text

Or use volume mounts for development:
```yaml
volumes:
  - ./target/release:/app/bin
```

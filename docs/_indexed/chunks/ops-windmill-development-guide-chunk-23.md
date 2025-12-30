---
doc_id: ops/windmill/development-guide
chunk_id: ops/windmill/development-guide#chunk-23
heading_path: ["Windmill Development Guide", "Connect other services"]
chunk_type: prose
tokens: 28
summary: "Connect other services"
---

## Connect other services
docker network connect shared-services tandoor-web_recipes-1
```text

Services can then reach each other by container name:
- Tandoor: `http://tandoor-web_recipes-1:80`

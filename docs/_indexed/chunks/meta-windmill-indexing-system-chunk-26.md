---
doc_id: meta/windmill/indexing-system
chunk_id: meta/windmill/indexing-system#chunk-26
heading_path: ["Windmill Documentation Indexing System", "Search Optimization"]
chunk_type: code
tokens: 44
summary: "Search Optimization"
---

## Search Optimization

### Entity-Based Search

Map terms to entities for fast lookup:

```json
{
  "retry": ["retries", "error_handler"],
  "error": ["error_handler", "retries"],
  "deploy": ["staging_prod", "windmill_deployment", "wmill_cli"]
}
```

### Tag-Based Search

Filter by tags:

```bash

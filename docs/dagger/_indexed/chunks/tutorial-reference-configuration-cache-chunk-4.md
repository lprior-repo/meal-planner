---
doc_id: tutorial/reference/configuration-cache
chunk_id: tutorial/reference/configuration-cache#chunk-4
heading_path: ["configuration-cache", "Manual Pruning"]
chunk_type: code
tokens: 40
summary: "Remove all cache entries not currently being used:
```bash
dagger core engine local-cache prune
```
"
---
Remove all cache entries not currently being used:
```bash
dagger core engine local-cache prune
```

Prune following the configured cache garbage collection policy:
```bash
dagger core engine local-cache prune --use-default-policy
```

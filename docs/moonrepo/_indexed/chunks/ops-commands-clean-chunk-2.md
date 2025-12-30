---
doc_id: ops/commands/clean
chunk_id: ops/commands/clean#chunk-2
heading_path: ["clean", "Delete cache with a custom lifetime"]
chunk_type: prose
tokens: 44
summary: "Delete cache with a custom lifetime"
---

## Delete cache with a custom lifetime
$ moon clean --lifetime '24 hours'
```

### Options

-   `--lifetime` - The maximum lifetime of cached artifacts before being marked as stale. Defaults to "7 days".

---
doc_id: meta/windmill/indexing-system
chunk_id: meta/windmill/indexing-system#chunk-27
heading_path: ["Windmill Documentation Indexing System", "Find all CLI documentation"]
chunk_type: code
tokens: 54
summary: "Find all CLI documentation"
---

## Find all CLI documentation
grep -r "<tags>windmill,cli" docs/
```

### Category-Based Search

Browse by category:

```xml
<!-- flows -->
<entity category="flows">retries, error_handler, for_loops...</entity>

<!-- core_concepts -->
<entity category="core_concepts">caching, concurrency_limits...</entity>

<!-- cli -->
<entity category="cli">wmill_cli</entity>

<!-- sdk -->
<entity category="sdk">rust_sdk, python_client</entity>
```

---
doc_id: ops/windmill/development-guide
chunk_id: ops/windmill/development-guide#chunk-24
heading_path: ["Windmill Development Guide", "File Structure"]
chunk_type: prose
tokens: 49
summary: "File Structure"
---

## File Structure

```
windmill/
├── wmill.yaml                    # Sync configuration
├── wmill-lock.yaml               # Workspace lock
└── f/
    └── meal-planner/
        └── tandoor/
            ├── test_connection.rs           # Script code
            ├── test_connection.script.yaml  # Metadata & schema
            └── test_connection.script.lock  # Dependency lock
```

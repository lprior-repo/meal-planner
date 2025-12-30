---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-3
heading_path: ["Meal Planner Architecture", "CUPID Principles"]
chunk_type: prose
tokens: 83
summary: "CUPID Principles"
---

## CUPID Principles

All code in this project should embody these properties:

- **Composable**: Small binaries that pipe JSON in/out, work with Windmill or CLI
- **Unix philosophy**: Each binary does one thing well
- **Predictable**: Same input = same output, clear error handling
- **Idiomatic**: Standard Rust patterns, serde for JSON, thiserror for errors
- **Domain-based**: Organized by business domain, not technical layers

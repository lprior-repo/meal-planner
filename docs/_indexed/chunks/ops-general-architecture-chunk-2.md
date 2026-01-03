---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-2
heading_path: ["Architecture", "Design Principles (CUPID)"]
chunk_type: prose
tokens: 62
summary: "Design Principles (CUPID)"
---

## Design Principles (CUPID)

- **Composable**: Small binaries that work standalone or via Windmill
- **Unix philosophy**: Each binary does ONE thing well
- **Predictable**: Same input = same output, explicit error handling
- **Idiomatic**: Standard Rust, serde, thiserror
- **Domain-based**: Organized by business domain, not technical layers

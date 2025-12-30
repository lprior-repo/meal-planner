---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-11
heading_path: ["Meal Planner Architecture", "Adding a New Binary"]
chunk_type: prose
tokens: 59
summary: "Adding a New Binary"
---

## Adding a New Binary

1. Create file: `src/<domain>/bin/<operation>.rs`
2. Follow the binary contract (stdin JSON → stdout JSON)
3. Keep it under ~100 lines, doing ONE thing
4. Add to `Cargo.toml`:
   ```toml
   [[bin]]
   name = "<domain>-<operation>"
   path = "src/<domain>/bin/<operation>.rs"
   ```
5. Create corresponding Windmill script

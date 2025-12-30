---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-10
heading_path: ["Meal Planner Architecture", "Adding a New Domain"]
chunk_type: prose
tokens: 50
summary: "Adding a New Domain"
---

## Adding a New Domain

1. Create domain directory: `src/<domain>/`
2. Add module files: `mod.rs`, `client.rs`, `types.rs`
3. Create `bin/` subdirectory for binaries
4. Add binaries to `Cargo.toml`
5. Export domain in `src/lib.rs`
6. Create Windmill scripts in `windmill/f/meal-planner/<domain>/`

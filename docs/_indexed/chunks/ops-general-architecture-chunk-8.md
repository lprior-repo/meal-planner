---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-8
heading_path: ["Architecture", "Adding a New Domain"]
chunk_type: prose
tokens: 37
summary: "Adding a New Domain"
---

## Adding a New Domain

1. Create `src/<domain>/` with `mod.rs`, `client.rs`, `types.rs`
2. Add binaries in `src/bin/<domain>_<operation>.rs`
3. Register in `Cargo.toml` and `src/lib.rs`
4. Create Windmill scripts in `windmill/f/<domain>/`

---
doc_id: concept/general/recipe-import-pipeline
chunk_id: concept/general/recipe-import-pipeline#chunk-3
heading_path: ["Recipe Import Pipeline", "Binaries (Phase 1)"]
chunk_type: prose
tokens: 40
summary: "Binaries (Phase 1)"
---

## Binaries (Phase 1)

| Binary | Input | Output |
|--------|-------|--------|
| `tandoor_scrape_recipe` | `{tandoor, url}` | `{recipe_json, images}` |
| `tandoor_create_recipe` | `{tandoor, recipe, keywords}` | `{recipe_id, name}` |

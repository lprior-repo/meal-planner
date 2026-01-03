---
doc_id: concept/general/recipe-import-pipeline
chunk_id: concept/general/recipe-import-pipeline#chunk-4
heading_path: ["Recipe Import Pipeline", "Binaries (Phase 2)"]
chunk_type: prose
tokens: 39
summary: "Binaries (Phase 2)"
---

## Binaries (Phase 2)

| Binary | Input | Output |
|--------|-------|--------|
| `fatsecret_enrich_nutrition` | `{fatsecret, ingredients}` | `{nutrition, auto_tags}` |
| `tandoor_update_keywords` | `{tandoor, recipe_id, keywords}` | `{success}` |

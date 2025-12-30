---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-10
heading_path: ["Recipe Import Pipeline", "Files to Create"]
chunk_type: prose
tokens: 80
summary: "Files to Create"
---

## Files to Create

| File | Purpose |
|------|---------|
| `src/bin/tandoor_scrape_recipe.rs` | Binary: scrape recipe from URL |
| `src/bin/tandoor_create_recipe.rs` | Binary: create recipe in Tandoor |
| `windmill/f/tandoor/scrape_recipe.rs` | Windmill script (alternative) |
| `windmill/f/tandoor/scrape_recipe.script.yaml` | Windmill script metadata |
| `windmill/f/tandoor/create_recipe.rs` | Windmill script (alternative) |
| `windmill/f/tandoor/create_recipe.script.yaml` | Windmill script metadata |
| `windmill/f/tandoor/import_recipe.flow/flow.yaml` | Windmill flow |

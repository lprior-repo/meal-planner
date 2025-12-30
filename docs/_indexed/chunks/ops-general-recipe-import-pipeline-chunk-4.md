---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-4
heading_path: ["Recipe Import Pipeline", "Binaries"]
chunk_type: prose
tokens: 126
summary: "Binaries"
---

## Binaries

### Phase 1 (Core Import)

| Binary | Purpose | Input | Output |
|--------|---------|-------|--------|
| `tandoor_scrape_recipe` | Scrape recipe from URL via Tandoor API | `{tandoor, url}` | `{recipe_json, images}` |
| `tandoor_create_recipe` | Create recipe in Tandoor from scraped data | `{tandoor, recipe, keywords}` | `{recipe_id, name}` |

### Phase 2 (Nutrition Enrichment)

| Binary | Purpose | Input | Output |
|--------|---------|-------|--------|
| `fatsecret_enrich_nutrition` | Look up nutrition for ingredients | `{fatsecret, ingredients}` | `{nutrition, auto_tags}` |
| `tandoor_update_keywords` | Add keywords to existing recipe | `{tandoor, recipe_id, keywords}` | `{success}` |

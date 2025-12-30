---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-13
heading_path: ["Recipe Import Pipeline", "Implementation Order"]
chunk_type: prose
tokens: 53
summary: "Implementation Order"
---

## Implementation Order

1. **Phase 1a:** `tandoor_scrape_recipe` binary/script
2. **Phase 1b:** `tandoor_create_recipe` binary/script
3. **Phase 1c:** `import_recipe` flow
4. **Phase 1d:** Test with Meat Church URLs
5. **Phase 2a:** `fatsecret_enrich_nutrition` binary
6. **Phase 2b:** `import_recipe_enriched` flow
7. **Phase 3:** `batch_import_recipes` flow

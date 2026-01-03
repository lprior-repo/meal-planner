---
doc_id: concept/general/recipe-import-pipeline
chunk_id: concept/general/recipe-import-pipeline#chunk-2
heading_path: ["Recipe Import Pipeline", "Architecture"]
chunk_type: prose
tokens: 58
summary: "Architecture"
---

## Architecture

Windmill flow composes small binaries (CUPID principles):

```
windmill flow
├── tandoor_scrape_recipe    → recipe JSON
├── tandoor_create_recipe    → recipe_id
├── fatsecret_enrich_nutrition → nutrition, tags
└── tandoor_update_keywords  → success
```

Each binary: JSON in → JSON out, ~50 lines, does one thing.

See: [ARCHITECTURE.md](./ops-general-architecture.md)

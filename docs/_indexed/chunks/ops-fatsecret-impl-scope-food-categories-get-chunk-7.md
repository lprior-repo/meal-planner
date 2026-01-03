---
doc_id: ops/fatsecret/impl-scope-food-categories-get
chunk_id: ops/fatsecret/impl-scope-food-categories-get#chunk-7
heading_path: ["Implementation Scope: FatSecret food.categories.get.v2", "Input from Windmill (fatsecret resource is auto-passed)"]
chunk_type: prose
tokens: 18
summary: "Input from Windmill (fatsecret resource is auto-passed)"
---

## Input from Windmill (fatsecret resource is auto-passed)
FATSECRET_JSON=$(echo "$fatsecret" | jq -c '.')

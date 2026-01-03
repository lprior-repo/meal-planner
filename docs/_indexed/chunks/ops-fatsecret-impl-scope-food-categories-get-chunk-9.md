---
doc_id: ops/fatsecret/impl-scope-food-categories-get
chunk_id: ops/fatsecret/impl-scope-food-categories-get#chunk-9
heading_path: ["Implementation Scope: FatSecret food.categories.get.v2", "Build input JSON"]
chunk_type: prose
tokens: 55
summary: "Build input JSON"
---

## Build input JSON
INPUT_JSON=$(jq -n \
  --argjson fs "$FATSECRET_JSON" \
  --arg region "$REGION" \
  --arg language "$LANGUAGE" \
  '{
    fatsecret: $fs,
    region: (if $region == "" then null else $region end),
    language: (if $language == "" then null else $language end)
  }')

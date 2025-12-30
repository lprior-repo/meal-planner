---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-8
heading_path: ["Recipe Import Pipeline", "f/tandoor/import_recipe_enriched.flow/flow.yaml"]
chunk_type: prose
tokens: 67
summary: "f/tandoor/import_recipe_enriched.flow/flow.yaml"
---

## f/tandoor/import_recipe_enriched.flow/flow.yaml
summary: Import recipe with nutrition enrichment

steps:
  - id: scrape
    script: f/tandoor/scrape_recipe
    
  - id: enrich
    summary: Look up nutrition data
    script: f/fatsecret/enrich_nutrition
    input:
      fatsecret: $res:u/admin/fatsecret
      ingredients: ${steps.scrape.result.recipe_json.steps[0].ingredients}
      servings: ${steps.scrape.result.recipe_json.servings}
      
  - id: create
    script: f/tandoor/create_recipe
    input:
      recipe: ${steps.scrape.result.recipe_json}
      additional_keywords:
        - ${steps.derive_source_tag.result}
        - ${steps.enrich.result.auto_tags}
        - ${flow_input.additional_keywords}
```python

### Batch Import Flow

```yaml

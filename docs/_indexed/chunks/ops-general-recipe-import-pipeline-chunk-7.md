---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-7
heading_path: ["Recipe Import Pipeline", "f/tandoor/import_recipe.flow/flow.yaml"]
chunk_type: prose
tokens: 180
summary: "f/tandoor/import_recipe.flow/flow.yaml"
---

## f/tandoor/import_recipe.flow/flow.yaml
summary: Import recipe from URL with auto-tagging
description: |
  Scrapes a recipe from a URL using Tandoor's built-in scraper,
  adds source-based and user-provided keywords, and creates
  the recipe in Tandoor.

input_schema:
  type: object
  properties:
    url:
      type: string
      description: Recipe URL to import
    additional_keywords:
      type: array
      items:
        type: string
      description: Additional keywords to add
  required:
    - url

steps:
  - id: scrape
    summary: Scrape recipe from URL
    script: f/tandoor/scrape_recipe
    input:
      tandoor: $res:u/admin/tandoor
      url: ${flow_input.url}
      
  - id: derive_source_tag
    summary: Extract source tag from URL domain
    script: inline
    lang: python
    code: |
      from urllib.parse import urlparse
      domain = urlparse(flow_input["url"]).netloc
      # meatchurch.com -> meat-church
      # seriouseats.com -> serious-eats
      return domain.replace("www.", "").replace(".com", "").replace(".", "-")
      
  - id: create
    summary: Create recipe in Tandoor
    script: f/tandoor/create_recipe
    input:
      tandoor: $res:u/admin/tandoor
      recipe: ${steps.scrape.result.recipe_json}
      additional_keywords: 
        - ${steps.derive_source_tag.result}
        - ${flow_input.additional_keywords}
```python

### Phase 2: Enriched Import (with Nutrition)

```yaml

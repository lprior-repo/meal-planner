---
doc_id: ops/general/recipe-import-pipeline
chunk_id: ops/general/recipe-import-pipeline#chunk-9
heading_path: ["Recipe Import Pipeline", "f/tandoor/batch_import_recipes.flow/flow.yaml"]
chunk_type: prose
tokens: 137
summary: "f/tandoor/batch_import_recipes.flow/flow.yaml"
---

## f/tandoor/batch_import_recipes.flow/flow.yaml
summary: Import multiple recipes from URL list

input_schema:
  type: object
  properties:
    urls:
      type: array
      items:
        type: string
    common_keywords:
      type: array
      items:
        type: string

steps:
  - id: import_all
    summary: Import each URL
    for_loop:
      iterator: ${flow_input.urls}
      script: f/tandoor/import_recipe
      input:
        url: ${iter.value}
        additional_keywords: ${flow_input.common_keywords}
        
  - id: summarize
    summary: Generate import report
    script: inline
    lang: python
    code: |
      results = steps["import_all"]["result"]
      succeeded = [r for r in results if r.get("success")]
      failed = [r for r in results if not r.get("success")]
      return {
        "total": len(results),
        "succeeded": len(succeeded),
        "failed": len(failed),
        "recipes": [{"id": r["recipe_id"], "name": r["name"]} for r in succeeded],
        "errors": [{"url": r.get("url"), "error": r.get("error")} for r in failed]
      }
```text

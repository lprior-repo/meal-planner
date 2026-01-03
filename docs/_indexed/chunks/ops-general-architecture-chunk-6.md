---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-6
heading_path: ["Architecture", "Windmill Integration"]
chunk_type: prose
tokens: 28
summary: "Windmill Integration"
---

## Windmill Integration

Flows compose binaries:

```yaml
steps:
  - get_recipes: tandoor/list_recipes
  - get_nutrition: fatsecret/search
    foreach: ${steps.get_recipes}
  - calculate: nutrition/macros
    input: ${steps.get_nutrition}
```

---
doc_id: ops/general/architecture
chunk_id: ops/general/architecture#chunk-7
heading_path: ["Meal Planner Architecture", "Example: Daily meal sync flow"]
chunk_type: prose
tokens: 35
summary: "Example: Daily meal sync flow"
---

## Example: Daily meal sync flow
steps:
  - name: get_recipes
    script: tandoor/list_recipes
  - name: get_nutrition
    script: fatsecret/foods_search
    foreach: ${steps.get_recipes.results}
  - name: calculate_macros
    script: nutrition/calculate_macros
    input: ${steps.get_nutrition}
```

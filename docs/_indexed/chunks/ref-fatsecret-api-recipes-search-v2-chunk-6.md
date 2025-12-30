---
doc_id: ref/fatsecret/api-recipes-search-v2
chunk_id: ref/fatsecret/api-recipes-search-v2#chunk-6
heading_path: ["Recipes Search v2", "Example Request"]
chunk_type: prose
tokens: 15
summary: "Example Request"
---

## Example Request

```text
GET https://platform.fatsecret.com/rest/recipes/search/v2
    ?search_expression=chicken
    &must_have_images=true
    &calories.to=500
    &max_results=10
    &format=json
```text

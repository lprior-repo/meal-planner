---
doc_id: ref/fatsecret/api-recipes-search-v2
chunk_id: ref/fatsecret/api-recipes-search-v2#chunk-5
heading_path: ["Recipes Search v2", "Response"]
chunk_type: prose
tokens: 109
summary: "Response"
---

## Response

Returns a list of recipes with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `recipe_id` | integer | Unique recipe identifier |
| `recipe_name` | string | Name of the recipe |
| `recipe_description` | string | Brief description |
| `recipe_image` | string | URL to recipe image |
| `recipe_nutrition` | object | Nutritional summary |
| `recipe_ingredients` | array | List of ingredients |
| `recipe_types` | array | Recipe categories (e.g., "Main Dishes") |

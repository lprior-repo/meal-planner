---
doc_id: ref/fatsecret/api-recipes-search-v2
chunk_id: ref/fatsecret/api-recipes-search-v2#chunk-7
heading_path: ["Recipes Search v2", "Example Response"]
chunk_type: prose
tokens: 79
summary: "Example Response"
---

## Example Response

```json
{
  "recipes": {
    "max_results": 10,
    "page_number": 0,
    "total_results": 1234,
    "recipe": [
      {
        "recipe_id": 12345,
        "recipe_name": "Grilled Chicken Breast",
        "recipe_description": "Simple grilled chicken with herbs",
        "recipe_image": "https://...",
        "recipe_nutrition": {
          "calories": "250",
          "carbohydrate": "5",
          "fat": "8",
          "protein": "35"
        },
        "recipe_ingredients": {
          "ingredient": ["chicken breast", "olive oil", "herbs"]
        },
        "recipe_types": {
          "recipe_type": ["Main Dishes"]
        }
      }
    ]
  }
}
```

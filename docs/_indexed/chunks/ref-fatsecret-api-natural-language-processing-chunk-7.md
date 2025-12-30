---
doc_id: ref/fatsecret/api-natural-language-processing
chunk_id: ref/fatsecret/api-natural-language-processing#chunk-7
heading_path: ["Natural Language Processing API v1", "Example Request"]
chunk_type: prose
tokens: 50
summary: "Example Request"
---

## Example Request

```json
{
  "user_input": "For breakfast I ate a slice of toast with butter",
  "include_food_data": true,
  "eaten_foods": [
    {
      "food_id": 12345,
      "food_name": "Whole Wheat Bread",
      "food_brand": "Nature's Own",
      "serving_description": "1 slice",
      "serving_size": 1
    }
  ]
}
```text

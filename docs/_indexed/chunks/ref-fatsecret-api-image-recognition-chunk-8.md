---
doc_id: ref/fatsecret/api-image-recognition
chunk_id: ref/fatsecret/api-image-recognition#chunk-8
heading_path: ["Image Recognition API v1", "Example Response"]
chunk_type: prose
tokens: 104
summary: "Example Response"
---

## Example Response

```json
{
  "food_response": [
    {
      "food_id": 33691,
      "food_entry_name": "Banana",
      "eaten": {
        "food_names": ["Banana", "Fresh Banana"],
        "descriptions": ["Medium banana"],
        "units": ["medium", "small", "large", "cup sliced"],
        "metric_info": {
          "metric_serving_amount": 118,
          "metric_serving_unit": "g"
        },
        "total_nutritional_content": {
          "calories": 105,
          "carbohydrate": 27,
          "protein": 1.3,
          "fat": 0.4,
          "fiber": 3.1
        }
      },
      "suggested_serving": {
        "serving_id": 52183,
        "serving_description": "1 medium (7\" to 7-7/8\" long)",
        "number_of_units": 1
      },
      "food": {
        "food_id": 33691,
        "food_name": "Banana",
        "food_type": "Generic",
        "servings": {
          "serving": [...]
        }
      }
    }
  ]
}
```

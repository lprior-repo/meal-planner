---
doc_id: ref/fatsecret/api-natural-language-processing
chunk_id: ref/fatsecret/api-natural-language-processing#chunk-8
heading_path: ["Natural Language Processing API v1", "Example Response"]
chunk_type: prose
tokens: 150
summary: "Example Response"
---

## Example Response

```json
{
  "food_response": [
    {
      "food_id": 33099,
      "food_entry_name": "Toast",
      "eaten": {
        "food_names": ["Toast", "White Toast", "Toasted Bread"],
        "descriptions": ["1 slice of toast"],
        "units": ["slice", "piece"],
        "metric_info": {
          "metric_serving_amount": 30,
          "metric_serving_unit": "g"
        },
        "total_nutritional_content": {
          "calories": 79,
          "carbohydrate": 15,
          "protein": 2.7,
          "fat": 1,
          "fiber": 0.8
        }
      },
      "suggested_serving": {
        "serving_id": 47512,
        "serving_description": "1 slice",
        "number_of_units": 1
      }
    },
    {
      "food_id": 36774,
      "food_entry_name": "Butter",
      "eaten": {
        "food_names": ["Butter", "Salted Butter"],
        "descriptions": ["1 pat of butter"],
        "units": ["pat", "tbsp", "tsp", "cup"],
        "metric_info": {
          "metric_serving_amount": 5,
          "metric_serving_unit": "g"
        },
        "total_nutritional_content": {
          "calories": 36,
          "carbohydrate": 0,
          "protein": 0,
          "fat": 4.1,
          "fiber": 0
        }
      },
      "suggested_serving": {
        "serving_id": 51284,
        "serving_description": "1 pat",
        "number_of_units": 1
      }
    }
  ]
}
```

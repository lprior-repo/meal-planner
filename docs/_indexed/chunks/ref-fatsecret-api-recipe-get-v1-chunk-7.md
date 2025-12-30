---
doc_id: ref/fatsecret/api-recipe-get-v1
chunk_id: ref/fatsecret/api-recipe-get-v1#chunk-7
heading_path: ["Recipe Get by ID v1", "Example Response"]
chunk_type: prose
tokens: 219
summary: "Example Response"
---

## Example Response

```json
{
  "recipe": {
    "recipe_id": 12345,
    "recipe_name": "Grilled Chicken Breast",
    "recipe_url": "https://www.fatsecret.com/recipes/...",
    "recipe_description": "Simple grilled chicken with herbs and spices.",
    "number_of_servings": 4,
    "preparation_time_min": 10,
    "cooking_time_min": 20,
    "rating": 4.5,
    "recipe_types": {
      "recipe_type": ["Main Dishes", "Chicken"]
    },
    "recipe_categories": {
      "recipe_category": [
        {
          "recipe_category_name": "Low Carb",
          "recipe_category_url": "https://..."
        }
      ]
    },
    "recipe_images": {
      "recipe_image": [
        "https://www.fatsecret.com/static/images/recipes/..."
      ]
    },
    "serving_sizes": {
      "serving": {
        "calories": "250",
        "carbohydrate": "2.5",
        "protein": "35",
        "fat": "10",
        "saturated_fat": "2",
        "cholesterol": "85",
        "sodium": "320",
        "fiber": "0.5",
        "sugar": "0"
      }
    },
    "ingredients": {
      "ingredient": [
        {
          "food_id": 1234,
          "food_name": "Chicken Breast",
          "serving_id": 5678,
          "number_of_units": "1.000",
          "measurement_description": "breast",
          "ingredient_description": "1 boneless, skinless chicken breast"
        },
        {
          "food_id": 2345,
          "food_name": "Olive Oil",
          "serving_id": 6789,
          "number_of_units": "1.000",
          "measurement_description": "tbsp",
          "ingredient_description": "1 tbsp olive oil"
        }
      ]
    },
    "directions": {
      "direction": [
        {
          "direction_number": 1,
          "direction_description": "Preheat grill to medium-high heat."
        },
        {
          "direction_number": 2,
          "direction_description": "Season chicken with salt and pepper."
        },
        {
          "direction_number": 3,
          "direction_description": "Grill for 6-8 minutes per side until cooked through."
        }
      ]
    }
  }
}
```

# Recipe Get by ID v1

> **Deprecated**: This API version is deprecated.

Retrieve complete recipe details by recipe ID.

## Endpoint

- **URL**: `https://platform.fatsecret.com/rest/recipe/v1`
- **Method**: `recipe.get`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `recipe_id` | integer | **Yes** | Unique identifier of the recipe |
| `format` | string | No | Response format (`json` or `xml`) |

## Premier Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `region` | string | Regional content filter (Premier accounts only) |

## Response

Returns a complete recipe object with the following fields:

### Basic Information

| Field | Type | Description |
|-------|------|-------------|
| `recipe_id` | integer | Unique recipe identifier |
| `recipe_name` | string | Name of the recipe |
| `recipe_url` | string | URL to recipe on FatSecret |
| `recipe_description` | string | Full description |
| `number_of_servings` | integer | Number of servings |
| `preparation_time_min` | integer | Prep time in minutes |
| `cooking_time_min` | integer | Cooking time in minutes |
| `rating` | float | User rating (0-5) |

### Categories

| Field | Type | Description |
|-------|------|-------------|
| `recipe_types` | array | Recipe type categories |
| `recipe_categories` | array | Additional categorization |

### Media

| Field | Type | Description |
|-------|------|-------------|
| `recipe_images` | array | URLs to recipe images |

### Nutrition

| Field | Type | Description |
|-------|------|-------------|
| `serving_sizes` | object | Complete nutritional information per serving |

The `serving_sizes` object includes:
- `calories`
- `carbohydrate`
- `protein`
- `fat`
- `saturated_fat`
- `polyunsaturated_fat`
- `monounsaturated_fat`
- `cholesterol`
- `sodium`
- `potassium`
- `fiber`
- `sugar`
- `vitamin_a`
- `vitamin_c`
- `calcium`
- `iron`

### Ingredients

| Field | Type | Description |
|-------|------|-------------|
| `ingredients` | array | List of ingredient objects |

Each ingredient contains:

| Field | Type | Description |
|-------|------|-------------|
| `food_id` | integer | FatSecret food database ID |
| `food_name` | string | Name of the food item |
| `serving_id` | integer | Serving size ID used |
| `number_of_units` | float | Quantity of servings |
| `measurement_description` | string | Unit of measurement |
| `ingredient_description` | string | Full ingredient text |

### Directions

| Field | Type | Description |
|-------|------|-------------|
| `directions` | array | Step-by-step cooking instructions |

## Example Request

```text
GET https://platform.fatsecret.com/rest/recipe/v1
    ?recipe_id=12345
    &format=json
```

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

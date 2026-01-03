---
id: ref/fatsecret/api-foods-get-favorites
title: "Foods Get Favorites (v1)"
category: ref
tags: ["fatsecret", "reference", "foods"]
---

# Foods Get Favorites (v1)

> **Context**: Retrieve the user's favorite foods list.

Retrieve the user's favorite foods list.

> **Deprecated** - This is version 1 of the API. Check for newer versions.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food/favorites/v1`
- **HTTP Method:** GET
- **API Method:** `foods.get_favorites`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

## Response

Returns a list of favorite foods:

| Field | Type | Description |
|-------|------|-------------|
| `food_id` | integer | Unique food identifier |
| `food_name` | string | Name of the food |
| `food_type` | string | Type of food (e.g., `Generic`, `Brand`) |
| `food_url` | string | URL to the food on fatsecret.com |
| `food_description` | string | Brief description with nutrition summary |
| `serving_id` | integer | Default serving size identifier (if set) |
| `number_of_units` | decimal | Default number of servings (if set) |

## Example Response (JSON)

```json
{
  "foods": {
    "food": [
      {
        "food_id": "12345",
        "food_name": "Chicken Breast",
        "food_type": "Generic",
        "food_url": "https://www.fatsecret.com/calories-nutrition/generic/chicken-breast",
        "food_description": "Per 100g - Calories: 165kcal | Fat: 3.57g | Carbs: 0.00g | Protein: 31.02g",
        "serving_id": "54321",
        "number_of_units": "1.00"
      },
      {
        "food_id": "12346",
        "food_name": "Brown Rice",
        "food_type": "Generic",
        "food_url": "https://www.fatsecret.com/calories-nutrition/generic/brown-rice",
        "food_description": "Per 100g - Calories: 112kcal | Fat: 0.83g | Carbs: 23.51g | Protein: 2.32g"
      },
      {
        "food_id": "78901",
        "food_name": "Greek Yogurt",
        "food_type": "Brand",
        "food_url": "https://www.fatsecret.com/calories-nutrition/brand/greek-yogurt",
        "food_description": "Per container - Calories: 100kcal | Fat: 0.00g | Carbs: 6.00g | Protein: 17.00g",
        "serving_id": "98765",
        "number_of_units": "1.00"
      }
    ]
  }
}
```

## Usage Notes

- Favorites without custom serving preferences will not include `serving_id` or `number_of_units`
- Use `food_id` from this response to log entries quickly with `food_entry.create`
- The `food_description` provides a quick nutrition summary
- Empty favorites list returns an empty `foods` object
- Use `food.add_favorite` to add new favorites


## See Also

- [Documentation Index](./COMPASS.md)

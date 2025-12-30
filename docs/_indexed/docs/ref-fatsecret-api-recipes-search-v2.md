---
id: ref/fatsecret/api-recipes-search-v2
title: "Recipes Search v2"
category: ref
tags: ["recipes", "fatsecret", "reference"]
---

# Recipes Search v2

> **Context**: Search for recipes by name or keyword.

> **Deprecated**: This API version is deprecated.

Search for recipes by name or keyword.

## Endpoint

- **URL**: `https://platform.fatsecret.com/rest/recipes/search/v2`
- **Method**: `recipes.search.v2`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `search_expression` | string | No | Search terms for recipe name/description |
| `must_have_images` | boolean | No | Filter to only recipes with images |
| `calories.from` | integer | No | Minimum calories per serving |
| `calories.to` | integer | No | Maximum calories per serving |
| `carb_percentage.from` | integer | No | Minimum carbohydrate percentage |
| `carb_percentage.to` | integer | No | Maximum carbohydrate percentage |
| `protein_percentage.from` | integer | No | Minimum protein percentage |
| `protein_percentage.to` | integer | No | Maximum protein percentage |
| `fat_percentage.from` | integer | No | Minimum fat percentage |
| `fat_percentage.to` | integer | No | Maximum fat percentage |
| `prep_time.from` | integer | No | Minimum preparation time (minutes) |
| `prep_time.to` | integer | No | Maximum preparation time (minutes) |
| `page_number` | integer | No | Page number for pagination (0-indexed) |
| `max_results` | integer | No | Results per page (max 50) |
| `sort_by` | string | No | Sort order (see below) |
| `format` | string | No | Response format (`json` or `xml`) |

### Sort Options

- `newest` - Most recently added first
- `oldest` - Oldest first
- `caloriesPerServingAscending` - Lowest calories first
- `caloriesPerServingDescending` - Highest calories first

## Premier Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `region` | string | Regional content filter (Premier accounts only) |

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

## Example Request

```text
GET https://platform.fatsecret.com/rest/recipes/search/v2
    ?search_expression=chicken
    &must_have_images=true
    &calories.to=500
    &max_results=10
    &format=json
```text

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


## See Also

- [Documentation Index](./COMPASS.md)

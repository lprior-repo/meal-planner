---
id: ref/fatsecret/api-foods-search-v3
title: "Foods Search v3"
category: ref
tags: ["fatsecret", "reference", "foods"]
---

# Foods Search v3

> **Context**: Search for foods by name or description with comprehensive nutrition data, allergens, and food attributes.

> **Status:** Premier, Deprecated

## Overview

Search for foods by name or description with comprehensive nutrition data, allergens, and food attributes.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/foods/search/v3`
- **Method:** `foods.search.v3`
- **Scopes:** `premier`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `search_expression` | string | Yes | Search terms for food matching |
| `page_number` | integer | No | Page number for paginated results (0-based) |
| `max_results` | integer | No | Maximum results per page (max 50) |
| `include_sub_categories` | boolean | No | Include food sub-category information |
| `include_food_images` | boolean | No | Include food image URLs |
| `include_food_attributes` | boolean | No | Include allergens and dietary preferences |
| `flag_default_serving` | boolean | No | Flag the default serving in results |
| `region` | string | No | Filter by region code |
| `language` | string | No | Response language code |
| `format` | string | No | Response format (`json` or `xml`) |

## Response

The response includes detailed food information:

- `food_id` - Unique identifier for the food
- `food_name` - Name of the food item
- `food_type` - Type classification (Brand, Generic)
- `food_url` - URL to the food page on FatSecret
- `brand_name` - Brand name (for branded foods)
- `servings` - Array of serving options with full nutrition data:
  - Calories, fat, carbohydrates, protein
  - Detailed macro and micronutrient breakdown
- `allergens` - Allergen information (when `include_food_attributes` is true)
- `preferences` - Dietary preferences (when `include_food_attributes` is true)

## Example Request

```text
GET https://platform.fatsecret.com/rest/foods/search/v3
    ?search_expression=chicken+breast
    &max_results=10
    &include_food_attributes=true
    &format=json
```

## Notes

- This endpoint is deprecated; consider using the latest version when available
- Requires Premier access scope
- Maximum of 50 results per request


## See Also

- [Documentation Index](./COMPASS.md)

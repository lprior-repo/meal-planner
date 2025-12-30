---
id: ref/fatsecret/api-foods-search-v1
title: "Foods Search v1"
category: ref
tags: ["foods", "fatsecret", "reference"]
---

# Foods Search v1

> **Context**: Search for foods by name with basic food information. This is the original search endpoint with simpler response data.

> **Status:** Legacy

## Overview

Search for foods by name with basic food information. This is the original search endpoint with simpler response data.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/foods/search/v1`
- **Method:** `foods.search`

## Parameters

### Standard Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `search_expression` | string | Yes | Search terms for food matching |
| `page_number` | integer | No | Page number for paginated results (0-based) |
| `max_results` | integer | No | Maximum results per page (max 50) |
| `format` | string | No | Response format (`json` or `xml`) |

### Premier Parameters

These parameters require Premier access:

| Parameter | Type | Description |
|-----------|------|-------------|
| `generic_description` | string | Filter by generic food description |
| `region` | string | Filter by region code |
| `language` | string | Response language code |

## Response

The response includes basic food information:

- `food_id` - Unique identifier for the food
- `food_name` - Name of the food item
- `brand_name` - Brand name (for branded foods)
- `food_type` - Type classification (Brand, Generic)
- `food_url` - URL to the food page on FatSecret
- `food_description` - Brief description with basic nutrition summary

## Example Request

```text
GET https://platform.fatsecret.com/rest/foods/search/v1
    ?search_expression=apple
    &max_results=20
    &format=json
```

## Example Response

```json
{
  "foods": {
    "food": [
      {
        "food_id": "35718",
        "food_name": "Apple",
        "food_type": "Generic",
        "food_url": "https://www.fatsecret.com/calories-nutrition/generic/apple",
        "food_description": "Per 100g - Calories: 52kcal | Fat: 0.17g | Carbs: 13.81g | Protein: 0.26g"
      }
    ],
    "max_results": "20",
    "page_number": "0",
    "total_results": "1234"
  }
}
```

## Notes

- Maximum of 50 results per request
- Use `food.get` to retrieve full nutrition details for a specific food
- Premier features require appropriate access scope


## See Also

- [Documentation Index](./COMPASS.md)

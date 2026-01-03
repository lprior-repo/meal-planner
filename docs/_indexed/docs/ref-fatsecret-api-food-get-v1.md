---
id: ref/fatsecret/api-food-get-v1
title: "Food Get v1"
category: ref
tags: ["fatsecret", "reference", "food"]
---

# Food Get v1

> **Context**: Retrieve detailed information for a specific food item by its ID, including complete serving and nutrition data.

> **Status:** Deprecated

## Overview

Retrieve detailed information for a specific food item by its ID, including complete serving and nutrition data.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food/v1`
- **Method:** `food.get`

## Parameters

### Standard Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_id` | integer | Yes | Unique identifier of the food to retrieve |
| `format` | string | No | Response format (`json` or `xml`) |

### Premier Parameters

These parameters require Premier access:

| Parameter | Type | Description |
|-----------|------|-------------|
| `include_sub_categories` | boolean | Include food sub-category information |
| `flag_default_serving` | boolean | Flag the default serving in results |
| `region` | string | Filter by region code |
| `language` | string | Response language code |

## Response

The response includes comprehensive food details:

### Food Information
- `food_id` - Unique identifier
- `food_name` - Name of the food
- `food_type` - Type classification (Brand, Generic)
- `food_url` - URL to FatSecret page
- `brand_name` - Brand name (if applicable)

### Servings

Each serving includes:

- `serving_id` - Unique serving identifier
- `serving_description` - Human-readable description (e.g., "1 cup", "100g")
- `serving_url` - URL to serving details
- `metric_serving_amount` - Amount in metric units
- `metric_serving_unit` - Metric unit type
- `number_of_units` - Number of units in serving

### Nutrition Data (per serving)

- `calories` - Total calories
- `fat` - Total fat (g)
- `saturated_fat` - Saturated fat (g)
- `trans_fat` - Trans fat (g)
- `polyunsaturated_fat` - Polyunsaturated fat (g)
- `monounsaturated_fat` - Monounsaturated fat (g)
- `cholesterol` - Cholesterol (mg)
- `sodium` - Sodium (mg)
- `carbohydrate` - Total carbohydrates (g)
- `fiber` - Dietary fiber (g)
- `sugar` - Sugars (g)
- `protein` - Protein (g)
- `vitamin_a` - Vitamin A (% DV)
- `vitamin_c` - Vitamin C (% DV)
- `calcium` - Calcium (% DV)
- `iron` - Iron (% DV)
- `potassium` - Potassium (mg)

## Example Request

```text
GET https://platform.fatsecret.com/rest/food/v1
    ?food_id=35718
    &format=json
```text

## Example Response

```json
{
  "food": {
    "food_id": "35718",
    "food_name": "Apple",
    "food_type": "Generic",
    "food_url": "https://www.fatsecret.com/calories-nutrition/generic/apple",
    "servings": {
      "serving": [
        {
          "serving_id": "34185",
          "serving_description": "1 medium (3\" dia)",
          "metric_serving_amount": "182.000",
          "metric_serving_unit": "g",
          "calories": "95",
          "carbohydrate": "25.13",
          "protein": "0.47",
          "fat": "0.31",
          "fiber": "4.40",
          "sugar": "18.91"
        }
      ]
    }
  }
}
```

## Notes

- This endpoint is deprecated; consider using newer versions when available
- The `food_id` can be obtained from search results
- Some nutrition fields may not be present for all foods


## See Also

- [Documentation Index](./COMPASS.md)

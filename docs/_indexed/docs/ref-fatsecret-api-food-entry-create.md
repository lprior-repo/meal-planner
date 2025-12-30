---
id: ref/fatsecret/api-food-entry-create
title: "Food Entry Create"
category: ref
tags: ["food", "fatsecret", "reference"]
---

# Food Entry Create

> **Context**: Create a food diary entry for a user.

Create a food diary entry for a user.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food-entries/v1`
- **HTTP Method:** POST
- **API Method:** `food_entry.create`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_id` | integer | Yes | The unique food identifier |
| `food_entry_name` | string | Yes | Display name for the entry |
| `serving_id` | integer | Yes | The serving size identifier |
| `number_of_units` | decimal | Yes | Number of servings consumed |
| `meal` | string | Yes | Meal type: `breakfast`, `lunch`, `dinner`, or `other` |
| `date` | integer | No | Days since January 1, 1970 (defaults to today) |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

## Response

Returns a `food_entry` object with full nutrition information:

| Field | Description |
|-------|-------------|
| `food_entry_id` | Unique identifier for this entry |
| `food_id` | The food identifier |
| `food_entry_name` | Display name |
| `serving_id` | Serving size identifier |
| `number_of_units` | Number of servings |
| `meal` | Meal type |
| `date_int` | Entry date (days since epoch) |
| `calories` | Total calories |
| `carbohydrate` | Total carbohydrates (g) |
| `protein` | Total protein (g) |
| `fat` | Total fat (g) |
| `saturated_fat` | Saturated fat (g) |
| `polyunsaturated_fat` | Polyunsaturated fat (g) |
| `monounsaturated_fat` | Monounsaturated fat (g) |
| `cholesterol` | Cholesterol (mg) |
| `sodium` | Sodium (mg) |
| `potassium` | Potassium (mg) |
| `fiber` | Dietary fiber (g) |
| `sugar` | Sugar (g) |

## Example Response (JSON)

```json
{
  "food_entry": {
    "food_entry_id": "123456789",
    "food_id": "12345",
    "food_entry_name": "Chicken Breast",
    "serving_id": "54321",
    "number_of_units": "1.00",
    "meal": "lunch",
    "date_int": "19724",
    "calories": "165",
    "carbohydrate": "0.00",
    "protein": "31.00",
    "fat": "3.60",
    "saturated_fat": "1.01",
    "polyunsaturated_fat": "0.77",
    "monounsaturated_fat": "1.24",
    "cholesterol": "85",
    "sodium": "74",
    "potassium": "256",
    "fiber": "0.00",
    "sugar": "0.00"
  }
}
```

## Usage Notes

- First search for foods using `foods.search` to get `food_id` and `serving_id`
- Nutrition values are calculated based on `number_of_units` multiplied by serving size
- The `date` parameter uses Unix epoch day format
- To get today's date in epoch days: `Math.floor(Date.now() / 86400000)`


## See Also

- [Documentation Index](./COMPASS.md)

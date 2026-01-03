---
id: ref/fatsecret/api-food-entries-get
title: "Food Entries Get (v1)"
category: ref
tags: ["fatsecret", "reference", "food"]
---

# Food Entries Get (v1)

> **Context**: Retrieve food diary entries for a user.

Retrieve food diary entries for a user.

> **Deprecated** - This is version 1 of the API. Check for newer versions.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food-entries/v1`
- **HTTP Method:** GET
- **API Method:** `food_entries.get`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | integer | No* | Days since January 1, 1970 |
| `food_entry_id` | integer | No* | Specific food entry identifier |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

*Either `date` or `food_entry_id` should be provided. If neither is specified, returns today's entries.

## Response

Returns a list of `food_entry` items with full nutrition information:

| Field | Description |
|-------|-------------|
| `food_entry_id` | Unique identifier for this entry |
| `food_id` | The food identifier |
| `food_entry_name` | Display name |
| `serving_id` | Serving size identifier |
| `number_of_units` | Number of servings |
| `meal` | Meal type: `breakfast`, `lunch`, `dinner`, or `other` |
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
  "food_entries": {
    "food_entry": [
      {
        "food_entry_id": "123456789",
        "food_id": "12345",
        "food_entry_name": "Oatmeal",
        "serving_id": "54321",
        "number_of_units": "1.00",
        "meal": "breakfast",
        "date_int": "19724",
        "calories": "150",
        "carbohydrate": "27.00",
        "protein": "5.00",
        "fat": "3.00",
        "saturated_fat": "0.50",
        "polyunsaturated_fat": "1.00",
        "monounsaturated_fat": "1.00",
        "cholesterol": "0",
        "sodium": "0",
        "potassium": "130",
        "fiber": "4.00",
        "sugar": "1.00"
      },
      {
        "food_entry_id": "123456790",
        "food_id": "12346",
        "food_entry_name": "Chicken Breast",
        "serving_id": "54322",
        "number_of_units": "1.50",
        "meal": "lunch",
        "date_int": "19724",
        "calories": "247",
        "carbohydrate": "0.00",
        "protein": "46.50",
        "fat": "5.40",
        "saturated_fat": "1.52",
        "polyunsaturated_fat": "1.16",
        "monounsaturated_fat": "1.86",
        "cholesterol": "128",
        "sodium": "111",
        "potassium": "384",
        "fiber": "0.00",
        "sugar": "0.00"
      }
    ]
  }
}
```

## Usage Notes

- When querying by `date`, all entries for that day are returned
- When querying by `food_entry_id`, only that specific entry is returned
- Entries are grouped by meal type in the response
- Use `date` to get daily totals for nutrition tracking
- Single entry responses return an object instead of an array


## See Also

- [Documentation Index](./COMPASS.md)

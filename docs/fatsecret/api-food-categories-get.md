# Food Categories Get All v2

> **Status:** Premier

## Overview

Retrieve all available food categories from the FatSecret database.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food-categories/v2`
- **Method:** `food_categories.get.v2`
- **Scopes:** `premier`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `region` | string | No | Filter by region code |
| `language` | string | No | Response language code |
| `format` | string | No | Response format (`json` or `xml`) |

## Response

The response includes a list of all food categories:

- `food_category_id` - Unique identifier for the category
- `food_category_name` - Display name of the category
- `food_category_description` - Description of what the category contains

## Example Request

```text
GET https://platform.fatsecret.com/rest/food-categories/v2
    ?format=json
```

## Example Response

```json
{
  "food_categories": {
    "food_category": [
      {
        "food_category_id": "1",
        "food_category_name": "Fruits",
        "food_category_description": "Fresh and dried fruits"
      },
      {
        "food_category_id": "2",
        "food_category_name": "Vegetables",
        "food_category_description": "Fresh and cooked vegetables"
      },
      {
        "food_category_id": "3",
        "food_category_name": "Meat",
        "food_category_description": "Beef, pork, lamb, and other meats"
      }
    ]
  }
}
```

## Notes

- Requires Premier access scope
- Use `food_category_id` with the Food Sub Categories endpoint to get detailed sub-categories
- Categories help organize and filter food searches

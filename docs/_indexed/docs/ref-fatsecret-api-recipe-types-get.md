---
id: ref/fatsecret/api-recipe-types-get
title: "Recipe Types Get All v1"
category: ref
tags: ["fatsecret", "reference", "recipe"]
---

# Recipe Types Get All v1

> **Context**: Retrieve all available recipe type categories.

> **Deprecated**: This API version is deprecated.

Retrieve all available recipe type categories.

## Endpoint

- **URL**: `https://platform.fatsecret.com/rest/recipe-types/v1`
- **Method**: `recipe_types.get`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `format` | string | No | Response format (`json` or `xml`) |

## Response

Returns a list of all available recipe types.

| Field | Type | Description |
|-------|------|-------------|
| `recipe_types` | array | List of recipe type names |

### Available Recipe Types

- Appetizers
- Beverages
- Breads
- Breakfast
- Desserts
- Main Dishes
- Salads
- Sandwiches
- Side Dishes
- Snacks
- Soups

## Example Request

```text
GET https://platform.fatsecret.com/rest/recipe-types/v1
    ?format=json
```text

## Example Response

```json
{
  "recipe_types": {
    "recipe_type": [
      "Appetizers",
      "Beverages",
      "Breads",
      "Breakfast",
      "Desserts",
      "Main Dishes",
      "Salads",
      "Sandwiches",
      "Side Dishes",
      "Snacks",
      "Soups"
    ]
  }
}
```

## Usage Notes

Recipe types are used to categorize recipes and can be used in conjunction with the [Recipes Search v2](./ref-fatsecret-api-recipes-search-v2.md) API to filter results.


## See Also

- [Recipes Search v2](api-recipes-search-v2.md)

# Food Brands Get All v2

> **Status:** Premier

## Overview

Retrieve a list of food brands filtered by starting characters and optionally by brand type.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/brands/v2`
- **Method:** `food_brands.get.v2`
- **Scopes:** `premier`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `starts_with` | string | Yes | Filter brands starting with this string |
| `brand_type` | string | No | Filter by brand type |
| `region` | string | No | Filter by region code |
| `language` | string | No | Response language code |
| `format` | string | No | Response format (`json` or `xml`) |

### Brand Types

- `manufacturer` - Food manufacturers and packaged goods brands
- `restaurant` - Restaurant and fast food chains
- `supermarket` - Supermarket and store brands

## Response

The response includes a list of matching brands:

- `brand_id` - Unique identifier for the brand
- `brand_name` - Name of the brand
- `brand_type` - Type of brand (manufacturer, restaurant, supermarket)

## Example Request

```text
GET https://platform.fatsecret.com/rest/brands/v2
    ?starts_with=Kel
    &brand_type=manufacturer
    &format=json
```

## Example Response

```json
{
  "brands": {
    "brand": [
      {
        "brand_id": "1234",
        "brand_name": "Kellogg's",
        "brand_type": "manufacturer"
      },
      {
        "brand_id": "5678",
        "brand_name": "Keebler",
        "brand_type": "manufacturer"
      }
    ]
  }
}
```

## Notes

- Requires Premier access scope
- Use the `starts_with` parameter to filter results alphabetically
- Brand IDs can be used to filter food searches

---
id: ref/fatsecret/api-food-brands-get
title: "Food Brands Get All v2"
category: ref
tags: ["fatsecret", "food", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Food Brands Get All v2</title>
  <description>Retrieve a list of food brands filtered by starting characters and optionally by brand type.</description>
  <created_at>2026-01-02T19:55:26.828745</created_at>
  <updated_at>2026-01-02T19:55:26.828745</updated_at>
  <language>en</language>
  <sections count="8">
    <section name="Overview" level="2"/>
    <section name="Endpoint" level="2"/>
    <section name="Parameters" level="2"/>
    <section name="Brand Types" level="3"/>
    <section name="Response" level="2"/>
    <section name="Example Request" level="2"/>
    <section name="Example Response" level="2"/>
    <section name="Notes" level="2"/>
  </sections>
  <features>
    <feature>brand_types</feature>
    <feature>endpoint</feature>
    <feature>example_request</feature>
    <feature>example_response</feature>
    <feature>notes</feature>
    <feature>overview</feature>
    <feature>parameters</feature>
    <feature>response</feature>
  </features>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>fatsecret,food,reference</tags>
</doc_metadata>
-->

# Food Brands Get All v2

> **Context**: Retrieve a list of food brands filtered by starting characters and optionally by brand type.

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
```text

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


## See Also

- [Documentation Index](./COMPASS.md)

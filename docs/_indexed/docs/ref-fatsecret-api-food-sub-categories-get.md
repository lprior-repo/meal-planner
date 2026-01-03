---
id: ref/fatsecret/api-food-sub-categories-get
title: "Food Sub Categories Get All v1"
category: ref
tags: ["fatsecret", "food", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Food Sub Categories Get All v1</title>
  <description>Retrieve all sub-categories for a specific food category.</description>
  <created_at>2026-01-02T19:55:26.838567</created_at>
  <updated_at>2026-01-02T19:55:26.838567</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Overview" level="2"/>
    <section name="Endpoint" level="2"/>
    <section name="Parameters" level="2"/>
    <section name="Response" level="2"/>
    <section name="Example Request" level="2"/>
    <section name="Example Response" level="2"/>
    <section name="Notes" level="2"/>
  </sections>
  <features>
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

# Food Sub Categories Get All v1

> **Context**: Retrieve all sub-categories for a specific food category.

> **Status:** Premier, Deprecated

## Overview

Retrieve all sub-categories for a specific food category.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food-sub-categories/v1`
- **Method:** `food_sub_categories.get`
- **Scopes:** `premier`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_category_id` | integer | Yes | ID of the parent food category |
| `region` | string | No | Filter by region code |
| `language` | string | No | Response language code |
| `format` | string | No | Response format (`json` or `xml`) |

## Response

The response includes a list of sub-categories for the specified category:

- `food_sub_category_id` - Unique identifier for the sub-category
- `food_sub_category_name` - Display name of the sub-category
- `food_sub_category_description` - Description of what the sub-category contains

## Example Request

```text
GET https://platform.fatsecret.com/rest/food-sub-categories/v1
    ?food_category_id=1
    &format=json
```text

## Example Response

```json
{
  "food_sub_categories": {
    "food_sub_category": [
      {
        "food_sub_category_id": "101",
        "food_sub_category_name": "Citrus Fruits",
        "food_sub_category_description": "Oranges, lemons, limes, and other citrus"
      },
      {
        "food_sub_category_id": "102",
        "food_sub_category_name": "Berries",
        "food_sub_category_description": "Strawberries, blueberries, raspberries, etc."
      },
      {
        "food_sub_category_id": "103",
        "food_sub_category_name": "Tropical Fruits",
        "food_sub_category_description": "Mangoes, pineapples, papayas, and more"
      }
    ]
  }
}
```

## Notes

- This endpoint is deprecated; consider using newer versions when available
- Requires Premier access scope
- First retrieve category IDs using the Food Categories endpoint
- Sub-categories provide granular organization for food items


## See Also

- [Documentation Index](./COMPASS.md)

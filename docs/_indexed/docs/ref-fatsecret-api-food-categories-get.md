---
id: ref/fatsecret/api-food-categories-get
title: "Food Categories Get All v2"
category: ref
tags: ["fatsecret", "food", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Food Categories Get All v2</title>
  <description>Retrieve all available food categories from the FatSecret database.</description>
  <created_at>2026-01-02T19:55:26.829915</created_at>
  <updated_at>2026-01-02T19:55:26.829915</updated_at>
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

# Food Categories Get All v2

> **Context**: Retrieve all available food categories from the FatSecret database.

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
```text

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


## See Also

- [Documentation Index](./COMPASS.md)

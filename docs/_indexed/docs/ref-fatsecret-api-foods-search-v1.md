---
id: ref/fatsecret/api-foods-search-v1
title: "Foods Search v1"
category: ref
tags: ["fatsecret", "reference", "foods"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Foods Search v1</title>
  <description>Search for foods by name with basic food information. This is the original search endpoint with simpler response data.</description>
  <created_at>2026-01-02T19:55:26.841221</created_at>
  <updated_at>2026-01-02T19:55:26.841221</updated_at>
  <language>en</language>
  <sections count="9">
    <section name="Overview" level="2"/>
    <section name="Endpoint" level="2"/>
    <section name="Parameters" level="2"/>
    <section name="Standard Parameters" level="3"/>
    <section name="Premier Parameters" level="3"/>
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
    <feature>premier_parameters</feature>
    <feature>response</feature>
    <feature>standard_parameters</feature>
  </features>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>fatsecret,reference,foods</tags>
</doc_metadata>
-->

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
```text

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

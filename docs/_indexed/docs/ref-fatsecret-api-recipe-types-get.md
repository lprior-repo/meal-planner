---
id: ref/fatsecret/api-recipe-types-get
title: "Recipe Types Get All v1"
category: ref
tags: ["recipe", "fatsecret", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Recipe Types Get All v1</title>
  <description>Retrieve all available recipe type categories.</description>
  <created_at>2026-01-02T19:55:26.855468</created_at>
  <updated_at>2026-01-02T19:55:26.855468</updated_at>
  <language>en</language>
  <sections count="7">
    <section name="Endpoint" level="2"/>
    <section name="Parameters" level="2"/>
    <section name="Response" level="2"/>
    <section name="Available Recipe Types" level="3"/>
    <section name="Example Request" level="2"/>
    <section name="Example Response" level="2"/>
    <section name="Usage Notes" level="2"/>
  </sections>
  <features>
    <feature>available_recipe_types</feature>
    <feature>endpoint</feature>
    <feature>example_request</feature>
    <feature>example_response</feature>
    <feature>parameters</feature>
    <feature>response</feature>
    <feature>usage_notes</feature>
  </features>
  <dependencies>
    <dependency type="feature">ref/fatsecret/api-recipes-search-v2</dependency>
  </dependencies>
  <related_entities>
    <entity relationship="uses">api-recipes-search-v2.md</entity>
  </related_entities>
  <examples count="2">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>recipe,fatsecret,reference</tags>
</doc_metadata>
-->

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

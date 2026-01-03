---
id: ref/fatsecret/api-food-add-favorite
title: "Food Add Favorite"
category: ref
tags: ["fatsecret", "food", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Food Add Favorite</title>
  <description>Add a food to the user&apos;s favorites list.</description>
  <created_at>2026-01-02T19:55:26.827897</created_at>
  <updated_at>2026-01-02T19:55:26.827897</updated_at>
  <language>en</language>
  <sections count="5">
    <section name="Endpoint" level="2"/>
    <section name="Parameters" level="2"/>
    <section name="Response" level="2"/>
    <section name="Example Response (JSON)" level="2"/>
    <section name="Usage Notes" level="2"/>
  </sections>
  <features>
    <feature>endpoint</feature>
    <feature>example_response_json</feature>
    <feature>parameters</feature>
    <feature>response</feature>
    <feature>usage_notes</feature>
  </features>
  <examples count="1">
    <example type="code">Code examples included</example>
  </examples>
  <difficulty_level>beginner</difficulty_level>
  <estimated_reading_time>1</estimated_reading_time>
  <tags>fatsecret,food,reference</tags>
</doc_metadata>
-->

# Food Add Favorite

> **Context**: Add a food to the user's favorites list.

Add a food to the user's favorites list.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food/favorite/v1`
- **HTTP Method:** POST
- **API Method:** `food.add_favorite`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_id` | integer | Yes | The unique food identifier to add as favorite |
| `serving_id` | integer | No | Default serving size identifier |
| `number_of_units` | decimal | No | Default number of servings |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

## Response

| Field | Type | Description |
|-------|------|-------------|
| `success` | integer | `1` if the food was successfully added to favorites |

## Example Response (JSON)

```json
{
  "success": 1
}
```

## Usage Notes

- Use `foods.search` to find `food_id` values
- Optionally specify `serving_id` and `number_of_units` to set default serving preferences
- If the food is already a favorite, this call will update the serving preferences
- Favorites make it faster for users to log frequently eaten foods


## See Also

- [Documentation Index](./COMPASS.md)

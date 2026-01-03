---
id: ref/fatsecret/api-food-delete-favorite
title: "Food Delete Favorite"
category: ref
tags: ["fatsecret", "food", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Food Delete Favorite</title>
  <description>Remove a food from the user&apos;s favorites list.</description>
  <created_at>2026-01-02T19:55:26.830943</created_at>
  <updated_at>2026-01-02T19:55:26.830943</updated_at>
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

# Food Delete Favorite

> **Context**: Remove a food from the user's favorites list.

Remove a food from the user's favorites list.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food/favorite/v1`
- **HTTP Method:** DELETE
- **API Method:** `food.delete_favorite`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_id` | integer | Yes | The unique food identifier to remove from favorites |
| `serving_id` | integer | No | Serving size identifier (for specific serving preference) |
| `number_of_units` | decimal | No | Number of servings (for specific serving preference) |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

## Response

| Field | Type | Description |
|-------|------|-------------|
| `success` | integer | `1` if the food was successfully removed from favorites |

## Example Response (JSON)

```json
{
  "success": 1
}
```

## Usage Notes

- The `food_id` can be obtained from `foods.get_favorites`
- Attempting to delete a food that is not in favorites will return an error
- Deletion is permanent but the food can be re-added at any time


## See Also

- [Documentation Index](./COMPASS.md)

---
id: ref/fatsecret/api-food-entry-delete
title: "Food Entry Delete"
category: ref
tags: ["fatsecret", "food", "reference"]
---

<!--
<doc_metadata>
  <type>reference</type>
  <category>api</category>
  <title>Food Entry Delete</title>
  <description>Delete a food diary entry.</description>
  <created_at>2026-01-02T19:55:26.835796</created_at>
  <updated_at>2026-01-02T19:55:26.835796</updated_at>
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

# Food Entry Delete

> **Context**: Delete a food diary entry.

Delete a food diary entry.

> **OAuth 1.0 Only** - This endpoint requires OAuth 1.0 authentication.

## Endpoint

- **URL:** `https://platform.fatsecret.com/rest/food-entries/v1`
- **HTTP Method:** DELETE
- **API Method:** `food_entry.delete`

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_entry_id` | integer | Yes | The unique food entry identifier to delete |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

## Response

| Field | Type | Description |
|-------|------|-------------|
| `success` | integer | `1` if the entry was successfully deleted |

## Example Response (JSON)

```json
{
  "success": 1
}
```

## Usage Notes

- The `food_entry_id` is obtained from `food_entries.get` or `food_entry.create`
- Deletion is permanent and cannot be undone
- Attempting to delete a non-existent entry will return an error
- Only entries belonging to the authenticated user can be deleted


## See Also

- [Documentation Index](./COMPASS.md)

---
id: ref/fatsecret/api-food-entry-delete
title: "Food Entry Delete"
category: ref
tags: ["food", "fatsecret", "reference"]
---

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

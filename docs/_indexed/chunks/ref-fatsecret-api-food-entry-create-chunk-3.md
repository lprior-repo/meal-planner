---
doc_id: ref/fatsecret/api-food-entry-create
chunk_id: ref/fatsecret/api-food-entry-create#chunk-3
heading_path: ["Food Entry Create", "Parameters"]
chunk_type: prose
tokens: 139
summary: "Parameters"
---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_id` | integer | Yes | The unique food identifier |
| `food_entry_name` | string | Yes | Display name for the entry |
| `serving_id` | integer | Yes | The serving size identifier |
| `number_of_units` | decimal | Yes | Number of servings consumed |
| `meal` | string | Yes | Meal type: `breakfast`, `lunch`, `dinner`, or `other` |
| `date` | integer | No | Days since January 1, 1970 (defaults to today) |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

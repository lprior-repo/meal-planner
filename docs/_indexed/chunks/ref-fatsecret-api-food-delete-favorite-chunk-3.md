---
doc_id: ref/fatsecret/api-food-delete-favorite
chunk_id: ref/fatsecret/api-food-delete-favorite#chunk-3
heading_path: ["Food Delete Favorite", "Parameters"]
chunk_type: prose
tokens: 94
summary: "Parameters"
---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_id` | integer | Yes | The unique food identifier to remove from favorites |
| `serving_id` | integer | No | Serving size identifier (for specific serving preference) |
| `number_of_units` | decimal | No | Number of servings (for specific serving preference) |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

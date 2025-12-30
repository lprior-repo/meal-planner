---
doc_id: ref/fatsecret/api-food-entries-get
chunk_id: ref/fatsecret/api-food-entries-get#chunk-3
heading_path: ["Food Entries Get (v1)", "Parameters"]
chunk_type: prose
tokens: 85
summary: "Parameters"
---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date` | integer | No* | Days since January 1, 1970 |
| `food_entry_id` | integer | No* | Specific food entry identifier |
| `format` | string | No | Response format: `json` or `xml` (default: `xml`) |

*Either `date` or `food_entry_id` should be provided. If neither is specified, returns today's entries.

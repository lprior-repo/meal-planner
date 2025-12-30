---
doc_id: ref/fatsecret/api-food-get-v1
chunk_id: ref/fatsecret/api-food-get-v1#chunk-4
heading_path: ["Food Get v1", "Parameters"]
chunk_type: prose
tokens: 130
summary: "Parameters"
---

## Parameters

### Standard Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `food_id` | integer | Yes | Unique identifier of the food to retrieve |
| `format` | string | No | Response format (`json` or `xml`) |

### Premier Parameters

These parameters require Premier access:

| Parameter | Type | Description |
|-----------|------|-------------|
| `include_sub_categories` | boolean | Include food sub-category information |
| `flag_default_serving` | boolean | Flag the default serving in results |
| `region` | string | Filter by region code |
| `language` | string | Response language code |

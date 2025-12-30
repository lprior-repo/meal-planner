---
doc_id: ref/fatsecret/api-image-recognition
chunk_id: ref/fatsecret/api-image-recognition#chunk-6
heading_path: ["Image Recognition API v1", "Response"]
chunk_type: prose
tokens: 222
summary: "Response"
---

## Response

### food_response Array

Each detected food item includes:

| Field | Type | Description |
|-------|------|-------------|
| food_id | integer | Unique food identifier |
| food_entry_name | string | Display name for the food entry |

### eaten Object

Information about the detected food as consumed:

| Field | Type | Description |
|-------|------|-------------|
| food_names | array | Possible names for the food |
| descriptions | array | Food descriptions |
| units | array | Available units of measurement |
| metric_info | object | Metric measurement information |
| total_nutritional_content | object | Complete nutritional breakdown |

### suggested_serving Object

Recommended serving information:

| Field | Type | Description |
|-------|------|-------------|
| serving_id | integer | Unique serving identifier |
| serving_description | string | Human-readable serving description |
| number_of_units | number | Suggested number of units |

### food Object (when include_food_data=true)

Full food details including:

- Complete food information
- All available servings with nutritional data
- Brand information (if applicable)

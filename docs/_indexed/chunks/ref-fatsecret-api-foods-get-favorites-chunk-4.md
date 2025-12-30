---
doc_id: ref/fatsecret/api-foods-get-favorites
chunk_id: ref/fatsecret/api-foods-get-favorites#chunk-4
heading_path: ["Foods Get Favorites (v1)", "Response"]
chunk_type: prose
tokens: 122
summary: "Response"
---

## Response

Returns a list of favorite foods:

| Field | Type | Description |
|-------|------|-------------|
| `food_id` | integer | Unique food identifier |
| `food_name` | string | Name of the food |
| `food_type` | string | Type of food (e.g., `Generic`, `Brand`) |
| `food_url` | string | URL to the food on fatsecret.com |
| `food_description` | string | Brief description with nutrition summary |
| `serving_id` | integer | Default serving size identifier (if set) |
| `number_of_units` | decimal | Default number of servings (if set) |

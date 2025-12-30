---
doc_id: ref/fatsecret/api-profile-get
chunk_id: ref/fatsecret/api-profile-get#chunk-4
heading_path: ["Profile Get Status", "Response"]
chunk_type: prose
tokens: 124
summary: "Response"
---

## Response

| Field | Type | Description |
|-------|------|-------------|
| `weight_measure` | string | User's preferred weight unit: `kg` or `lb` |
| `height_measure` | string | User's preferred height unit: `cm` or `inch` |
| `last_weight_kg` | number | Most recent weight entry in kilograms |
| `last_weight_date_int` | integer | Date of last weight entry (days since Jan 1, 1970) |
| `last_weight_comment` | string | Comment on the last weight entry |
| `goal_weight_kg` | number | Target weight in kilograms |
| `height_cm` | number | User's height in centimeters |

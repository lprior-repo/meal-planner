---
doc_id: ref/fatsecret/api-profile-get
chunk_id: ref/fatsecret/api-profile-get#chunk-6
heading_path: ["Profile Get Status", "Usage Notes"]
chunk_type: prose
tokens: 66
summary: "Usage Notes"
---

## Usage Notes

- Weight values are always returned in kilograms regardless of `weight_measure` preference
- Height is always returned in centimeters regardless of `height_measure` preference
- Use the `*_measure` fields to display values in the user's preferred units
- `last_weight_date_int` uses Unix epoch day format (days since January 1, 1970)

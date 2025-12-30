---
doc_id: ref/fatsecret/api-foods-get-favorites
chunk_id: ref/fatsecret/api-foods-get-favorites#chunk-6
heading_path: ["Foods Get Favorites (v1)", "Usage Notes"]
chunk_type: prose
tokens: 66
summary: "Usage Notes"
---

## Usage Notes

- Favorites without custom serving preferences will not include `serving_id` or `number_of_units`
- Use `food_id` from this response to log entries quickly with `food_entry.create`
- The `food_description` provides a quick nutrition summary
- Empty favorites list returns an empty `foods` object
- Use `food.add_favorite` to add new favorites

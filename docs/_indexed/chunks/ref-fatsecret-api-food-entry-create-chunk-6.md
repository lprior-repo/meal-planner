---
doc_id: ref/fatsecret/api-food-entry-create
chunk_id: ref/fatsecret/api-food-entry-create#chunk-6
heading_path: ["Food Entry Create", "Usage Notes"]
chunk_type: prose
tokens: 61
summary: "Usage Notes"
---

## Usage Notes

- First search for foods using `foods.search` to get `food_id` and `serving_id`
- Nutrition values are calculated based on `number_of_units` multiplied by serving size
- The `date` parameter uses Unix epoch day format
- To get today's date in epoch days: `Math.floor(Date.now() / 86400000)`

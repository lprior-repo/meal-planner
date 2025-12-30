---
doc_id: ref/fatsecret/api-food-entries-get
chunk_id: ref/fatsecret/api-food-entries-get#chunk-6
heading_path: ["Food Entries Get (v1)", "Usage Notes"]
chunk_type: prose
tokens: 74
summary: "Usage Notes"
---

## Usage Notes

- When querying by `date`, all entries for that day are returned
- When querying by `food_entry_id`, only that specific entry is returned
- Entries are grouped by meal type in the response
- Use `date` to get daily totals for nutrition tracking
- Single entry responses return an object instead of an array

---
doc_id: ref/fatsecret/api-food-entry-delete
chunk_id: ref/fatsecret/api-food-entry-delete#chunk-6
heading_path: ["Food Entry Delete", "Usage Notes"]
chunk_type: prose
tokens: 54
summary: "Usage Notes"
---

## Usage Notes

- The `food_entry_id` is obtained from `food_entries.get` or `food_entry.create`
- Deletion is permanent and cannot be undone
- Attempting to delete a non-existent entry will return an error
- Only entries belonging to the authenticated user can be deleted

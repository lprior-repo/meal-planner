---
doc_id: ref/fatsecret/api-food-delete-favorite
chunk_id: ref/fatsecret/api-food-delete-favorite#chunk-6
heading_path: ["Food Delete Favorite", "Usage Notes"]
chunk_type: prose
tokens: 50
summary: "Usage Notes"
---

## Usage Notes

- The `food_id` can be obtained from `foods.get_favorites`
- Attempting to delete a food that is not in favorites will return an error
- Deletion is permanent but the food can be re-added at any time

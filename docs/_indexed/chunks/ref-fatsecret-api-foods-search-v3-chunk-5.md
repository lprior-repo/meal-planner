---
doc_id: ref/fatsecret/api-foods-search-v3
chunk_id: ref/fatsecret/api-foods-search-v3#chunk-5
heading_path: ["Foods Search v3", "Response"]
chunk_type: prose
tokens: 115
summary: "Response"
---

## Response

The response includes detailed food information:

- `food_id` - Unique identifier for the food
- `food_name` - Name of the food item
- `food_type` - Type classification (Brand, Generic)
- `food_url` - URL to the food page on FatSecret
- `brand_name` - Brand name (for branded foods)
- `servings` - Array of serving options with full nutrition data:
  - Calories, fat, carbohydrates, protein
  - Detailed macro and micronutrient breakdown
- `allergens` - Allergen information (when `include_food_attributes` is true)
- `preferences` - Dietary preferences (when `include_food_attributes` is true)

---
doc_id: ref/fatsecret/api-food-get-v1
chunk_id: ref/fatsecret/api-food-get-v1#chunk-5
heading_path: ["Food Get v1", "Response"]
chunk_type: prose
tokens: 253
summary: "Response"
---

## Response

The response includes comprehensive food details:

### Food Information
- `food_id` - Unique identifier
- `food_name` - Name of the food
- `food_type` - Type classification (Brand, Generic)
- `food_url` - URL to FatSecret page
- `brand_name` - Brand name (if applicable)

### Servings

Each serving includes:

- `serving_id` - Unique serving identifier
- `serving_description` - Human-readable description (e.g., "1 cup", "100g")
- `serving_url` - URL to serving details
- `metric_serving_amount` - Amount in metric units
- `metric_serving_unit` - Metric unit type
- `number_of_units` - Number of units in serving

### Nutrition Data (per serving)

- `calories` - Total calories
- `fat` - Total fat (g)
- `saturated_fat` - Saturated fat (g)
- `trans_fat` - Trans fat (g)
- `polyunsaturated_fat` - Polyunsaturated fat (g)
- `monounsaturated_fat` - Monounsaturated fat (g)
- `cholesterol` - Cholesterol (mg)
- `sodium` - Sodium (mg)
- `carbohydrate` - Total carbohydrates (g)
- `fiber` - Dietary fiber (g)
- `sugar` - Sugars (g)
- `protein` - Protein (g)
- `vitamin_a` - Vitamin A (% DV)
- `vitamin_c` - Vitamin C (% DV)
- `calcium` - Calcium (% DV)
- `iron` - Iron (% DV)
- `potassium` - Potassium (mg)

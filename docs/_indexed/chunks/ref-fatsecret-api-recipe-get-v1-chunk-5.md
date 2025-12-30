---
doc_id: ref/fatsecret/api-recipe-get-v1
chunk_id: ref/fatsecret/api-recipe-get-v1#chunk-5
heading_path: ["Recipe Get by ID v1", "Response"]
chunk_type: prose
tokens: 403
summary: "Response"
---

## Response

Returns a complete recipe object with the following fields:

### Basic Information

| Field | Type | Description |
|-------|------|-------------|
| `recipe_id` | integer | Unique recipe identifier |
| `recipe_name` | string | Name of the recipe |
| `recipe_url` | string | URL to recipe on FatSecret |
| `recipe_description` | string | Full description |
| `number_of_servings` | integer | Number of servings |
| `preparation_time_min` | integer | Prep time in minutes |
| `cooking_time_min` | integer | Cooking time in minutes |
| `rating` | float | User rating (0-5) |

### Categories

| Field | Type | Description |
|-------|------|-------------|
| `recipe_types` | array | Recipe type categories |
| `recipe_categories` | array | Additional categorization |

### Media

| Field | Type | Description |
|-------|------|-------------|
| `recipe_images` | array | URLs to recipe images |

### Nutrition

| Field | Type | Description |
|-------|------|-------------|
| `serving_sizes` | object | Complete nutritional information per serving |

The `serving_sizes` object includes:
- `calories`
- `carbohydrate`
- `protein`
- `fat`
- `saturated_fat`
- `polyunsaturated_fat`
- `monounsaturated_fat`
- `cholesterol`
- `sodium`
- `potassium`
- `fiber`
- `sugar`
- `vitamin_a`
- `vitamin_c`
- `calcium`
- `iron`

### Ingredients

| Field | Type | Description |
|-------|------|-------------|
| `ingredients` | array | List of ingredient objects |

Each ingredient contains:

| Field | Type | Description |
|-------|------|-------------|
| `food_id` | integer | FatSecret food database ID |
| `food_name` | string | Name of the food item |
| `serving_id` | integer | Serving size ID used |
| `number_of_units` | float | Quantity of servings |
| `measurement_description` | string | Unit of measurement |
| `ingredient_description` | string | Full ingredient text |

### Directions

| Field | Type | Description |
|-------|------|-------------|
| `directions` | array | Step-by-step cooking instructions |

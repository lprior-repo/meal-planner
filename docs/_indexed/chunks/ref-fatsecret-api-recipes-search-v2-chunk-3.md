---
doc_id: ref/fatsecret/api-recipes-search-v2
chunk_id: ref/fatsecret/api-recipes-search-v2#chunk-3
heading_path: ["Recipes Search v2", "Parameters"]
chunk_type: prose
tokens: 300
summary: "Parameters"
---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `search_expression` | string | No | Search terms for recipe name/description |
| `must_have_images` | boolean | No | Filter to only recipes with images |
| `calories.from` | integer | No | Minimum calories per serving |
| `calories.to` | integer | No | Maximum calories per serving |
| `carb_percentage.from` | integer | No | Minimum carbohydrate percentage |
| `carb_percentage.to` | integer | No | Maximum carbohydrate percentage |
| `protein_percentage.from` | integer | No | Minimum protein percentage |
| `protein_percentage.to` | integer | No | Maximum protein percentage |
| `fat_percentage.from` | integer | No | Minimum fat percentage |
| `fat_percentage.to` | integer | No | Maximum fat percentage |
| `prep_time.from` | integer | No | Minimum preparation time (minutes) |
| `prep_time.to` | integer | No | Maximum preparation time (minutes) |
| `page_number` | integer | No | Page number for pagination (0-indexed) |
| `max_results` | integer | No | Results per page (max 50) |
| `sort_by` | string | No | Sort order (see below) |
| `format` | string | No | Response format (`json` or `xml`) |

### Sort Options

- `newest` - Most recently added first
- `oldest` - Oldest first
- `caloriesPerServingAscending` - Lowest calories first
- `caloriesPerServingDescending` - Highest calories first

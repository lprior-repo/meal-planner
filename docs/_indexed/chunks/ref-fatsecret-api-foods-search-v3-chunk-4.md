---
doc_id: ref/fatsecret/api-foods-search-v3
chunk_id: ref/fatsecret/api-foods-search-v3#chunk-4
heading_path: ["Foods Search v3", "Parameters"]
chunk_type: prose
tokens: 182
summary: "Parameters"
---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `search_expression` | string | Yes | Search terms for food matching |
| `page_number` | integer | No | Page number for paginated results (0-based) |
| `max_results` | integer | No | Maximum results per page (max 50) |
| `include_sub_categories` | boolean | No | Include food sub-category information |
| `include_food_images` | boolean | No | Include food image URLs |
| `include_food_attributes` | boolean | No | Include allergens and dietary preferences |
| `flag_default_serving` | boolean | No | Flag the default serving in results |
| `region` | string | No | Filter by region code |
| `language` | string | No | Response language code |
| `format` | string | No | Response format (`json` or `xml`) |

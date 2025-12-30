---
doc_id: ref/fatsecret/api-food-brands-get
chunk_id: ref/fatsecret/api-food-brands-get#chunk-4
heading_path: ["Food Brands Get All v2", "Parameters"]
chunk_type: prose
tokens: 131
summary: "Parameters"
---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `starts_with` | string | Yes | Filter brands starting with this string |
| `brand_type` | string | No | Filter by brand type |
| `region` | string | No | Filter by region code |
| `language` | string | No | Response language code |
| `format` | string | No | Response format (`json` or `xml`) |

### Brand Types

- `manufacturer` - Food manufacturers and packaged goods brands
- `restaurant` - Restaurant and fast food chains
- `supermarket` - Supermarket and store brands

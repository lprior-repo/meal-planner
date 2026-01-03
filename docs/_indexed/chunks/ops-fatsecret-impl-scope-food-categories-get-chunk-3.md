---
doc_id: ops/fatsecret/impl-scope-food-categories-get
chunk_id: ops/fatsecret/impl-scope-food-categories-get#chunk-3
heading_path: ["Implementation Scope: FatSecret food.categories.get.v2", "API Analysis"]
chunk_type: prose
tokens: 169
summary: "API Analysis"
---

## API Analysis

### Endpoint Details
- **Method:** `food_categories.get.v2`
- **URL:** `https://platform.fatsecret.com/rest/food-categories/v2`
- **Scope:** `premier` (requires Premier access)
- **Auth:** 2-legged OAuth (no user token required)

### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `region` | `string` | No | Filter by region code |
| `language` | `string` | No | Response language code |
| `format` | `string` | No | Response format (`json` or `xml`) |

### Response Structure

```json
{
  "food_categories": {
    "food_category": [
      {
        "food_category_id": "1",
        "food_category_name": "Fruits",
        "food_category_description": "Fresh and dried fruits"
      }
    ]
  }
}
```

**Key Observations:**
1. Returns a **static list** (rarely changes)
2. Top-level categories only (use `food_sub_categories.get` for hierarchy)
3. Requires Premier access tier
4. No pagination (full list in single response)

---

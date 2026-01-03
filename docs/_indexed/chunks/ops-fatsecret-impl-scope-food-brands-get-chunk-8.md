---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-8
heading_path: ["Implementation Scope: food.brands.get.v2", "File Locations"]
chunk_type: prose
tokens: 39
summary: "File Locations"
---

## File Locations

Following the domain-based architecture:

```
src/fatsecret/foods/
├── types.rs           # Add Brand, BrandId, BrandType, BrandListResponse
├── client.rs          # Add get_food_brands(), search_brands_simple()
└── mod.rs             # Re-export new types
```

---
doc_id: ops/fatsecret/impl-scope-food-categories-get
chunk_id: ops/fatsecret/impl-scope-food-categories-get#chunk-19
heading_path: ["Implementation Scope: FatSecret food.categories.get.v2", "Appendix: Full Type Hierarchy"]
chunk_type: prose
tokens: 65
summary: "Appendix: Full Type Hierarchy"
---

## Appendix: Full Type Hierarchy

```
FoodCategory
├── food_category_id: FoodCategoryId (opaque string)
├── food_category_name: String
└── food_category_description: String

FoodCategoriesResponse
└── categories: Vec<FoodCategory>
```

**Design follows existing patterns:**
- Opaque ID types with Display/From traits
- Serde-based JSON deserialization
- Wrapper types for API responses
- Flexible deserializers for FatSecret quirks

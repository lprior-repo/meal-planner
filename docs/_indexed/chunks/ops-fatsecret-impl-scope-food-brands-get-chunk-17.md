---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-17
heading_path: ["Implementation Scope: food.brands.get.v2", "Testing Considerations"]
chunk_type: prose
tokens: 106
summary: "Testing Considerations"
---

## Testing Considerations

If implemented, tests should cover:

1. **Success Cases**:
   - Search with just `starts_with`
   - Search with brand type filter
   - Empty results (no matches)
   - Single result (API returns object, not array)

2. **Error Cases**:
   - Missing `starts_with` parameter (code 101)
   - Invalid `brand_type` value (code 103)
   - Premier scope not available (code 12)
   - Premium subscription required (code 24)

3. **Edge Cases**:
   - Empty string for `starts_with`
   - Special characters in `starts_with`
   - Case sensitivity of brand matching

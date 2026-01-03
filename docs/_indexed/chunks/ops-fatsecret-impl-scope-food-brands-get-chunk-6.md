---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-6
heading_path: ["Implementation Scope: food.brands.get.v2", "Error Cases"]
chunk_type: prose
tokens: 150
summary: "Error Cases"
---

## Error Cases

### API Errors

| Code | Error | Cause | Recovery |
|------|-------|-------|----------|
| 12 | `MethodNotAccessible` | OAuth token lacks `premier` scope | Re-authenticate with correct scopes |
| 24 | `PremiumRequired` | Account lacks Premier subscription | Upgrade subscription plan |
| 101 | `MissingRequiredParameter` | `starts_with` parameter missing | Include required parameter |
| 103 | `InvalidParameterValue` | Invalid `brand_type` value | Use valid BrandType enum value |

### Edge Cases

1. **Empty Results**: When no brands match the filter, returns `{"brands": {}}` (empty list)
2. **Single Result**: API returns single object instead of array - handled by `deserialize_single_or_vec`
3. **Invalid brand_type**: API returns error code 103 with descriptive message

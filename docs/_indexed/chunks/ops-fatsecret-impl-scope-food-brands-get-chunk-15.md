---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-15
heading_path: ["Implementation Scope: food.brands.get.v2", "Priority Assessment"]
chunk_type: prose
tokens: 235
summary: "Priority Assessment"
---

## Priority Assessment

### Recommendation: **DEFER**

**Rationale:**

1. **Limited Immediate Value**: Brand filtering is a "nice to have" for food search, but not critical for core meal planning functionality
2. **Premier Scope Required**: Requires Premier subscription access, limiting utility
3. **Workaround Available**: Brand names are already included in `FoodSearchResult.brand_name` - users can filter client-side
4. **Low Usage Frequency**: Brand-specific searches are less common than general food searches
5. **No Dependent Features**: No other features currently depend on brand lookup

### Future Triggers for Implementation

Implement when:
- Premier subscription is active and verified
- User requests brand-specific search filtering
- Building advanced food search UI with brand autocomplete
- Analytics show users frequently filter by brand manually

### Immediate Alternative

Current `foods.search` already returns brand names:

```rust
pub struct FoodSearchResult {
    pub food_id: FoodId,
    pub food_name: String,
    pub food_type: String,
    pub brand_name: Option<String>,  // Already available!
    pub food_description: String,
    pub food_url: String,
}
```

Users can:
1. Search foods generically: `search_foods(&config, "corn flakes", 0, 20)`
2. Filter results client-side by `brand_name`
3. Use autocomplete on the brand names from search results

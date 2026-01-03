---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-4
heading_path: ["Implementation Scope: food.brands.get.v2", "Request Parameters"]
chunk_type: prose
tokens: 154
summary: "Request Parameters"
---

## Request Parameters

### Required Parameters

| Parameter | Type | Description | Validation |
|-----------|------|-------------|------------|
| `starts_with` | `String` | Filter brands starting with this string | Non-empty, typically 1-3 characters for autocomplete |

### Optional Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `brand_type` | `Option<BrandType>` | Filter by brand type | None (all types) |
| `region` | `Option<String>` | ISO region code (e.g., "US") | None |
| `language` | `Option<String>` | ISO language code (e.g., "en") | None |

### Brand Types

```rust
pub enum BrandType {
    /// Food manufacturers and packaged goods brands
    Manufacturer,
    /// Restaurant and fast food chains
    Restaurant,
    /// Supermarket and store brands
    Supermarket,
}
```

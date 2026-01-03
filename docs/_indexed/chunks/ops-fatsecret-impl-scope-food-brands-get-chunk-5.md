---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-5
heading_path: ["Implementation Scope: food.brands.get.v2", "Response Types"]
chunk_type: code
tokens: 174
summary: "Response Types"
---

## Response Types

### Primary Response

```rust
/// Response from food_brands.get.v2 API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrandListResponse {
    /// List of matching brands (may be empty)
    #[serde(
        rename = "brand",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub brands: Vec<Brand>,
}
```

### Brand Type

```rust
/// A food brand
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Brand {
    /// Unique identifier for the brand
    pub brand_id: BrandId,
    /// Display name of the brand
    pub brand_name: String,
    /// Type of brand (manufacturer, restaurant, supermarket)
    pub brand_type: BrandType,
}
```

### Opaque ID Type

```rust
/// Opaque brand ID from FatSecret API
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct BrandId(String);

impl BrandId {
    pub fn new(id: impl Into<String>) -> Self { ... }
    pub fn as_str(&self) -> &str { ... }
}
```

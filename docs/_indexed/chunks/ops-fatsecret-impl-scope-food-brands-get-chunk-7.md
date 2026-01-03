---
doc_id: ops/fatsecret/impl-scope-food-brands-get
chunk_id: ops/fatsecret/impl-scope-food-brands-get#chunk-7
heading_path: ["Implementation Scope: food.brands.get.v2", "Rust Implementation"]
chunk_type: code
tokens: 185
summary: "Rust Implementation"
---

## Rust Implementation

### Client Function Signature

```rust
/// Get list of brands filtered by starting characters
///
/// This is a 2-legged OAuth request (no user token required).
///
/// # Parameters
/// - `starts_with`: Filter brands starting with this string (required)
/// - `brand_type`: Optional brand type filter
/// - `region`: Optional ISO region code
/// - `language`: Optional ISO language code
///
/// # Example
/// ```rust
/// let brands = get_food_brands(
///     &config,
///     "Kel",
///     Some(BrandType::Manufacturer),
///     None,
///     None
/// ).await?;
/// ```
pub async fn get_food_brands(
    config: &FatSecretConfig,
    starts_with: &str,
    brand_type: Option<BrandType>,
    region: Option<&str>,
    language: Option<&str>,
) -> Result<BrandListResponse, FatSecretError>
```

### Simplified Function

```rust
/// Simplified brand lookup (no filters)
pub async fn search_brands_simple(
    config: &FatSecretConfig,
    starts_with: &str,
) -> Result<BrandListResponse, FatSecretError>
```

### Response Wrapper

```rust
#[derive(Deserialize)]
struct BrandsWrapper {
    brands: BrandListResponse,
}
```

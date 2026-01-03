---
id: ops/fatsecret/impl-scope-food-brands-get
title: "Implementation Scope: food.brands.get.v2"
category: ops
tags: ["operations", "fatsecret", "implementation", "advanced", "api"]
---

# Implementation Scope: food.brands.get.v2

> **Context**: API endpoint to retrieve a filtered list of food brands from FatSecret. This is a **Premier** scope endpoint used for food brand lookup and autocomple

## Overview

API endpoint to retrieve a filtered list of food brands from FatSecret. This is a **Premier** scope endpoint used for food brand lookup and autocomplete functionality.

**API Documentation**: [docs/fatsecret/api-food-brands-get.md](./ref-fatsecret-api-food-brands-get.md)

## API Details

- **Method**: `food_brands.get.v2`
- **Endpoint**: `https://platform.fatsecret.com/rest/brands/v2`
- **Auth**: 2-legged OAuth (no user token required)
- **Scope**: `premier` (requires Premier access)

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

## File Locations

Following the domain-based architecture:

```
src/fatsecret/foods/
├── types.rs           # Add Brand, BrandId, BrandType, BrandListResponse
├── client.rs          # Add get_food_brands(), search_brands_simple()
└── mod.rs             # Re-export new types
```

## Implementation Notes

### Serde Considerations

1. **Single vs Array**: Use `deserialize_single_or_vec` for the `brand` field to handle both single objects and arrays
2. **Empty Results**: The `default` attribute ensures empty responses parse correctly
3. **Opaque IDs**: `BrandId` is transparent (serializes as string) but type-safe

### Brand Type Serialization

```rust
impl BrandType {
    pub fn to_api_string(&self) -> &'static str {
        match self {
            BrandType::Manufacturer => "manufacturer",
            BrandType::Restaurant => "restaurant",
            BrandType::Supermarket => "supermarket",
        }
    }
}

impl Serialize for BrandType {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(self.to_api_string())
    }
}
```

### Request Building

```rust
let mut params = HashMap::new();
params.insert("starts_with".to_string(), starts_with.to_string());

if let Some(bt) = brand_type {
    params.insert("brand_type".to_string(), bt.to_api_string().to_string());
}

if let Some(r) = region {
    params.insert("region".to_string(), r.to_string());
}

if let Some(l) = language {
    params.insert("language".to_string(), l.to_string());
}

let response_json = make_api_request(config, "food_brands.get.v2", params).await?;
let wrapper: BrandsWrapper = serde_json::from_str(&response_json)?;
Ok(wrapper.brands)
```

## Use Cases

### Primary Use Case: Brand Autocomplete

```rust
// User types "Kel" in search
let brands = search_brands_simple(&config, "Kel").await?;

for brand in brands.brands {
    println!("{}: {} ({})", brand.brand_id, brand.brand_name, brand.brand_type);
}
// Output:
// 1234: Kellogg's (manufacturer)
// 5678: Keebler (manufacturer)
```

### Filter by Type

```rust
// Find restaurant chains starting with "Mc"
let restaurants = get_food_brands(
    &config,
    "Mc",
    Some(BrandType::Restaurant),
    None,
    None
).await?;
```

### Use Brand ID for Food Search

After getting a brand ID, it can be used to filter food searches:

```rust
// Get brand ID from brand search
let brands = search_brands_simple(&config, "Kell").await?;
let kelloggs_id = &brands.brands[0].brand_id;

// Use brand ID in food search (not yet implemented)
// let foods = search_foods_by_brand(&config, kelloggs_id, "corn flakes").await?;
```

## Binary Contract

Following CUPID principles, create a minimal binary wrapper:

```bash
## windmill/f/fatsecret/food_brands_get.rs
## Input: {"starts_with": "Kel", "brand_type": "manufacturer"}
## Output: {"brands": [...]}
```

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

## Related Endpoints

- **food.categories.get.v2**: Similar pattern, also Premier scope (see [api-food-categories-get.md](./ref-fatsecret-api-food-categories-get.md))
- **foods.search**: Already implemented, returns `brand_name` in results
- **food.get.v5**: Already implemented, returns `brand_name` in Food details

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

## Dependencies

- **crate::fatsecret::core::serde_utils::deserialize_single_or_vec** - Already exists
- **crate::fatsecret::core::{make_api_request, FatSecretConfig, FatSecretError}** - Already exists
- **serde::{Serialize, Deserialize}** - Standard dependency

## Compatibility

- **Rust SDK**: Full support for all parameter types
- **Windmill**: Can be exposed as Bash-wrapped binary following existing patterns
- **API Version**: v2 (current stable version)

## Summary

The `food.brands.get.v2` endpoint provides brand autocomplete and filtering functionality. While the API is well-documented and straightforward to implement, it should be **DEFERRED** because:

1. It requires Premier subscription (uncertain availability)
2. Brand names are already available in food search results
3. Client-side filtering is a viable alternative
4. No immediate business need for brand-specific searches

When needed, implementation is low-risk (estimated 2-3 hours) following existing patterns in `src/fatsecret/foods/`.


## See Also

- [docs/fatsecret/api-food-brands-get.md](api-food-brands-get.md)
- [api-food-categories-get.md](api-food-categories-get.md)

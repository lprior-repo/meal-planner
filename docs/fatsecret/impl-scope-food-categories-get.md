# Implementation Scope: FatSecret food.categories.get.v2

**Status:** Not Recommended for Implementation  
**Priority:** P3 (Low)  
**API Tier:** Premier  
**Date:** 2025-12-31

## Executive Summary

The `food.categories.get.v2` endpoint returns a static list of food category metadata. After analyzing current use cases, this endpoint provides **limited value** for our meal planning workflow. The categories are primarily useful for building UI category browsers, which is not a current requirement.

**Recommendation:** **DEFER** implementation until a specific need emerges (e.g., category-based food filtering in UI).

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

## Proposed Rust Type Design

### Domain Types (`src/fatsecret/foods/types.rs`)

```rust
use serde::{Deserialize, Serialize};
use crate::fatsecret::core::serde_utils::deserialize_single_or_vec;

// ============================================================================
// Food Category Types
// ============================================================================

/// Opaque food category ID from FatSecret API
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct FoodCategoryId(String);

impl FoodCategoryId {
    /// Creates a new FoodCategoryId from the given value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the category ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl From<String> for FoodCategoryId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for FoodCategoryId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl std::fmt::Display for FoodCategoryId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// A food category from the FatSecret database
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodCategory {
    /// Unique identifier for this category
    pub food_category_id: FoodCategoryId,
    /// Display name of the category (e.g., "Fruits", "Vegetables")
    pub food_category_name: String,
    /// Description of what the category contains
    pub food_category_description: String,
}

/// Response from food_categories.get.v2 API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodCategoriesResponse {
    /// List of food categories
    #[serde(
        rename = "food_category",
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub categories: Vec<FoodCategory>,
}
```

**Design Notes:**
- Follows existing pattern for opaque IDs (`FoodId`, `ServingId`)
- Uses `deserialize_single_or_vec` for FatSecret API quirks
- Simple, flat structure (no hierarchy at this level)

---

### Client Function (`src/fatsecret/foods/client.rs`)

```rust
use crate::fatsecret::foods::types::FoodCategoriesResponse;

// ============================================================================
// Food Categories API (food_categories.get.v2)
// ============================================================================

#[derive(Deserialize)]
struct CategoriesWrapper {
    food_categories: FoodCategoriesResponse,
}

/// Get all available food categories using food_categories.get.v2 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
/// 
/// # Optional Parameters
/// - `region`: Filter by region code (e.g., "US", "GB")
/// - `language`: Response language code (e.g., "en", "es")
pub async fn get_food_categories(
    config: &FatSecretConfig,
    region: Option<&str>,
    language: Option<&str>,
) -> Result<FoodCategoriesResponse, FatSecretError> {
    let mut params = HashMap::new();

    if let Some(r) = region {
        params.insert("region".to_string(), r.to_string());
    }

    if let Some(l) = language {
        params.insert("language".to_string(), l.to_string());
    }

    let response_json = make_api_request(config, "food_categories.get.v2", params).await?;

    let wrapper: CategoriesWrapper = serde_json::from_str(&response_json)?;
    Ok(wrapper.food_categories)
}

/// Simplified version with no region/language filters
pub async fn get_food_categories_simple(
    config: &FatSecretConfig,
) -> Result<FoodCategoriesResponse, FatSecretError> {
    get_food_categories(config, None, None).await
}
```

---

### Binary (`src/bin/fatsecret_food_categories_get.rs`)

```rust
//! FatSecret food.categories.get.v2 binary
//!
//! Fetches all available food categories from the FatSecret database.
//! Follows CUPID principles: Composable, Unix philosophy, Predictable, Idiomatic, Domain-based.

use meal_planner::fatsecret::core::FatSecretConfig;
use meal_planner::fatsecret::foods::get_food_categories;
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Debug, Deserialize)]
struct Input {
    fatsecret: FatSecretConfig,
    #[serde(default)]
    region: Option<String>,
    #[serde(default)]
    language: Option<String>,
}

#[derive(Debug, Serialize)]
struct Output {
    categories: serde_json::Value,
}

#[tokio::main]
async fn main() {
    let result = run().await;
    match result {
        Ok(output) => {
            println!("{}", serde_json::to_string(&output).unwrap());
        }
        Err(e) => {
            eprintln!(r#"{{"error": "{}"}}"#, e);
            std::process::exit(1);
        }
    }
}

async fn run() -> anyhow::Result<Output> {
    // 1. Read input from stdin
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    let input: Input = serde_json::from_str(&input_str)?;

    // 2. Get food categories
    let categories = get_food_categories(
        &input.fatsecret,
        input.region.as_deref(),
        input.language.as_deref(),
    )
    .await?;

    // 3. Return JSON output
    Ok(Output {
        categories: serde_json::to_value(categories)?,
    })
}
```

**Binary Characteristics:**
- ~50 lines (follows architecture guideline)
- JSON stdin → JSON stdout
- Single responsibility: fetch categories
- No business logic (pure data retrieval)

---

### Windmill Script (`windmill/f/fatsecret/food_categories_get.sh`)

```bash
#!/bin/bash
# Get all food categories from FatSecret API
# Requires: fatsecret resource (u/admin/fatsecret_api)

set -euo pipefail

# Input from Windmill (fatsecret resource is auto-passed)
FATSECRET_JSON=$(echo "$fatsecret" | jq -c '.')

# Optional parameters
REGION="${region:-}"
LANGUAGE="${language:-}"

# Build input JSON
INPUT_JSON=$(jq -n \
  --argjson fs "$FATSECRET_JSON" \
  --arg region "$REGION" \
  --arg language "$LANGUAGE" \
  '{
    fatsecret: $fs,
    region: (if $region == "" then null else $region end),
    language: (if $language == "" then null else $language end)
  }')

# Call binary
echo "$INPUT_JSON" | fatsecret_food_categories_get
```

---

## Use Case Analysis

### Current Project Needs

**Active Use Cases:**
1. **Food Search** (`foods.search`) - Find foods by name ✅
2. **Food Details** (`food.get`) - Get nutrition for specific food ✅
3. **Diary Entry** (`food_entry.create`) - Log food consumption ✅
4. **Favorites** (`food.add_favorite`) - Save frequently used foods ✅

**NOT Currently Needed:**
- ❌ Browse foods by category
- ❌ Filter search results by category
- ❌ Category-based meal recommendations
- ❌ UI category picker/dropdown

### Potential Future Use Cases

| Use Case | Value | Complexity | Priority |
|----------|-------|------------|----------|
| UI category browser | Medium | Low | P2 |
| Category-filtered search | Low | Medium | P3 |
| Category-based insights | Low | High | P3 |
| Sub-category navigation | Medium | Medium | P2 |

**Why Category Filtering Has Limited Value:**
- FatSecret's search is already excellent (powered by NLP)
- Text search handles most discovery needs
- Categories are broad and not nutrition-focused
- Users typically search by food name, not category

---

## Integration Points

### Database Schema
**NOT REQUIRED** - Categories are static reference data that rarely changes. If needed, fetch on-demand and cache in application memory.

### Dependencies
```toml
# No additional dependencies needed
# Uses existing fatsecret core client
```

### Related Endpoints
- `food_sub_categories.get` - Get sub-categories for a category (also low priority)
- `food.brands.get` - Get brand names (more useful for filtering)
- `foods.search` - Already filters by generic/branded without needing categories

---

## Testing Strategy

**IF IMPLEMENTED**, follow existing patterns:

### Unit Tests (`src/fatsecret/foods/client.rs`)
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_get_food_categories() {
        // Mock response test
        let json = r#"{
          "food_categories": {
            "food_category": [
              {
                "food_category_id": "1",
                "food_category_name": "Fruits",
                "food_category_description": "Fresh and dried fruits"
              }
            ]
          }
        }"#;

        // Test deserialization
        let wrapper: CategoriesWrapper = serde_json::from_str(json).unwrap();
        assert_eq!(wrapper.food_categories.categories.len(), 1);
        assert_eq!(wrapper.food_categories.categories[0].food_category_name, "Fruits");
    }
}
```

### Integration Test (`tests/fatsecret_food_categories_test.rs`)
```rust
#[tokio::test]
async fn test_food_categories_binary() {
    let config = common::get_test_config();
    let input = serde_json::json!({
        "fatsecret": config,
        "region": null,
        "language": null
    });

    let output = Command::new("./target/debug/fatsecret_food_categories_get")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
        .unwrap();

    // ... test output parsing
}
```

---

## Implementation Effort

| Task | Effort | Notes |
|------|--------|-------|
| Type definitions | 1 hour | Follow existing patterns |
| Client function | 30 min | Simple HTTP request |
| Binary | 30 min | Standard stdin/stdout contract |
| Windmill script | 15 min | Bash wrapper |
| Unit tests | 1 hour | Deserialization tests |
| Integration tests | 1 hour | Binary E2E tests |
| Documentation | 30 min | Update foods module docs |
| **TOTAL** | **~5 hours** | Low complexity |

---

## Decision: DEFER Implementation

### Rationale

1. **No Current Use Case**: Our meal planning workflow doesn't require category browsing
2. **Low ROI**: Text search already provides excellent food discovery
3. **Static Reference Data**: Categories rarely change; can be fetched on-demand if needed
4. **Premier Tier Only**: Requires higher access tier for limited value
5. **Alternative Solutions**: 
   - `foods.search` handles most discovery needs
   - Favorites/recent foods provide personalization
   - Barcode lookup handles packaged foods

### When to Revisit

Implement this endpoint IF:
- Building a UI food browser with category navigation
- Adding category-based meal planning features
- Implementing advanced food filtering beyond text search
- Customer specifically requests category-based workflows

### Alternative Recommendation

**Instead, prioritize:**
1. `food.brands.get` - More useful for filtering branded vs. generic foods
2. Enhanced search with filters (generic/branded, dietary attributes)
3. Favorite foods and meal templates (already implemented)

---

## References

- **API Documentation:** [docs/fatsecret/api-food-categories-get.md](./api-food-categories-get.md)
- **Related API:** [docs/fatsecret/api-food-sub-categories-get.md](./api-food-sub-categories-get.md)
- **Architecture:** [docs/ARCHITECTURE.md](../ARCHITECTURE.md)
- **Existing Foods Module:** `src/fatsecret/foods/`
- **FatSecret Platform API:** https://platform.fatsecret.com/api/

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

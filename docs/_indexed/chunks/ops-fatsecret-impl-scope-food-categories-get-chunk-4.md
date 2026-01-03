---
doc_id: ops/fatsecret/impl-scope-food-categories-get
chunk_id: ops/fatsecret/impl-scope-food-categories-get#chunk-4
heading_path: ["Implementation Scope: FatSecret food.categories.get.v2", "Proposed Rust Type Design"]
chunk_type: code
tokens: 715
summary: "Proposed Rust Type Design"
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

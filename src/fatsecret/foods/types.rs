//! FatSecret Food Domain Types
//!
//! This module defines all types used in the FatSecret Foods API domain, including
//! foods, servings, nutrition data, and API response structures.
//!
//! # Design Principles
//!
//! 1. **Opaque IDs** - [`FoodId`] and [`ServingId`] are opaque wrappers preventing
//!    accidental mixing of string IDs
//! 2. **Flexible deserialization** - Handle FatSecret's inconsistent JSON (strings vs numbers)
//! 3. **Flattened structures** - Nutrition data embedded in servings via `#[serde(flatten)]`
//! 4. **Optional fields** - Micronutrients and brand names are optional per API contract
//!
//! # Type Hierarchy
//!
//! ```text
//! Food                          # Complete food details
//! ├── food_id: FoodId           # Unique identifier
//! ├── food_name: String         # "Chicken Breast"
//! ├── food_type: String         # "Generic" or "Brand"
//! ├── brand_name: Option        # For branded foods
//! └── servings: FoodServings
//!     └── serving: Vec<Serving>
//!         ├── serving_id: ServingId
//!         ├── serving_description: String    # "1 cup"
//!         ├── metric_serving_amount: Option  # 240.0
//!         ├── metric_serving_unit: Option    # "g"
//!         └── nutrition: Nutrition           # Flattened
//!             ├── calories: f64              # Required macros
//!             ├── protein: f64
//!             ├── carbohydrate: f64
//!             ├── fat: f64
//!             ├── saturated_fat: Option<f64> # Optional details
//!             ├── fiber: Option<f64>
//!             ├── sugar: Option<f64>
//!             └── ... (vitamins, minerals)
//! ```
//!
//! # Key Types
//!
//! ## Core Domain Types
//!
//! - [`Food`] - Complete food with all serving options and nutrition
//! - [`Serving`] - A single serving size with embedded nutrition data
//! - [`Nutrition`] - Macros (protein/carbs/fat) and optional micros/vitamins
//! - [`FoodId`], [`ServingId`] - Type-safe opaque identifiers
//!
//! ## Search & Discovery Types
//!
//! - [`FoodSearchResponse`] - Paginated search results
//! - [`FoodSearchResult`] - Single search result with summary
//! - [`FoodAutocompleteResponse`] - Autocomplete suggestions
//! - [`FoodSuggestion`] - Single suggestion (id + name only)
//!
//! # API Response Mapping
//!
//! FatSecret returns inconsistent JSON shapes. This module handles:
//!
//! - **String/number coercion** - Some APIs return `"123"`, others `123`
//! - **Single item arrays** - `{"serving": {...}}` vs `{"serving": [{...}]}`
//! - **Optional vs required** - Micronutrients may be missing or `null`
//!
//! See [`crate::fatsecret::core::serde_utils`] for custom deserializers.
//!
//! # Examples
//!
//! ## Working with food details
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::types::{Food, FoodId};
//!
//! # fn example(food: Food) {
//! // Find default serving
//! let default_serving = food.servings.serving.iter()
//!     .find(|s| s.is_default == Some(1))
//!     .or_else(|| food.servings.serving.first());
//!
//! if let Some(serving) = default_serving {
//!     println!("{}: {} cal",
//!         serving.serving_description,
//!         serving.nutrition.calories
//!     );
//!     
//!     // Check for fiber data
//!     if let Some(fiber) = serving.nutrition.fiber {
//!         println!("  Fiber: {}g", fiber);
//!     }
//! }
//! # }
//! ```
//!
//! ## Processing search results
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::types::FoodSearchResponse;
//!
//! # fn example(response: FoodSearchResponse) {
//! println!("Showing {} of {} results",
//!     response.foods.len(),
//!     response.total_results
//! );
//!
//! for result in response.foods {
//!     println!("{}: {}", result.food_name, result.food_description);
//!     if let Some(brand) = result.brand_name {
//!         println!("  Brand: {}", brand);
//!     }
//! }
//!
//! // Calculate pagination
//! let total_pages = (response.total_results / response.max_results) + 1;
//! let current_page = response.page_number + 1; // API is 0-indexed
//! println!("Page {}/{}", current_page, total_pages);
//! # }
//! ```
//!
//! ## Creating opaque IDs
//!
//! ```
//! use meal_planner::fatsecret::foods::types::{FoodId, ServingId};
//!
//! // From string slice
//! let food_id = FoodId::new("12345");
//! assert_eq!(food_id.as_str(), "12345");
//!
//! // From String
//! let serving_id = ServingId::from("67890".to_string());
//! assert_eq!(serving_id.to_string(), "67890");
//!
//! // Type safety prevents mixing
//! // let wrong: FoodId = ServingId::new("123"); // Compile error!
//! ```
//!
//! # Nutrition Data Units
//!
//! | Field | Unit | Notes |
//! |-------|------|-------|
//! | `calories` | kcal | Required |
//! | `protein`, `carbohydrate`, `fat` | grams | Required macros |
//! | `saturated_fat`, `fiber`, `sugar` | grams | Optional |
//! | `cholesterol`, `sodium`, `potassium` | milligrams | Optional |
//! | `vitamin_a`, `vitamin_c`, `calcium`, `iron` | % daily value | Optional |
//!
//! # See Also
//!
//! - [`crate::fatsecret::foods::client`] for API client functions
//! - [`crate::fatsecret::core::serde_utils`] for custom deserializers
//! - [FatSecret Platform API Reference](https://platform.fatsecret.com/api/)

use serde::{Deserialize, Serialize};

use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float, deserialize_flexible_int, deserialize_optional_flexible_float,
    deserialize_optional_flexible_int, deserialize_single_or_vec,
};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque food ID from FatSecret API
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct FoodId(String);

impl FoodId {
    /// Creates a new FoodId from the given value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the food ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl From<String> for FoodId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for FoodId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl std::fmt::Display for FoodId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Opaque serving ID from FatSecret API
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct ServingId(String);

impl ServingId {
    /// Creates a new ServingId from the given value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the serving ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl From<String> for ServingId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for ServingId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl std::fmt::Display for ServingId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

// ============================================================================
// Nutrition Information
// ============================================================================

/// Nutrition information for a food serving
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Nutrition {
    /// Calorie content in kcal
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    /// Carbohydrate content in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub carbohydrate: f64,
    /// Protein content in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub protein: f64,
    /// Total fat content in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub fat: f64,
    /// Saturated fat content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub saturated_fat: Option<f64>,
    /// Polyunsaturated fat content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub polyunsaturated_fat: Option<f64>,
    /// Monounsaturated fat content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub monounsaturated_fat: Option<f64>,
    /// Trans fat content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub trans_fat: Option<f64>,
    /// Cholesterol content in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub cholesterol: Option<f64>,
    /// Sodium content in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub sodium: Option<f64>,
    /// Potassium content in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub potassium: Option<f64>,
    /// Dietary fiber content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub fiber: Option<f64>,
    /// Total sugar content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub sugar: Option<f64>,
    /// Added sugars content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub added_sugars: Option<f64>,
    /// Vitamin A as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_a: Option<f64>,
    /// Vitamin C as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_c: Option<f64>,
    /// Vitamin D as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_d: Option<f64>,
    /// Calcium as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub calcium: Option<f64>,
    /// Iron as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub iron: Option<f64>,
}

// ============================================================================
// Serving Information
// ============================================================================

/// A serving size option for a food
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Serving {
    /// Unique identifier for this serving size
    pub serving_id: ServingId,
    /// Human-readable description of the serving (e.g., "1 cup")
    pub serving_description: String,
    /// URL to the serving details on FatSecret
    pub serving_url: String,
    /// Metric equivalent amount (e.g., 240 for 240g)
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub metric_serving_amount: Option<f64>,
    /// Unit for metric serving amount (e.g., "g", "ml")
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub metric_serving_unit: Option<String>,
    /// Number of units in this serving
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
    /// Description of the measurement unit (e.g., "cup", "tbsp")
    pub measurement_description: String,
    /// Whether this is the default serving size (1 = default)
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_int"
    )]
    pub is_default: Option<i32>,
    /// Nutrition information for this serving size
    #[serde(flatten)]
    pub nutrition: Nutrition,
}

// ============================================================================
// Food Information
// ============================================================================

/// Complete food details from FatSecret API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Food {
    /// Unique identifier for this food
    pub food_id: FoodId,
    /// Name of the food
    pub food_name: String,
    /// Type of food (e.g., "Generic", "Brand")
    pub food_type: String,
    /// URL to the food details on FatSecret
    pub food_url: String,
    /// Brand name for branded foods
    #[serde(skip_serializing_if = "Option::is_none")]
    pub brand_name: Option<String>,
    /// Available serving sizes for this food
    pub servings: FoodServings,
}

/// Container for food serving options
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodServings {
    /// List of available serving sizes
    #[serde(rename = "serving", deserialize_with = "deserialize_single_or_vec")]
    pub serving: Vec<Serving>,
}

// ============================================================================
// Search Results
// ============================================================================

/// Single food search result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSearchResult {
    /// Unique identifier for this food
    pub food_id: FoodId,
    /// Name of the food
    pub food_name: String,
    /// Type of food (e.g., "Generic", "Brand")
    pub food_type: String,
    /// Brief description including nutrition summary
    pub food_description: String,
    /// Brand name for branded foods
    #[serde(skip_serializing_if = "Option::is_none")]
    pub brand_name: Option<String>,
    /// URL to the food details on FatSecret
    pub food_url: String,
}

/// Response from foods.search API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSearchResponse {
    /// List of matching foods
    #[serde(
        rename = "food",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub foods: Vec<FoodSearchResult>,
    /// Maximum results per page
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub max_results: i32,
    /// Total number of matching results
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub total_results: i32,
    /// Current page number (0-indexed)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub page_number: i32,
}

// ============================================================================
// Autocomplete Results
// ============================================================================

/// Single food autocomplete suggestion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSuggestion {
    /// Unique identifier for this food
    pub food_id: FoodId,
    /// Name of the suggested food
    pub food_name: String,
}

/// Response from foods.autocomplete API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodAutocompleteResponse {
    /// List of autocomplete suggestions
    #[serde(rename = "suggestion", deserialize_with = "deserialize_single_or_vec")]
    pub suggestions: Vec<FoodSuggestion>,
}

/// FatSecret SDK Foods domain types
///
/// This module defines the core types for the FatSecret Foods API.
/// These types are independent from the Tandoor domain and represent
/// FatSecret's data structures.
///
/// Opaque types are used for IDs to ensure type safety and prevent
/// accidental mixing of different ID types.
import gleam/option.{type Option}

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for FatSecret food IDs
pub opaque type FoodId {
  FoodId(String)
}

/// Create a FoodId from a string
pub fn food_id(id: String) -> FoodId {
  FoodId(id)
}

/// Convert FoodId to string (for API calls)
pub fn food_id_to_string(id: FoodId) -> String {
  case id {
    FoodId(s) -> s
  }
}

/// Opaque type for FatSecret serving IDs
pub opaque type ServingId {
  ServingId(String)
}

/// Create a ServingId from a string
pub fn serving_id(id: String) -> ServingId {
  ServingId(id)
}

/// Convert ServingId to string (for API calls)
pub fn serving_id_to_string(id: ServingId) -> String {
  case id {
    ServingId(s) -> s
  }
}

// ============================================================================
// Nutrition Information
// ============================================================================

/// Nutrition information for a food serving
///
/// Required fields (calories, macros) are always present.
/// Optional micronutrients may be None if not provided by FatSecret.
pub type Nutrition {
  Nutrition(
    /// Energy in kcal
    calories: Float,
    /// Total carbohydrates in grams
    carbohydrate: Float,
    /// Protein in grams
    protein: Float,
    /// Total fat in grams
    fat: Float,
    /// Saturated fat in grams
    saturated_fat: Option(Float),
    /// Polyunsaturated fat in grams
    polyunsaturated_fat: Option(Float),
    /// Monounsaturated fat in grams
    monounsaturated_fat: Option(Float),
    /// Cholesterol in mg
    cholesterol: Option(Float),
    /// Sodium in mg
    sodium: Option(Float),
    /// Potassium in mg
    potassium: Option(Float),
    /// Dietary fiber in grams
    fiber: Option(Float),
    /// Total sugars in grams
    sugar: Option(Float),
    /// Vitamin A as % DV
    vitamin_a: Option(Float),
    /// Vitamin C as % DV
    vitamin_c: Option(Float),
    /// Calcium as % DV
    calcium: Option(Float),
    /// Iron as % DV
    iron: Option(Float),
  )
}

// ============================================================================
// Serving Information
// ============================================================================

/// A serving size option for a food
///
/// FatSecret provides multiple serving options per food (e.g., "1 cup", "100g").
/// Each serving has complete nutrition information.
pub type Serving {
  Serving(
    /// Unique serving identifier
    serving_id: ServingId,
    /// Human-readable serving description (e.g., "1 cup diced")
    serving_description: String,
    /// FatSecret URL for this serving
    serving_url: String,
    /// Metric amount (e.g., 240.0 for "1 cup = 240ml")
    metric_serving_amount: Option(Float),
    /// Metric unit (e.g., "ml", "g")
    metric_serving_unit: Option(String),
    /// Number of units (e.g., 1.0 for "1 cup")
    number_of_units: Float,
    /// Measurement description (e.g., "cup", "tablespoon")
    measurement_description: String,
    /// Complete nutrition information for this serving
    nutrition: Nutrition,
  )
}

// ============================================================================
// Food Information
// ============================================================================

/// Complete food details from food.get.v4 API
///
/// Contains all available information about a food including
/// all serving options and complete nutrition data.
pub type Food {
  Food(
    /// Unique food identifier
    food_id: FoodId,
    /// Food name (e.g., "Apple", "Whole Milk")
    food_name: String,
    /// Food type (e.g., "Brand", "Generic")
    food_type: String,
    /// FatSecret URL for this food
    food_url: String,
    /// Brand name (only for branded foods)
    brand_name: Option(String),
    /// List of available serving options
    servings: List(Serving),
  )
}

// ============================================================================
// Search Results
// ============================================================================

/// Single food search result from foods.search API
///
/// This is a lightweight version of Food used in search results.
/// To get complete details including servings, use food.get.v4.
pub type FoodSearchResult {
  FoodSearchResult(
    /// Unique food identifier
    food_id: FoodId,
    /// Food name
    food_name: String,
    /// Food type (e.g., "Brand", "Generic")
    food_type: String,
    /// Combined description including serving info
    food_description: String,
    /// Brand name (only for branded foods)
    brand_name: Option(String),
    /// FatSecret URL for this food
    food_url: String,
  )
}

/// Response from foods.search API
///
/// Contains paginated search results with metadata.
pub type FoodSearchResponse {
  FoodSearchResponse(
    /// List of matching foods
    foods: List(FoodSearchResult),
    /// Maximum results per page
    max_results: Int,
    /// Total number of matching results
    total_results: Int,
    /// Current page number (0-indexed)
    page_number: Int,
  )
}

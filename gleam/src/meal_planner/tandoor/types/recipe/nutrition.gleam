/// Nutrition information type for Tandoor SDK
///
/// This module defines detailed nutrition information types that can be
/// associated with recipes, including source tracking for nutrition data.
///
/// Unlike the simplified TandoorNutrition type in the main types module,
/// this NutritionInfo type includes an ID and source field for tracking
/// where nutrition data originated from.
import gleam/option.{type Option}

// ============================================================================
// Nutrition Information Types
// ============================================================================

/// Detailed nutrition information with source tracking
///
/// This type represents comprehensive nutrition data for a recipe,
/// including all macronutrients and the ability to track the data source.
///
/// All numeric fields are optional Float values to accommodate:
/// - Missing data from various sources
/// - Recipes where certain nutritional info isn't calculated
/// - Partial nutrition information
///
/// Fields:
/// - id: Unique identifier for this nutrition record
/// - carbohydrates: Total carbohydrates in grams
/// - fats: Total fats in grams
/// - proteins: Total proteins in grams
/// - calories: Total calories (kcal)
/// - source: Where this nutrition data came from (e.g., "USDA", "manual", "calculated")
pub type NutritionInfo {
  NutritionInfo(
    /// Unique identifier for this nutrition information record
    id: Int,
    /// Total carbohydrates in grams (optional)
    carbohydrates: Option(Float),
    /// Total fats in grams (optional)
    fats: Option(Float),
    /// Total proteins in grams (optional)
    proteins: Option(Float),
    /// Total calories in kcal (optional)
    calories: Option(Float),
    /// Source of nutrition data (optional, e.g., "USDA", "manual", "calculated")
    source: Option(String),
  )
}

/// Create a new NutritionInfo with all required fields
///
/// Use this constructor when you have complete nutrition data.
///
/// Example:
/// ```gleam
/// let nutrition = new(
///   id: 1,
///   carbohydrates: Some(45.0),
///   fats: Some(12.0),
///   proteins: Some(25.0),
///   calories: Some(380.0),
///   source: Some("USDA")
/// )
/// ```
pub fn new(
  id id: Int,
  carbohydrates carbohydrates: Option(Float),
  fats fats: Option(Float),
  proteins proteins: Option(Float),
  calories calories: Option(Float),
  source source: Option(String),
) -> NutritionInfo {
  NutritionInfo(
    id: id,
    carbohydrates: carbohydrates,
    fats: fats,
    proteins: proteins,
    calories: calories,
    source: source,
  )
}

/// Create an empty NutritionInfo with only an ID
///
/// Use this when creating a placeholder or when nutrition data
/// will be populated later.
///
/// Example:
/// ```gleam
/// let nutrition = empty(id: 1)
/// ```
pub fn empty(id id: Int) -> NutritionInfo {
  NutritionInfo(
    id: id,
    carbohydrates: option.None,
    fats: option.None,
    proteins: option.None,
    calories: option.None,
    source: option.None,
  )
}

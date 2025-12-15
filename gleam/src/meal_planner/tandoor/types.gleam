/// Tandoor API type definitions
///
/// This module defines all types needed for Tandoor recipe API integration.
/// It includes types for API responses, recipe data, and creation requests.
///
/// The types are structured to match the Tandoor API schema while providing
/// a clear separation between API types and internal application types.
///
/// Note: TandoorFood (2-field) is used for recipe ingredient references only.
/// For full food API operations, use the Food type from meal_planner/tandoor/types/food/food.
import gleam/option.{type Option}

// ============================================================================
// API Response Types
// ============================================================================

/// Paginated recipe list response from Tandoor API
pub type RecipeListResponse {
  RecipeListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(TandoorRecipe),
  )
}

// ============================================================================
// Recipe Types
// ============================================================================

/// Complete Tandoor recipe with all metadata and ingredients
pub type TandoorRecipe {
  TandoorRecipe(
    id: Int,
    name: String,
    description: String,
    servings: Int,
    servings_text: String,
    prep_time: Int,
    cooking_time: Int,
    ingredients: List(TandoorIngredient),
    steps: List(TandoorStep),
    nutrition: Option(TandoorNutrition),
    keywords: List(TandoorKeyword),
    image: Option(String),
    internal_id: Option(String),
    created_at: String,
    updated_at: String,
  )
}

// ============================================================================
// Ingredient Types
// ============================================================================

/// Ingredient with full details including food, unit, and amount
pub type TandoorIngredient {
  TandoorIngredient(
    id: Int,
    food: TandoorFood,
    unit: TandoorUnit,
    amount: Float,
    note: String,
  )
}

/// Food item referenced by ingredient (embedded/simplified representation)
///
/// This is a minimal 2-field representation used ONLY in recipe ingredient references.
/// For full food API operations (get, list, create, update), use the Food type from
/// meal_planner/tandoor/types/food/food which contains all 8 fields.
pub type TandoorFood {
  TandoorFood(id: Int, name: String)
}

/// Measurement unit for ingredients
pub type TandoorUnit {
  TandoorUnit(id: Int, name: String, abbreviation: String)
}

// ============================================================================
// Step Types
// ============================================================================

/// Cooking step with instructions and timing
pub type TandoorStep {
  TandoorStep(id: Int, name: String, instructions: String, time: Int)
}

// ============================================================================
// Nutrition Types
// ============================================================================

/// Nutritional information for a recipe
pub type TandoorNutrition {
  TandoorNutrition(
    calories: Float,
    carbs: Float,
    protein: Float,
    fats: Float,
    fiber: Float,
    sugars: Option(Float),
    sodium: Option(Float),
  )
}

// ============================================================================
// Keyword/Tag Types
// ============================================================================

/// Keyword/tag for recipe categorization
pub type TandoorKeyword {
  TandoorKeyword(id: Int, name: String)
}

// ============================================================================
// Request Types (for creating recipes)
// ============================================================================

/// Request to create a new recipe in Tandoor
pub type TandoorRecipeCreateRequest {
  TandoorRecipeCreateRequest(
    name: String,
    description: String,
    servings: Int,
    servings_text: String,
    prep_time: Int,
    cooking_time: Int,
    ingredients: List(TandoorIngredientCreateRequest),
    steps: List(TandoorStepCreateRequest),
  )
}

/// Request to create an ingredient in a recipe
pub type TandoorIngredientCreateRequest {
  TandoorIngredientCreateRequest(
    food: TandoorFoodCreateRequest,
    unit: TandoorUnitCreateRequest,
    amount: Float,
    note: String,
  )
}

/// Request to create a food item
pub type TandoorFoodCreateRequest {
  TandoorFoodCreateRequest(name: String)
}

/// Request to create/use a measurement unit
pub type TandoorUnitCreateRequest {
  TandoorUnitCreateRequest(name: String)
}

/// Request to create a cooking step
pub type TandoorStepCreateRequest {
  TandoorStepCreateRequest(
    name: String,
    instructions: String,
    time: Option(Int),
  )
}

// ============================================================================
// Error Types
// ============================================================================

/// Errors that can occur when working with Tandoor API
pub type TandoorError {
  /// Network connectivity error
  NetworkError(String)
  /// Request timed out
  ConnectionTimeout
  /// HTTP error with status code and body
  HttpError(status_code: Int, body: String)
  /// API token is invalid or missing
  Unauthorized
  /// Recipe or resource not found
  NotFound
  /// JSON parsing error
  JsonParseError(String)
  /// Recipe format is invalid
  InvalidRecipeFormat(String)
  /// Recipe creation failed
  CreationFailed(String)
}

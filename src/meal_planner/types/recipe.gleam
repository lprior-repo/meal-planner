//// Recipe Types for Meal Planning
////
//// Simplified recipe types for the autonomous meal planning system.
//// Wraps Tandoor Recipe type with nutrition per serving.
////
//// This module provides the MealPlanRecipe opaque type which:
//// - Stores nutritional macros PER SERVING (not total)
//// - Tracks prep and cook time for scheduling
//// - Links to Tandoor recipe ID for full details
//// - Validates servings, prep time, and cook time
////
//// ## Example
////
//// ```gleam
//// import meal_planner/types/recipe
//// import meal_planner/types/macros
//// import meal_planner/id
//// import gleam/option.{None}
////
//// let macros = macros.new(protein: 30.0, fat: 12.0, carbs: 45.0)
//// let recipe_result = recipe.new_meal_plan_recipe(
////   id: id.recipe_id("tandoor-123"),
////   name: "Chicken Stir Fry",
////   servings: 4,
////   macros: macros,
////   image: None,
////   prep_time: 15,
////   cook_time: 20,
//// )
////
//// case recipe_result {
////   Ok(r) -> {
////     recipe.recipe_name(r) // "Chicken Stir Fry"
////     recipe.recipe_total_time(r) // 35 minutes
////     recipe.is_quick_prep(r) // True (15 min <= 15 min)
////   }
////   Error(msg) -> // Validation error
//// }
//// ```
////
//// Part of NORTH STAR epic (meal-planner-918).

import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/id.{type RecipeId}
import meal_planner/types/macros.{type Macros}

// ============================================================================
// Core Types
// ============================================================================

/// Simplified recipe for meal planning with nutrition per serving.
///
/// This is the primary recipe type used in meal plan generation.
/// Opaque type that wraps Tandoor recipe data with per-serving macros.
///
/// ## Key Properties
/// - Macros are PER SERVING (not total)
/// - Servings must be > 0
/// - Prep/cook time must be >= 0
/// - Links to Tandoor recipe via RecipeId
///
/// Use `new_meal_plan_recipe()` to construct with validation.
pub opaque type MealPlanRecipe {
  MealPlanRecipe(
    /// Tandoor recipe ID
    id: RecipeId,
    /// Recipe name
    name: String,
    /// Number of servings this recipe makes
    servings: Int,
    /// Macros PER SERVING (not total)
    macros: Macros,
    /// Optional recipe image URL
    image: Option(String),
    /// Prep time in minutes
    prep_time: Int,
    /// Cook time in minutes
    cook_time: Int,
  )
}

/// Constructor for MealPlanRecipe with validation.
///
/// Creates a MealPlanRecipe with validation for:
/// - Servings > 0
/// - Prep time >= 0
/// - Cook time >= 0
///
/// ## Example
///
/// ```gleam
/// let recipe_result = new_meal_plan_recipe(
///   id: id.recipe_id("tandoor-123"),
///   name: "Grilled Salmon",
///   servings: 2,
///   macros: macros.new(protein: 40.0, fat: 15.0, carbs: 5.0),
///   image: Some("https://example.com/salmon.jpg"),
///   prep_time: 10,
///   cook_time: 15,
/// )
/// ```
///
/// Returns:
/// - Ok(MealPlanRecipe) if all validations pass
/// - Error(String) with descriptive message if validation fails
pub fn new_meal_plan_recipe(
  id id: RecipeId,
  name name: String,
  servings servings: Int,
  macros macros: Macros,
  image image: Option(String),
  prep_time prep_time: Int,
  cook_time cook_time: Int,
) -> Result(MealPlanRecipe, String) {
  // Validate servings > 0
  case servings > 0 {
    False ->
      Error(
        "Recipe servings must be greater than 0, got "
        <> int.to_string(servings),
      )
    True -> {
      // Validate prep_time >= 0
      case prep_time >= 0 {
        False ->
          Error("Prep time must be >= 0, got " <> int.to_string(prep_time))
        True -> {
          // Validate cook_time >= 0
          case cook_time >= 0 {
            False ->
              Error("Cook time must be >= 0, got " <> int.to_string(cook_time))
            True ->
              Ok(MealPlanRecipe(
                id: id,
                name: name,
                servings: servings,
                macros: macros,
                image: image,
                prep_time: prep_time,
                cook_time: cook_time,
              ))
          }
        }
      }
    }
  }
}

/// Get recipe ID
pub fn recipe_id(recipe: MealPlanRecipe) -> RecipeId {
  recipe.id
}

/// Get recipe name
pub fn recipe_name(recipe: MealPlanRecipe) -> String {
  recipe.name
}

/// Get servings count
pub fn recipe_servings(recipe: MealPlanRecipe) -> Int {
  recipe.servings
}

/// Get macros per serving.
///
/// Returns the nutritional macros for a single serving.
/// This is the value stored in the recipe, NOT scaled by servings.
pub fn recipe_macros_per_serving(recipe: MealPlanRecipe) -> Macros {
  recipe.macros
}

/// Get total macros for all servings.
///
/// Calculates the total nutritional macros if you made the entire recipe.
/// Scales per-serving macros by the number of servings.
///
/// ## Example
///
/// ```gleam
/// // Recipe: 30g protein per serving, 4 servings
/// let total = recipe_total_macros(recipe)
/// // Returns Macros with 120g protein (30 * 4)
/// ```
pub fn recipe_total_macros(recipe: MealPlanRecipe) -> Macros {
  let servings_factor = int.to_float(recipe.servings)
  macros.scale(recipe.macros, servings_factor)
}

/// Get recipe image
pub fn recipe_image(recipe: MealPlanRecipe) -> Option(String) {
  recipe.image
}

/// Get prep time
pub fn recipe_prep_time(recipe: MealPlanRecipe) -> Int {
  recipe.prep_time
}

/// Get cook time
pub fn recipe_cook_time(recipe: MealPlanRecipe) -> Int {
  recipe.cook_time
}

/// Get total time (prep + cook).
///
/// Returns the sum of prep_time and cook_time in minutes.
/// Useful for filtering recipes by total time commitment.
pub fn recipe_total_time(recipe: MealPlanRecipe) -> Int {
  recipe.prep_time + recipe.cook_time
}

/// Check if recipe meets quick prep constraint (≤15 minutes prep).
///
/// Returns True if prep_time is 15 minutes or less.
/// Used by meal plan generator to filter quick breakfast options.
///
/// ## Example
///
/// ```gleam
/// case is_quick_prep(recipe) {
///   True -> // Good for busy mornings
///   False -> // Save for weekends
/// }
/// ```
pub fn is_quick_prep(recipe: MealPlanRecipe) -> Bool {
  recipe.prep_time <= 15
}

// ============================================================================
// JSON Serialization
// ============================================================================

/// Encode MealPlanRecipe to JSON.
///
/// Serializes recipe to JSON format for API responses and storage.
/// Image field is encoded as null if None.
pub fn meal_plan_recipe_to_json(recipe: MealPlanRecipe) -> Json {
  let image_json = case recipe.image {
    Some(url) -> json.string(url)
    None -> json.null()
  }

  json.object([
    #("id", id.recipe_id_to_json(recipe.id)),
    #("name", json.string(recipe.name)),
    #("servings", json.int(recipe.servings)),
    #("macros", macros.to_json(recipe.macros)),
    #("image", image_json),
    #("prep_time", json.int(recipe.prep_time)),
    #("cook_time", json.int(recipe.cook_time)),
  ])
}

// ============================================================================
// JSON Deserialization
// ============================================================================

/// Decode MealPlanRecipe from JSON.
///
/// Deserializes JSON to MealPlanRecipe using gleam/dynamic/decode.
/// Handles optional image field gracefully.
pub fn meal_plan_recipe_decoder() -> Decoder(MealPlanRecipe) {
  use id <- decode.field("id", id.recipe_id_decoder())
  use name <- decode.field("name", decode.string)
  use servings <- decode.field("servings", decode.int)
  use macros <- decode.field("macros", macros.decoder())
  use image <- decode.field("image", decode.optional(decode.string))
  use prep_time <- decode.field("prep_time", decode.int)
  use cook_time <- decode.field("cook_time", decode.int)

  decode.success(MealPlanRecipe(
    id: id,
    name: name,
    servings: servings,
    macros: macros,
    image: image,
    prep_time: prep_time,
    cook_time: cook_time,
  ))
}

// ============================================================================
// Display Formatting
// ============================================================================

/// Format recipe as a readable string with macros.
///
/// Returns a human-readable summary of the recipe including:
/// - Name
/// - Servings count
/// - Total time (prep + cook)
/// - Macros per serving
///
/// ## Example
///
/// ```gleam
/// to_string(recipe)
/// // "Chicken Stir Fry (4 servings, 35 min) - 30g P | 12g F | 45g C per serving"
/// ```
pub fn to_string(recipe: MealPlanRecipe) -> String {
  recipe.name
  <> " ("
  <> int.to_string(recipe.servings)
  <> " servings, "
  <> int.to_string(recipe_total_time(recipe))
  <> " min) - "
  <> macros.to_string(recipe.macros)
  <> " per serving"
}

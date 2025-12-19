//// Recipe Types for Meal Planning
////
//// Simplified recipe types for the autonomous meal planning system.
//// Wraps Tandoor Recipe type with nutrition per serving.
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

/// Simplified recipe for meal planning with nutrition per serving
/// This is the primary recipe type used in meal plan generation
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

/// Constructor for MealPlanRecipe with validation
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

/// Get macros per serving
pub fn recipe_macros_per_serving(recipe: MealPlanRecipe) -> Macros {
  recipe.macros
}

/// Get total macros for all servings
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

/// Get total time (prep + cook)
pub fn recipe_total_time(recipe: MealPlanRecipe) -> Int {
  recipe.prep_time + recipe.cook_time
}

/// Check if recipe meets quick prep constraint (≤15 minutes prep)
pub fn is_quick_prep(recipe: MealPlanRecipe) -> Bool {
  recipe.prep_time <= 15
}

// ============================================================================
// JSON Serialization
// ============================================================================

/// Encode MealPlanRecipe to JSON
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

/// Decode MealPlanRecipe from JSON
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

/// Format recipe as a readable string with macros
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

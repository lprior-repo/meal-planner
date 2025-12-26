//// Recipe Types for Meal Planning
////
//// This module provides two recipe types:
////
//// 1. **Ingredient & Recipe (Legacy)**
////    - Ingredient: Simple type from Tandoor API (name, quantity)
////    - Recipe: Full recipe from Tandoor with ingredients, instructions, nutrition
////    - FodmapLevel: Enum for FODMAP tracking (Low, Medium, High)
////    - Used for recipe management and food logging
////
//// 2. **MealPlanRecipe (Simplified for Meal Planning)**
////    - Opaque type for meal plan generation
////    - Stores macros PER SERVING with validation
////    - Tracks prep/cook time for scheduling
////    - Links to Tandoor recipe via RecipeId
////
//// ## Examples
////
//// ```gleam
//// // Legacy Recipe (from Tandoor API)
//// import meal_planner/types/recipe
//// let ingredient = recipe.Ingredient(name: "Chicken", quantity: "2 lbs")
//// let recipe = recipe.Recipe(
////   id: recipe_id("123"),
////   name: "Grilled Chicken",
////   ingredients: [ingredient],
////   instructions: ["Grill to 165F"],
////   macros: macros,
////   servings: 2,
////   category: "Protein",
////   fodmap_level: recipe.Low,
////   vertical_compliant: True,
//// )
////
//// // Meal Plan Recipe (simplified for planning)
//// let recipe_result = recipe.new_meal_plan_recipe(
////   id: id.recipe_id("tandoor-123"),
////   name: "Chicken Stir Fry",
////   servings: 4,
////   macros: macros,
////   image: None,
////   prep_time: 15,
////   cook_time: 20,
//// )
//// ```

import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/id.{type RecipeId}
import meal_planner/types/macros.{type Macros}

// ============================================================================
// Legacy Recipe Types (from Tandoor API)
// ============================================================================

/// Ingredient with name and quantity description.
///
/// Represents a single ingredient in a recipe with human-readable quantity.
/// Example: { name: "Flour", quantity: "2 cups" }
pub type Ingredient {
  Ingredient(name: String, quantity: String)
}

/// FODMAP level for digestive health tracking.
///
/// FODMAP (Fermentable Oligosaccharides, Disaccharides, Monosaccharides, And Polyols)
/// classification helpful for digestive health management.
pub type FodmapLevel {
  Low
  Medium
  High
}

/// Recipe with all nutritional and dietary information.
///
/// This type represents recipes from the Tandoor recipe manager.
/// Recipes are fetched from Tandoor API on-demand rather than being stored locally.
///
/// ## Fields
/// - id: Unique recipe identifier from Tandoor
/// - name: Recipe name
/// - ingredients: List of ingredients with quantities
/// - instructions: Step-by-step cooking instructions
/// - macros: Nutritional macros (protein, fat, carbs)
/// - servings: Number of servings this recipe makes
/// - category: Recipe category (e.g., "Protein", "Vegetable")
/// - fodmap_level: FODMAP classification for digestive health
/// - vertical_compliant: Whether recipe meets Vertical Diet requirements
pub type Recipe {
  Recipe(
    id: RecipeId,
    name: String,
    ingredients: List(Ingredient),
    instructions: List(String),
    macros: Macros,
    servings: Int,
    category: String,
    fodmap_level: FodmapLevel,
    vertical_compliant: Bool,
  )
}

/// Check if recipe meets Vertical Diet requirements.
///
/// Must be explicitly marked compliant AND have low FODMAP rating.
/// Returns True only when both conditions are met.
pub fn is_vertical_diet_compliant(recipe: Recipe) -> Bool {
  recipe.vertical_compliant && recipe.fodmap_level == Low
}

/// Returns macros per serving (macros are already stored per serving).
///
/// The macros field in Recipe represents nutrition per serving.
/// This function provides explicit access to that value.
pub fn macros_per_serving(recipe: Recipe) -> Macros {
  recipe.macros
}

/// Returns total macros for all servings.
///
/// Calculates total nutrition if you made the entire recipe.
/// Scales per-serving macros by the number of servings.
pub fn total_macros(recipe: Recipe) -> Macros {
  let servings_factor = case recipe.servings {
    s if s <= 0 -> 1.0
    s -> int.to_float(s)
  }
  macros.scale(recipe.macros, servings_factor)
}

// ============================================================================
// MealPlanRecipe Type (Simplified for Meal Planning)
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
// JSON Serialization - Legacy Types
// ============================================================================

/// Encode Ingredient to JSON.
pub fn ingredient_to_json(i: Ingredient) -> Json {
  json.object([
    #("name", json.string(i.name)),
    #("quantity", json.string(i.quantity)),
  ])
}

/// Convert FodmapLevel to string.
pub fn fodmap_level_to_string(f: FodmapLevel) -> String {
  case f {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

/// Encode Recipe to JSON.
pub fn recipe_to_json(r: Recipe) -> Json {
  json.object([
    #("id", id.recipe_id_to_json(r.id)),
    #("name", json.string(r.name)),
    #("ingredients", json.array(r.ingredients, ingredient_to_json)),
    #("instructions", json.array(r.instructions, json.string)),
    #("macros", macros.to_json(r.macros)),
    #("servings", json.int(r.servings)),
    #("category", json.string(r.category)),
    #("fodmap_level", json.string(fodmap_level_to_string(r.fodmap_level))),
    #("vertical_compliant", json.bool(r.vertical_compliant)),
  ])
}

// ============================================================================
// JSON Deserialization - Legacy Types
// ============================================================================

/// Decode Ingredient from JSON.
pub fn ingredient_decoder() -> Decoder(Ingredient) {
  use name <- decode.field("name", decode.string)
  use quantity <- decode.field("quantity", decode.string)
  decode.success(Ingredient(name: name, quantity: quantity))
}

/// Decode FodmapLevel from JSON string.
pub fn fodmap_level_decoder() -> Decoder(FodmapLevel) {
  use s <- decode.then(decode.string)
  case s {
    "low" -> decode.success(Low)
    "medium" -> decode.success(Medium)
    "high" -> decode.success(High)
    _ -> decode.failure(Low, "FodmapLevel")
  }
}

/// Decode Recipe from JSON.
pub fn recipe_decoder() -> Decoder(Recipe) {
  use recipe_id <- decode.field("id", id.recipe_id_decoder())
  use name <- decode.field("name", decode.string)
  use ingredients <- decode.field(
    "ingredients",
    decode.list(ingredient_decoder()),
  )
  use instructions <- decode.field("instructions", decode.list(decode.string))
  use macros <- decode.field("macros", macros.decoder())
  use servings <- decode.field("servings", decode.int)
  use category <- decode.field("category", decode.string)
  use fodmap_level <- decode.field("fodmap_level", fodmap_level_decoder())
  use vertical_compliant <- decode.field("vertical_compliant", decode.bool)
  decode.success(Recipe(
    id: recipe_id,
    name: name,
    ingredients: ingredients,
    instructions: instructions,
    macros: macros,
    servings: servings,
    category: category,
    fodmap_level: fodmap_level,
    vertical_compliant: vertical_compliant,
  ))
}

// ============================================================================
// Display Formatting - Legacy Types
// ============================================================================

/// Format ingredient as a readable line (e.g., "- Flour: 2 cups").
pub fn ingredient_to_display_string(ing: Ingredient) -> String {
  "  - " <> ing.name <> ": " <> ing.quantity
}

/// Format ingredient line for shopping list (indented).
pub fn ingredient_to_shopping_list_line(ing: Ingredient) -> String {
  "    - " <> ing.name <> ": " <> ing.quantity
}

/// Format FODMAP level as a readable string.
pub fn fodmap_level_to_display_string(level: FodmapLevel) -> String {
  case level {
    Low -> "Low"
    Medium -> "Medium"
    High -> "High"
  }
}

/// Format Recipe as a complete, readable string.
///
/// Returns a formatted string with:
/// - Recipe name
/// - Ingredients list
/// - Step-by-step instructions
/// - Nutritional macros
pub fn recipe_to_display_string(recipe: Recipe) -> String {
  let ingredients_str =
    list.map(recipe.ingredients, ingredient_to_display_string)
    |> string.join("\n")

  let instructions_str =
    list.index_map(recipe.instructions, fn(inst, i) {
      "  " <> int.to_string(i + 1) <> ". " <> inst
    })
    |> string.join("\n")

  recipe.name
  <> "\n"
  <> "Macros: "
  <> macros.to_string(recipe.macros)
  <> "\n\n"
  <> "Ingredients:\n"
  <> ingredients_str
  <> "\n\n"
  <> "Instructions:\n"
  <> instructions_str
}

// ============================================================================
// JSON Serialization - MealPlanRecipe
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

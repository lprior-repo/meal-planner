/// Recipe decoder for Tandoor SDK
///
/// This module provides JSON decoders for TandoorRecipe types from the API.
/// It follows the gleam/dynamic decode pattern for type-safe JSON parsing.
///
/// The decoders handle:
/// - Required fields (will fail if missing)
/// - Optional fields (use optional for nullable values)
/// - Nested objects (ingredients, steps, nutrition, keywords)
/// - Lists and arrays
import gleam/dynamic/decode
import meal_planner/tandoor/types.{
  type TandoorFood, type TandoorIngredient, type TandoorKeyword,
  type TandoorNutrition, type TandoorRecipe, type TandoorStep, type TandoorUnit,
  TandoorFood, TandoorIngredient, TandoorKeyword, TandoorNutrition,
  TandoorRecipe, TandoorStep, TandoorUnit,
}

// ============================================================================
// Recipe Decoder
// ============================================================================

/// Decode a complete TandoorRecipe from JSON
///
/// This decoder handles all fields of a recipe including nested structures
/// like ingredients, steps, nutrition data, and keywords.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Pasta Carbonara",
///   "description": "Classic Italian pasta dish",
///   "servings": 4,
///   "servings_text": "4 servings",
///   "prep_time": 10,
///   "cooking_time": 20,
///   "ingredients": [...],
///   "steps": [...],
///   "nutrition": {...},
///   "keywords": [...],
///   "image": "https://...",
///   "internal_id": "recipe-123",
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z"
/// }
/// ```
pub fn recipe_decoder() -> decode.Decoder(TandoorRecipe) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use servings <- decode.field("servings", decode.int)
  use servings_text <- decode.field("servings_text", decode.string)
  use prep_time <- decode.field("prep_time", decode.int)
  use cooking_time <- decode.field("cooking_time", decode.int)
  use ingredients <- decode.field(
    "ingredients",
    decode.list(ingredient_decoder()),
  )
  use steps <- decode.field("steps", decode.list(step_decoder()))
  use nutrition <- decode.field(
    "nutrition",
    decode.optional(nutrition_decoder()),
  )
  use keywords <- decode.field("keywords", decode.list(keyword_decoder()))
  use image <- decode.field("image", decode.optional(decode.string))
  use internal_id <- decode.field("internal_id", decode.optional(decode.string))
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(TandoorRecipe(
    id: id,
    name: name,
    description: description,
    servings: servings,
    servings_text: servings_text,
    prep_time: prep_time,
    cooking_time: cooking_time,
    ingredients: ingredients,
    steps: steps,
    nutrition: nutrition,
    keywords: keywords,
    image: image,
    internal_id: internal_id,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

// ============================================================================
// Ingredient Decoders
// ============================================================================

/// Decode a TandoorIngredient from JSON
///
/// Handles ingredient objects with nested food and unit data.
pub fn ingredient_decoder() -> decode.Decoder(TandoorIngredient) {
  use id <- decode.field("id", decode.int)
  use food <- decode.field("food", food_decoder())
  use unit <- decode.field("unit", unit_decoder())
  use amount <- decode.field("amount", decode.float)
  use note <- decode.field("note", decode.string)

  decode.success(TandoorIngredient(
    id: id,
    food: food,
    unit: unit,
    amount: amount,
    note: note,
  ))
}

/// Decode a TandoorFood from JSON
///
/// Simple food item with ID and name.
pub fn food_decoder() -> decode.Decoder(TandoorFood) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)

  decode.success(TandoorFood(id: id, name: name))
}

/// Decode a TandoorUnit from JSON
///
/// Measurement unit with ID, name, and abbreviation.
pub fn unit_decoder() -> decode.Decoder(TandoorUnit) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use abbreviation <- decode.field("abbreviation", decode.string)

  decode.success(TandoorUnit(id: id, name: name, abbreviation: abbreviation))
}

// ============================================================================
// Step Decoder
// ============================================================================

/// Decode a TandoorStep from JSON
///
/// Cooking step with instructions and timing.
pub fn step_decoder() -> decode.Decoder(TandoorStep) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use instructions <- decode.field("instructions", decode.string)
  use time <- decode.field("time", decode.int)

  decode.success(TandoorStep(
    id: id,
    name: name,
    instructions: instructions,
    time: time,
  ))
}

// ============================================================================
// Nutrition Decoder
// ============================================================================

/// Decode TandoorNutrition from JSON
///
/// Handles nutrition data with optional sugar and sodium fields.
pub fn nutrition_decoder() -> decode.Decoder(TandoorNutrition) {
  use calories <- decode.field("calories", decode.float)
  use carbs <- decode.field("carbs", decode.float)
  use protein <- decode.field("protein", decode.float)
  use fats <- decode.field("fats", decode.float)
  use fiber <- decode.field("fiber", decode.float)
  use sugars <- decode.field("sugars", decode.optional(decode.float))
  use sodium <- decode.field("sodium", decode.optional(decode.float))

  decode.success(TandoorNutrition(
    calories: calories,
    carbs: carbs,
    protein: protein,
    fats: fats,
    fiber: fiber,
    sugars: sugars,
    sodium: sodium,
  ))
}

// ============================================================================
// Keyword Decoder
// ============================================================================

/// Decode a TandoorKeyword from JSON
///
/// Simple keyword/tag with ID and name.
pub fn keyword_decoder() -> decode.Decoder(TandoorKeyword) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)

  decode.success(TandoorKeyword(id: id, name: name))
}

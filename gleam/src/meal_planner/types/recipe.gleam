/// Recipe types and operations
///
/// Represents recipes from the Tandoor recipe manager.
/// Recipes are fetched from Tandoor API on-demand rather than being stored locally.

import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/string
import meal_planner/id.{recipe_id_decoder, recipe_id_to_json}
import meal_planner/types.{
  type FodmapLevel, type Ingredient, type Macros, type Recipe, High, Ingredient,
  Low, Medium, Recipe, macros_decoder, macros_scale, macros_to_json,
  macros_to_string,
}

/// Check if recipe meets Vertical Diet requirements
/// Must be explicitly marked compliant and have low FODMAP
pub fn is_vertical_diet_compliant(recipe: Recipe) -> Bool {
  recipe.vertical_compliant && recipe.fodmap_level == Low
}

/// Returns macros per serving (macros are already stored per serving)
pub fn macros_per_serving(recipe: Recipe) -> Macros {
  recipe.macros
}

/// Returns total macros for all servings
pub fn total_macros(recipe: Recipe) -> Macros {
  let servings = case recipe.servings {
    s if s <= 0 -> 1
    s -> s
  }
  macros_scale(recipe.macros, int_to_float(servings))
}

// ============================================================================
// JSON Serialization
// ============================================================================

pub fn ingredient_to_json(i: Ingredient) -> Json {
  json.object([
    #("name", json.string(i.name)),
    #("quantity", json.string(i.quantity)),
  ])
}

pub fn fodmap_level_to_string(f: FodmapLevel) -> String {
  case f {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
}

pub fn recipe_to_json(r: Recipe) -> Json {
  json.object([
    #("id", recipe_id_to_json(r.id)),
    #("name", json.string(r.name)),
    #("ingredients", json.array(r.ingredients, ingredient_to_json)),
    #("instructions", json.array(r.instructions, json.string)),
    #("macros", macros_to_json(r.macros)),
    #("servings", json.int(r.servings)),
    #("category", json.string(r.category)),
    #("fodmap_level", json.string(fodmap_level_to_string(r.fodmap_level))),
    #("vertical_compliant", json.bool(r.vertical_compliant)),
  ])
}

// ============================================================================
// JSON Deserialization
// ============================================================================

pub fn fodmap_level_decoder() -> Decoder(FodmapLevel) {
  use s <- decode.then(decode.string)
  case s {
    "low" -> decode.success(Low)
    "medium" -> decode.success(Medium)
    "high" -> decode.success(High)
    _ -> decode.failure(Low, "FodmapLevel")
  }
}

pub fn ingredient_decoder() -> Decoder(Ingredient) {
  use name <- decode.field("name", decode.string)
  use quantity <- decode.field("quantity", decode.string)
  decode.success(Ingredient(name: name, quantity: quantity))
}

pub fn recipe_decoder() -> Decoder(Recipe) {
  use recipe_id <- decode.field("id", recipe_id_decoder())
  use name <- decode.field("name", decode.string)
  use ingredients <- decode.field(
    "ingredients",
    decode.list(ingredient_decoder()),
  )
  use instructions <- decode.field("instructions", decode.list(decode.string))
  use macros_val <- decode.field("macros", macros_decoder())
  use servings <- decode.field("servings", decode.int)
  use category <- decode.field("category", decode.string)
  use fodmap_level <- decode.field("fodmap_level", fodmap_level_decoder())
  use vertical_compliant <- decode.field("vertical_compliant", decode.bool)
  decode.success(Recipe(
    id: recipe_id,
    name: name,
    ingredients: ingredients,
    instructions: instructions,
    macros: macros_val,
    servings: servings,
    category: category,
    fodmap_level: fodmap_level,
    vertical_compliant: vertical_compliant,
  ))
}

// ============================================================================
// Display Formatting
// ============================================================================

/// Format ingredient as a readable line (e.g., "- Flour: 2 cups")
pub fn ingredient_to_display_string(ing: Ingredient) -> String {
  "  - " <> ing.name <> ": " <> ing.quantity
}

/// Format a single ingredient line for shopping list (indented)
pub fn ingredient_to_shopping_list_line(ing: Ingredient) -> String {
  "    - " <> ing.name <> ": " <> ing.quantity
}

/// Format FODMAP level as a readable string
pub fn fodmap_level_to_display_string(level: FodmapLevel) -> String {
  case level {
    Low -> "Low"
    Medium -> "Medium"
    High -> "High"
  }
}

/// Format recipe as a complete, readable string
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
  <> macros_to_string(recipe.macros)
  <> "\n\n"
  <> "Ingredients:\n"
  <> ingredients_str
  <> "\n\n"
  <> "Instructions:\n"
  <> instructions_str
}

// ============================================================================
// Helper Functions
// ============================================================================

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

import gleam/int

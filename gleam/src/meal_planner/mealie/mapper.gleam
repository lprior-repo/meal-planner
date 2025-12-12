//// Mapper for converting Mealie API types to internal meal planner types
//// Handles conversion from MealieRecipe to Recipe with nutrition parsing

import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/string
import meal_planner/id
import meal_planner/mealie/types as mealie
import meal_planner/types.{
  type Ingredient, type Macros, type Recipe, Ingredient, Low, Macros, Recipe,
}

// ============================================================================
// Main Conversion Functions
// ============================================================================

/// Convert a MealieRecipe to internal Recipe type
///
/// This is the primary conversion function for integrating Mealie recipes into
/// the meal planner. It transforms Mealie's API format into our internal domain type.
///
/// Conversions:
/// - ID: Generated from Mealie slug with "mealie-" prefix
/// - Macros: Parsed from Mealie's nutrition strings (e.g., "30g", "150 kcal")
/// - Servings: Extracted from recipeYield string
/// - Category: First recipe category or "Uncategorized"
/// - Defaults: fodmap_level=Low, vertical_compliant=False
///
/// Example:
/// ```gleam
/// let mealie_recipe = fetch_from_api()
/// let recipe = mealie_to_recipe(mealie_recipe)
/// // recipe.id will be RecipeId("mealie-beef-stew")
/// ```
pub fn mealie_to_recipe(mealie_recipe: mealie.MealieRecipe) -> Recipe {
  let recipe_id = id.recipe_id("mealie-" <> mealie_recipe.slug)
  let ingredients =
    list.map(mealie_recipe.recipe_ingredient, mealie_to_ingredient)
  let instructions =
    list.map(mealie_recipe.recipe_instructions, fn(instr) { instr.text })
  let macros = mealie_to_macros(mealie_recipe.nutrition)
  let servings = parse_recipe_yield(mealie_recipe.recipe_yield)

  // Determine category from first category or use "Uncategorized"
  let category = case mealie_recipe.recipe_category {
    [first, ..] -> first.name
    [] -> "Uncategorized"
  }

  Recipe(
    id: recipe_id,
    name: mealie_recipe.name,
    ingredients: ingredients,
    instructions: instructions,
    macros: macros,
    servings: servings,
    category: category,
    fodmap_level: Low,
    // Default to Low
    vertical_compliant: False,
  )
}

/// Convert a MealieIngredient to internal Ingredient type
/// Uses the display field as the primary source, falls back to food name or note
pub fn mealie_to_ingredient(mealie_ing: mealie.MealieIngredient) -> Ingredient {
  let name = case mealie_ing.display {
    "" ->
      case mealie_ing.food {
        Some(food) -> food.name
        None ->
          case mealie_ing.note {
            Some(note) -> note
            None -> "Unknown ingredient"
          }
      }
    display -> display
  }

  let quantity = case mealie_ing.quantity, mealie_ing.unit {
    Some(qty), Some(unit) ->
      float_to_string_rounded(qty) <> " " <> unit.abbreviation
    Some(qty), None -> float_to_string_rounded(qty)
    None, Some(unit) -> unit.abbreviation
    None, None ->
      case mealie_ing.original_text {
        Some(text) -> text
        None -> "to taste"
      }
  }

  Ingredient(name: name, quantity: quantity)
}

/// Convert MealieNutrition to internal Macros type
/// Parses nutrition strings like "150 kcal", "30g" to floats
/// Maps: fatContent -> fat, proteinContent -> protein, carbohydrateContent -> carbs
/// Defaults to 0.0 if nutrition is None or parsing fails
pub fn mealie_to_macros(nutrition: Option(mealie.MealieNutrition)) -> Macros {
  case nutrition {
    None -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
    Some(nutr) -> {
      let protein = parse_nutrition_string(nutr.protein_content)
      let fat = parse_nutrition_string(nutr.fat_content)
      let carbs = parse_nutrition_string(nutr.carbohydrate_content)
      Macros(protein: protein, fat: fat, carbs: carbs)
    }
  }
}

/// Parse recipe yield string to extract servings count
/// Examples: "4 servings" -> 4, "6" -> 6, "serves 8" -> 8
/// Defaults to 1 if parsing fails
pub fn parse_recipe_yield(yield: Option(String)) -> Int {
  case yield {
    None -> 1
    Some(yield_str) -> {
      // Try to extract the first number from the string
      case extract_first_number(yield_str) {
        Some(n) if n > 0 -> n
        _ -> 1
      }
    }
  }
}

// ============================================================================
// Helper Functions for Nutrition Parsing
// ============================================================================

/// Parse nutrition string to float (handles "100 kcal", "15g", "30.5", etc.)
/// Returns 0.0 if parsing fails
fn parse_nutrition_string(value: Option(String)) -> Float {
  case value {
    None -> 0.0
    Some(s) -> extract_number(s) |> option.unwrap(0.0)
  }
}

/// Extract the first numeric value from a string
/// Handles: "150", "150.5", "150 kcal", "15g", "30.5 grams"
fn extract_number(s: String) -> Option(Float) {
  // Clean up the string: trim whitespace and lowercase
  let cleaned = string.trim(s)

  // Try to find a number pattern (digits with optional decimal point)
  case parse_number_regex(cleaned) {
    Ok(num_str) ->
      case float.parse(num_str) {
        Ok(f) -> Some(f)
        Error(_) ->
          // Try parsing as int and converting to float
          case int.parse(num_str) {
            Ok(i) -> Some(int.to_float(i))
            Error(_) -> None
          }
      }
    Error(_) -> None
  }
}

/// Extract the first integer from a string using regex
fn extract_first_number(s: String) -> Option(Int) {
  case parse_number_regex(s) {
    Ok(num_str) ->
      case int.parse(num_str) {
        Ok(i) -> Some(i)
        Error(_) -> None
      }
    Error(_) -> None
  }
}

/// Use regex to extract the first number pattern from a string
fn parse_number_regex(s: String) -> Result(String, Nil) {
  // Pattern matches: optional minus, digits, optional decimal point and more digits
  let assert Ok(re) = regexp.from_string("-?\\d+\\.?\\d*")

  case regexp.scan(re, s) {
    [match, ..] -> Ok(match.content)
    [] -> Error(Nil)
  }
}

/// Format float to string with 1 decimal place, removing unnecessary zeros
fn float_to_string_rounded(f: Float) -> String {
  // Round to 1 decimal place
  let rounded = int.to_float(float.round(f *. 10.0)) /. 10.0

  // Check if it's a whole number
  case float.truncate(rounded) == float.round(rounded) {
    True -> int.to_string(float.truncate(rounded))
    False -> {
      let whole = float.truncate(rounded)
      let frac_part = rounded -. int.to_float(whole)
      let frac = float.round(frac_part *. 10.0)
      int.to_string(whole) <> "." <> int.to_string(frac)
    }
  }
}

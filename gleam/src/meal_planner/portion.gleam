/// Portion calculation module for scaling recipes to hit macro targets
///
/// This module works with both Recipe domain types and mealie.MealieRecipe directly.
/// Portion calculations are source-agnostic - they work with any Recipe
/// regardless of origin (Mealie, custom, etc).
///
/// Ported from Go implementation in main.go
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/id
import meal_planner/mealie/types as mealie
import meal_planner/types.{
  type FodmapLevel, type Macros, type Recipe, Low, macros_calories, macros_scale,
  
}

/// PortionCalculation represents a scaled recipe portion
pub type PortionCalculation {
  PortionCalculation(
    recipe: Recipe,
    scale_factor: Float,
    scaled_macros: Macros,
    meets_target: Bool,
    variance: Float,
  )
}

/// Calculate absolute value of a float
fn abs(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}

/// CalculatePortionForTarget scales a recipe to hit target macros
/// Prioritizes hitting protein target since it's the key constraint in Vertical Diet
pub fn calculate_portion_for_target(
  recipe: Recipe,
  target_macros: Macros,
) -> PortionCalculation {
  // If recipe has no macros defined, return 1.0 scale factor
  let has_no_macros =
    recipe.macros.protein == 0.0
    && recipe.macros.fat == 0.0
    && recipe.macros.carbs == 0.0

  case has_no_macros {
    True ->
      PortionCalculation(
        recipe: recipe,
        scale_factor: 1.0,
        scaled_macros: recipe.macros,
        meets_target: False,
        variance: 100.0,
      )
    False -> {
      // Calculate scale factor based on protein (primary macro)
      let scale_factor = case
        recipe.macros.protein >. 0.0 && target_macros.protein >. 0.0
      {
        True -> target_macros.protein /. recipe.macros.protein
        False -> {
          // Fallback to calories if no protein
          let recipe_calories = macros_calories(recipe.macros)
          let target_calories = macros_calories(target_macros)
          case recipe_calories >. 0.0 && target_calories >. 0.0 {
            True -> target_calories /. recipe_calories
            False -> 1.0
          }
        }
      }

      // Cap scale factor to reasonable range (0.25x to 4x)
      let capped_scale = case scale_factor {
        s if s <. 0.25 -> 0.25
        s if s >. 4.0 -> 4.0
        s -> s
      }

      // Calculate scaled macros
      let scaled_macros = macros_scale(recipe.macros, capped_scale)

      // Calculate variance from target
      let protein_var = case target_macros.protein >. 0.0 {
        True -> {
          let diff = scaled_macros.protein -. target_macros.protein
          abs(diff /. target_macros.protein)
        }
        False -> 0.0
      }

      let fat_var = case target_macros.fat >. 0.0 {
        True -> {
          let diff = scaled_macros.fat -. target_macros.fat
          abs(diff /. target_macros.fat)
        }
        False -> 0.0
      }

      let carbs_var = case target_macros.carbs >. 0.0 {
        True -> {
          let diff = scaled_macros.carbs -. target_macros.carbs
          abs(diff /. target_macros.carbs)
        }
        False -> 0.0
      }

      // Average variance across macros
      let variance = { protein_var +. fat_var +. carbs_var } /. 3.0 *. 100.0

      // Check if within 5% tolerance (on protein primarily)
      let meets_target = protein_var <=. 0.05

      PortionCalculation(
        recipe: recipe,
        scale_factor: capped_scale,
        scaled_macros: scaled_macros,
        meets_target: meets_target,
        variance: variance,
      )
    }
  }
}

/// CalculateDailyPortions distributes daily macro targets across meals
pub fn calculate_daily_portions(
  daily_macros: Macros,
  meals_per_day: Int,
  recipes: List(Recipe),
) -> List(PortionCalculation) {
  case meals_per_day <= 0 {
    True -> []
    False -> {
      // Divide daily macros evenly across meals
      let meals_float = int_to_float(meals_per_day)
      let per_meal_macros =
        Macros(
          protein: daily_macros.protein /. meals_float,
          fat: daily_macros.fat /. meals_float,
          carbs: daily_macros.carbs /. meals_float,
        )

      // Calculate portion for each recipe
      list.map(recipes, fn(recipe) {
        calculate_portion_for_target(recipe, per_meal_macros)
      })
    }
  }
}

/// Helper function to extract macros from mealie.MealieRecipe nutrition
/// Returns Macros with zeros if nutrition is not available
fn mealie_recipe_macros(recipe: mealie.MealieRecipe) -> Macros {
  case recipe.nutrition {
    None -> Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
    Some(nutrition) -> {
      let protein = parse_nutrition_value(nutrition.protein_content)
      let fat = parse_nutrition_value(nutrition.fat_content)
      let carbs = parse_nutrition_value(nutrition.carbohydrate_content)
      Macros(protein: protein, fat: fat, carbs: carbs)
    }
  }
}

/// Parse nutrition string to float (handles "100g", "15", "30.5", etc.)
/// Returns 0.0 if parsing fails
fn parse_nutrition_value(value: Option(String)) -> Float {
  case value {
    None -> 0.0
    Some(s) ->
      case extract_float_from_string(s) {
        Ok(f) -> f
        Error(_) -> 0.0
      }
  }
}

/// Extract float from a string (handles "100g", "30.5", etc.)
fn extract_float_from_string(s: String) -> Result(Float, Nil) {
  let trimmed = string_trim(s)
  // Try to parse the whole string as float first
  case float_parse(trimmed) {
    Ok(f) -> Ok(f)
    Error(_) -> {
      // Try to extract digits before unit (e.g., "100" from "100g")
      case extract_numeric_prefix(trimmed) {
        Some(num_str) ->
          case float_parse(num_str) {
            Ok(f) -> Ok(f)
            Error(_) -> Error(Nil)
          }
        None -> Error(Nil)
      }
    }
  }
}

/// Extract numeric prefix from a string (handles "100g" -> "100")
fn extract_numeric_prefix(s: String) -> Option(String) {
  case string_length(s) {
    0 -> None
    _ -> {
      // Find the first non-numeric character
      case find_first_non_numeric(s, 0) {
        0 -> None
        pos -> Some(string_substring(s, 0, pos))
      }
    }
  }
}

/// Find position of first non-numeric character (including decimal point)
fn find_first_non_numeric(s: String, pos: Int) -> Int {
  case pos >= string_length(s) {
    True -> pos
    False -> {
      let char = string_get_char_at(s, pos)
      case char == "." || char == "-" || is_digit(char) {
        True -> find_first_non_numeric(s, pos + 1)
        False -> pos
      }
    }
  }
}

/// Check if character is a digit
fn is_digit(c: String) -> Bool {
  case c {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    _ -> False
  }
}

/// CalculatePortionForMealieRecipe scales a mealie.MealieRecipe to hit target macros
/// Prioritizes hitting protein target since it's the key constraint in Vertical Diet
pub fn calculate_portion_for_mealie_recipe(
  recipe: mealie.MealieRecipe,
  target_macros: Macros,
) -> PortionCalculation {
  let recipe_macros = mealie_recipe_macros(recipe)

  // If recipe has no macros defined, return 1.0 scale factor
  let has_no_macros =
    recipe_macros.protein == 0.0
    && recipe_macros.fat == 0.0
    && recipe_macros.carbs == 0.0

  case has_no_macros {
    True ->
      PortionCalculation(
        recipe: Recipe(
          id: meal_recipe_id(recipe),
          name: recipe.name,
          ingredients: [],
          instructions: [],
          macros: recipe_macros,
          servings: 1,
          category: recipe_category(recipe),
          fodmap_level: Low,
          vertical_compliant: False,
        ),
        scale_factor: 1.0,
        scaled_macros: recipe_macros,
        meets_target: False,
        variance: 100.0,
      )
    False -> {
      // Calculate scale factor based on protein (primary macro)
      let scale_factor = case
        recipe_macros.protein >. 0.0 && target_macros.protein >. 0.0
      {
        True -> target_macros.protein /. recipe_macros.protein
        False -> {
          // Fallback to calories if no protein
          let recipe_calories = macros_calories(recipe_macros)
          let target_calories = macros_calories(target_macros)
          case recipe_calories >. 0.0 && target_calories >. 0.0 {
            True -> target_calories /. recipe_calories
            False -> 1.0
          }
        }
      }

      // Cap scale factor to reasonable range (0.25x to 4x)
      let capped_scale = case scale_factor {
        s if s <. 0.25 -> 0.25
        s if s >. 4.0 -> 4.0
        s -> s
      }

      // Calculate scaled macros
      let scaled_macros = macros_scale(recipe_macros, capped_scale)

      // Calculate variance from target
      let protein_var = case target_macros.protein >. 0.0 {
        True -> {
          let diff = scaled_macros.protein -. target_macros.protein
          abs(diff /. target_macros.protein)
        }
        False -> 0.0
      }

      let fat_var = case target_macros.fat >. 0.0 {
        True -> {
          let diff = scaled_macros.fat -. target_macros.fat
          abs(diff /. target_macros.fat)
        }
        False -> 0.0
      }

      let carbs_var = case target_macros.carbs >. 0.0 {
        True -> {
          let diff = scaled_macros.carbs -. target_macros.carbs
          abs(diff /. target_macros.carbs)
        }
        False -> 0.0
      }

      // Average variance across macros
      let variance = { protein_var +. fat_var +. carbs_var } /. 3.0 *. 100.0

      // Check if within 5% tolerance (on protein primarily)
      let meets_target = protein_var <=. 0.05

      PortionCalculation(
        recipe: Recipe(
          id: meal_recipe_id(recipe),
          name: recipe.name,
          ingredients: [],
          instructions: [],
          macros: scaled_macros,
          servings: 1,
          category: recipe_category(recipe),
          fodmap_level: Low,
          vertical_compliant: False,
        ),
        scale_factor: capped_scale,
        scaled_macros: scaled_macros,
        meets_target: meets_target,
        variance: variance,
      )
    }
  }
}

/// Helper: Convert mealie.MealieRecipe ID to RecipeId
fn meal_recipe_id(recipe: mealie.MealieRecipe) -> id.RecipeId {
  id.recipe_id("mealie-" <> recipe.slug)
}

/// Helper: Extract category from mealie.MealieRecipe
fn recipe_category(recipe: mealie.MealieRecipe) -> String {
  case recipe.recipe_category {
    [first, ..] -> first.name
    [] -> "Uncategorized"
  }
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

// ============================================================================
// String helper functions for Mealie nutrition parsing
// ============================================================================

@external(erlang, "string", "trim")
fn string_trim(s: String) -> String

@external(erlang, "erlang", "float")
fn float_parse(s: String) -> Result(Float, Nil)

@external(erlang, "string", "length")
fn string_length(s: String) -> Int

@external(erlang, "string", "slice")
fn string_substring(s: String, start: Int, len: Int) -> String

@external(erlang, "string", "sub_string")
fn string_get_char_at(s: String, pos: Int) -> String

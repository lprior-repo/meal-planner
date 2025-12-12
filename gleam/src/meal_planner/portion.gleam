/// Portion calculation module for scaling recipes to hit macro targets
///
/// This module works with Recipe domain types for portion calculations.
/// Portion calculations work with any Recipe regardless of origin.
///
/// Ported from Go implementation in main.go
import gleam/float as gleam_float
import gleam/int as gleam_int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string as gleam_string
import meal_planner/id
import meal_planner/types.{
  type Macros, type Recipe, Macros, macros_calories, macros_scale,
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

fn int_to_float(n: Int) -> Float {
  gleam_int.to_float(n)
}

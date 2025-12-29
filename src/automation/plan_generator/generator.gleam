//// Meal Plan Generation Core Logic
////
//// Implements the main generation algorithm:
//// - Target macro calculation from FatSecret profile
//// - Grocery list and macro summary placeholders
//// - Helper functions

import gleam/dict
import gleam/option.{None, Some}
import meal_planner/fatsecret/profile/types as fatsecret_profile
import meal_planner/generator/types as gen_types
import meal_planner/generator/weekly
import meal_planner/grocery_list
import meal_planner/types/macros.{type Macros, Macros, zero}

/// Calculate target macros from FatSecret profile
///
/// Uses calorie goal if available, otherwise uses defaults
pub fn calculate_target_macros(profile: fatsecret_profile.Profile) -> Macros {
  let daily_calories = case profile.calorie_goal {
    Some(cals) -> int_to_float(cals)
    None -> 2000.0
    // Default to 2000 cal/day
  }

  // Standard macro split: 30% protein, 30% fat, 40% carbs
  let protein_cals = daily_calories *. 0.3
  let fat_cals = daily_calories *. 0.3
  let carb_cals = daily_calories *. 0.4

  Macros(
    protein: protein_cals /. 4.0,
    // 4 cal/g
    fat: fat_cals /. 9.0,
    // 9 cal/g
    carbs: carb_cals /. 4.0,
  )
}

/// Create placeholder grocery list
/// TODO: Implement actual grocery list aggregation from meal plan
pub fn create_placeholder_grocery_list() -> grocery_list.GroceryList {
  grocery_list.GroceryList(by_category: dict.new(), all_items: [])
}

/// Create placeholder macro summary
/// TODO: Implement actual macro summary calculation from meal plan
pub fn create_placeholder_macro_summary(
  _plan: weekly.WeeklyMealPlan,
) -> gen_types.WeeklyMacros {
  gen_types.WeeklyMacros(
    weekly_total: zero(),
    daily_average: zero(),
    daily_breakdowns: [],
  )
}

/// Convert Int to Float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

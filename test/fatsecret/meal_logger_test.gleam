/// FatSecret sync tests
///
/// Tests for syncing meal plans to FatSecret diary with exact macro tracking
import gleam/option.{None}
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/meal_logger
import meal_planner/id
import meal_planner/types/macros.{Macros}
import meal_planner/types/recipe

pub fn main() {
  gleeunit.main()
}

/// Test: FatSecret sync logs meal with exact macros
///
/// Requirement: Log meal to FatSecret diary with exact nutrition calculated from recipe
///
/// Given: A complete meal plan with Monday breakfast (Protein Pancakes, 2 servings)
/// When: We sync the meal to FatSecret diary
/// Then:
///   - Calories logged = exact recipe nutrition × servings
///   - FatSecret diary updated with exact macros
///   - No rounding errors (exact match)
///
/// Data from test/fixtures/meal_plan/complete_week_balanced.json:
///   Monday breakfast:
///     - Recipe: Protein Pancakes (recipe-101)
///     - Recipe servings: 2
///     - Per-serving macros: protein=25.0g, fat=9.0g, carbs=32.5g
///     - Consumed servings: 2
///     - Total macros logged: protein=50.0g, fat=18.0g, carbs=65.0g
///     - Calories: (50.0 * 4) + (18.0 * 9) + (65.0 * 4) = 200 + 162 + 260 = 622.0
pub fn fatsecret_sync_logs_meal_with_exact_macros_test() {
  // Create recipe with per-serving macros
  // The fixture shows 2 servings with total: P=50, F=18, C=65
  // So per-serving is: P=25, F=9, C=32.5
  let per_serving_macros = Macros(protein: 25.0, fat: 9.0, carbs: 32.5)

  let assert Ok(test_recipe) =
    recipe.new_meal_plan_recipe(
      id: id.recipe_id("recipe-101"),
      name: "Protein Pancakes",
      servings: 2,
      macros: per_serving_macros,
      image: None,
      prep_time: 10,
      cook_time: 15,
    )

  // Sync 2 servings to FatSecret
  let result =
    meal_logger.sync_meal_to_fatsecret(
      recipe: test_recipe,
      servings: 2,
      date: "2025-12-22",
      meal_type: "breakfast",
    )

  // Verify result
  should.be_ok(result)

  let assert Ok(entry) = result

  // Verify exact macros (total for 2 servings)
  should.equal(entry.recipe_id, "recipe-101")
  should.equal(entry.meal_type, "breakfast")
  should.equal(entry.date, "2025-12-22")
  should.equal(entry.protein_g, 50.0)
  should.equal(entry.fat_g, 18.0)
  should.equal(entry.carbs_g, 65.0)
  should.equal(entry.calories, 622.0)
}

import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/portion
import shared/types.{Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// Test PortionCalculation struct and basic scaling
pub fn calculate_portion_for_target_basic_test() {
  let recipe =
    Recipe(
      id: "steak-and-rice",
      name: "Steak and Rice",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 50.0, fat: 20.0, carbs: 30.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let target = Macros(protein: 100.0, fat: 40.0, carbs: 60.0)

  let result = portion.calculate_portion_for_target(recipe, target)

  // Should scale by 2x to hit protein target
  result.scale_factor
  |> should.equal(2.0)

  result.scaled_macros.protein
  |> should.equal(100.0)

  result.meets_target
  |> should.equal(True)
}

// Test scaling with protein as primary constraint
pub fn calculate_portion_prioritizes_protein_test() {
  let recipe =
    Recipe(
      id: "chicken-breast",
      name: "Chicken Breast",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 40.0, fat: 5.0, carbs: 0.0),
      servings: 1,
      category: "chicken",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let target = Macros(protein: 60.0, fat: 15.0, carbs: 50.0)

  let result = portion.calculate_portion_for_target(recipe, target)

  // Should scale to 1.5x based on protein (60/40 = 1.5)
  result.scale_factor
  |> should.equal(1.5)

  result.scaled_macros.protein
  |> should.equal(60.0)

  // Fat will be 7.5 (not 15), carbs will be 0 (not 50)
  result.scaled_macros.fat
  |> should.equal(7.5)
}

// Test scale factor capping at 4x maximum
pub fn calculate_portion_caps_scale_factor_max_test() {
  let recipe =
    Recipe(
      id: "light-meal",
      name: "Light Meal",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 10.0),
      servings: 1,
      category: "variety",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let target = Macros(protein: 200.0, fat: 100.0, carbs: 200.0)

  let result = portion.calculate_portion_for_target(recipe, target)

  // Should cap at 4.0x, not 20x (200/10)
  result.scale_factor
  |> should.equal(4.0)

  result.scaled_macros.protein
  |> should.equal(40.0)
}

// Test scale factor capping at 0.25x minimum
pub fn calculate_portion_caps_scale_factor_min_test() {
  let recipe =
    Recipe(
      id: "heavy-meal",
      name: "Heavy Meal",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 100.0, fat: 50.0, carbs: 100.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let target = Macros(protein: 5.0, fat: 2.0, carbs: 5.0)

  let result = portion.calculate_portion_for_target(recipe, target)

  // Should cap at 0.25x, not 0.05x (5/100)
  result.scale_factor
  |> should.equal(0.25)

  result.scaled_macros.protein
  |> should.equal(25.0)
}

// Test with recipe that has no macros
pub fn calculate_portion_no_macros_test() {
  let recipe =
    Recipe(
      id: "unknown-meal",
      name: "Unknown Meal",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
      servings: 1,
      category: "other",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let target = Macros(protein: 50.0, fat: 20.0, carbs: 30.0)

  let result = portion.calculate_portion_for_target(recipe, target)

  // Should return 1.0 scale factor when no macro data
  result.scale_factor
  |> should.equal(1.0)

  result.meets_target
  |> should.equal(False)

  // Variance should be 100.0 indicating no data
  result.variance
  |> should.equal(100.0)
}

// Test variance calculation
pub fn calculate_portion_variance_within_tolerance_test() {
  let recipe =
    Recipe(
      id: "perfect-match",
      name: "Perfect Match",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 50.0, fat: 20.0, carbs: 30.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let target = Macros(protein: 52.0, fat: 21.0, carbs: 31.0)

  let result = portion.calculate_portion_for_target(recipe, target)

  // Should meet target as within 5% tolerance on protein
  result.meets_target
  |> should.equal(True)

  // Variance should be small
  let variance_is_small = result.variance <. 10.0
  variance_is_small
  |> should.equal(True)
}

// Test calculate_daily_portions
pub fn calculate_daily_portions_test() {
  let daily_macros = Macros(protein: 150.0, fat: 60.0, carbs: 180.0)
  let meals_per_day = 3

  let recipe1 =
    Recipe(
      id: "breakfast",
      name: "Breakfast",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
      servings: 1,
      category: "eggs",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let recipe2 =
    Recipe(
      id: "lunch",
      name: "Lunch",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 60.0, fat: 25.0, carbs: 70.0),
      servings: 1,
      category: "beef",
      fodmap_level: Low,
      vertical_compliant: True,
    )

  let recipes = [recipe1, recipe2]

  let results =
    portion.calculate_daily_portions(daily_macros, meals_per_day, recipes)

  // Should return 2 results (one per recipe)
  list.length(results)
  |> should.equal(2)

  // First recipe should scale to meet ~50g protein (150/3)
  let first = case list.first(results) {
    Ok(r) -> r
    Error(_) -> panic as "Expected first result"
  }

  // Scale factor should be 50/40 = 1.25
  first.scale_factor
  |> should.equal(1.25)
}

// Test calculate_daily_portions with zero meals per day
pub fn calculate_daily_portions_zero_meals_test() {
  let daily_macros = Macros(protein: 150.0, fat: 60.0, carbs: 180.0)
  let meals_per_day = 0

  let recipes = []

  let results =
    portion.calculate_daily_portions(daily_macros, meals_per_day, recipes)

  // Should return empty list
  list.length(results)
  |> should.equal(0)
}

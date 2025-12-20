//// Weekly Generation Algorithm Tests - TDD RED Phase
////
//// Tests for the complete 7-day meal plan generation engine.
//// Part of meal-planner-aejt Phase 3: Generation Engine Algorithm.
////
//// These tests validate:
//// 1. Uniqueness of meals within the week
//// 2. 30-day rotation compliance
//// 3. Macro balance within ±10% tolerance
//// 4. Travel constraint handling and locked meals

import gleeunit
import gleeunit/should
import meal_planner/generator/weekly.{type DayMeals, Dinner, LockedMeal, Lunch}
import meal_planner/id
import meal_planner/types.{type Recipe, Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a test recipe with specific macros
fn test_recipe(name: String, protein: Float, fat: Float, carbs: Float) -> Recipe {
  Recipe(
    id: id.recipe_id(name),
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Create 10 unique breakfast recipes for testing
fn breakfast_recipe_pool() -> List(Recipe) {
  [
    test_recipe("Oatmeal", 15.0, 8.0, 50.0),
    test_recipe("Eggs Benedict", 25.0, 18.0, 30.0),
    test_recipe("Smoothie Bowl", 20.0, 10.0, 45.0),
    test_recipe("Pancakes", 12.0, 15.0, 60.0),
    test_recipe("Greek Yogurt", 18.0, 5.0, 35.0),
    test_recipe("Avocado Toast", 16.0, 22.0, 40.0),
    test_recipe("Protein Shake", 30.0, 8.0, 25.0),
    test_recipe("French Toast", 14.0, 12.0, 55.0),
    test_recipe("Breakfast Burrito", 22.0, 16.0, 42.0),
    test_recipe("Granola Bowl", 10.0, 14.0, 48.0),
  ]
}

/// Create 5 lunch recipes for rotation testing
fn lunch_recipe_pool() -> List(Recipe) {
  [
    test_recipe("Chicken Salad", 35.0, 12.0, 25.0),
    test_recipe("Turkey Wrap", 30.0, 10.0, 40.0),
    test_recipe("Quinoa Bowl", 20.0, 8.0, 50.0),
    test_recipe("Tuna Sandwich", 28.0, 14.0, 35.0),
    test_recipe("Veggie Stir Fry", 15.0, 10.0, 45.0),
  ]
}

/// Create dinner recipes with balanced macros for Lewis's targets
fn dinner_recipe_pool() -> List(Recipe) {
  [
    // Target per meal: ~50g protein, 22g fat, 83g carbs (⅓ of 2000 cal)
    test_recipe("Grilled Salmon", 52.0, 20.0, 85.0),
    test_recipe("Beef Stir Fry", 48.0, 24.0, 80.0),
    test_recipe("Chicken Pasta", 50.0, 18.0, 90.0),
    test_recipe("Pork Chops", 55.0, 22.0, 75.0),
    test_recipe("Tofu Curry", 45.0, 20.0, 88.0),
    test_recipe("Lamb Kebabs", 53.0, 25.0, 78.0),
    test_recipe("Turkey Meatballs", 49.0, 19.0, 82.0),
  ]
}

/// Create quick-prep recipes for travel days
fn quick_prep_recipe_pool() -> List(Recipe) {
  [
    test_recipe("Protein Bar", 20.0, 8.0, 35.0),
    test_recipe("Instant Oats", 12.0, 6.0, 40.0),
    test_recipe("Ready Meal", 25.0, 10.0, 45.0),
  ]
}

// ============================================================================
// Test 1: Seven Unique Breakfasts
// ============================================================================

/// Test that generation produces 7 unique breakfast recipes
///
/// Input: 10 available breakfast recipes, no constraints
/// Expected: 7-day meal plan with all different breakfast recipes
/// Assertion: All 7 breakfast recipes are unique (no repeats)
pub fn test_generation_produces_seven_unique_breakfasts_test() {
  let available_breakfasts = breakfast_recipe_pool()
  let available_lunches = lunch_recipe_pool()
  let available_dinners = dinner_recipe_pool()

  // Target macros: 2000 cal/day, 150g protein, 65g fat, 250g carbs
  let target_macros = Macros(protein: 150.0, fat: 65.0, carbs: 250.0)

  // Call the generation function (THIS DOESN'T EXIST YET - RED PHASE)
  // let result = weekly.generate_meal_plan(
  //   available_breakfasts: available_breakfasts,
  //   available_lunches: available_lunches,
  //   available_dinners: available_dinners,
  //   target_macros: target_macros,
  //   constraints: Constraints(locked_meals: [], travel_dates: []),
  //   week_of: "2025-01-06",
  // )

  // For now, this test MUST FAIL because the function doesn't exist
  should.fail()
  // Once implemented, assertions would be:
  // result |> should.be_ok
  //
  // case result {
  //   Ok(plan) -> {
  //     // Extract all breakfast recipes
  //     let breakfasts = plan.days |> list.map(fn(day) { day.breakfast })
  //
  //     // Assert we have 7 meals
  //     list.length(breakfasts) |> should.equal(7)
  //
  //     // Assert all are unique
  //     let unique_breakfasts = list.unique(breakfasts)
  //     list.length(unique_breakfasts) |> should.equal(7)
  //   }
  //   Error(_) -> should.fail()
  // }
}

// ============================================================================
// Test 2: Thirty-Day Rotation Compliance
// ============================================================================

/// Test that generation respects 30-day rotation constraints
///
/// Input: 5 available lunch recipes, rotation history shows:
///   - Last week Monday: Chicken Salad
///   - Last week Tuesday: Turkey Wrap
///   - Last week Wednesday: Chicken Salad
///   - Last week Thursday: Turkey Wrap
///   - Last week Friday: Chicken Salad
///   - Last week Saturday: Turkey Wrap
///   - Last week Sunday: Chicken Salad
///
/// Expected: This week's lunch recipes exclude recipes used <30 days ago
/// Assertion: No lunch recipe appears on same day as last week
pub fn test_generation_respects_thirty_day_rotation_test() {
  let available_lunches = lunch_recipe_pool()
  let available_breakfasts = breakfast_recipe_pool()
  let available_dinners = dinner_recipe_pool()

  // Create rotation history (recipes used last week)
  // In real implementation, this would be RotationHistory type
  // For now, we simulate by having a constraint that checks history

  let target_macros = Macros(protein: 150.0, fat: 65.0, carbs: 250.0)

  // Call the generation function with rotation history
  // let rotation_history = [
  //   RotationHistory(
  //     meal_id: "Chicken Salad",
  //     last_served: "2024-12-30",  // Monday, 7 days ago
  //     days_since: 7,
  //   ),
  //   RotationHistory(
  //     meal_id: "Turkey Wrap",
  //     last_served: "2024-12-31",  // Tuesday, 6 days ago
  //     days_since: 6,
  //   ),
  // ]

  // let result = weekly.generate_meal_plan(
  //   available_breakfasts: available_breakfasts,
  //   available_lunches: available_lunches,
  //   available_dinners: available_dinners,
  //   target_macros: target_macros,
  //   constraints: Constraints(locked_meals: [], travel_dates: []),
  //   rotation_history: rotation_history,
  //   week_of: "2025-01-06",
  // )

  // For now, this test MUST FAIL because the function doesn't exist
  should.fail()
  // Once implemented, assertions would be:
  // result |> should.be_ok
  //
  // case result {
  //   Ok(plan) -> {
  //     // Get Monday's lunch (first day)
  //     let monday = plan.days |> list.first |> should.be_ok
  //
  //     // Assert Monday lunch is NOT "Chicken Salad"
  //     monday.lunch.name |> should.not_equal("Chicken Salad")
  //
  //     // Get Tuesday's lunch
  //     let tuesday = plan.days |> list.drop(1) |> list.first |> should.be_ok
  //
  //     // Assert Tuesday lunch is NOT "Turkey Wrap"
  //     tuesday.lunch.name |> should.not_equal("Turkey Wrap")
  //   }
  //   Error(_) -> should.fail()
  // }
}

// ============================================================================
// Test 3: Macro Balance Within 10 Percent
// ============================================================================

/// Test that each day's macros are balanced within ±10% of target
///
/// Input: Lewis's daily target = 2000 cal, 150g protein, 65g fat, 250g carbs
/// Expected: Each day's total macros fall within:
///   - Calories: 1800-2200 (±10%)
///   - Protein: 135-165g (±10%)
///   - Fat: 58.5-71.5g (±10%)
///   - Carbs: 225-275g (±10%)
/// Assertion: All 7 days meet macro tolerances
pub fn test_generation_balances_macros_within_ten_percent_test() {
  let available_breakfasts = breakfast_recipe_pool()
  let available_lunches = lunch_recipe_pool()
  let available_dinners = dinner_recipe_pool()

  // Lewis's actual daily targets
  let target_macros = Macros(protein: 150.0, fat: 65.0, carbs: 250.0)

  // Call the generation function
  // let result = weekly.generate_meal_plan(
  //   available_breakfasts: available_breakfasts,
  //   available_lunches: available_lunches,
  //   available_dinners: available_dinners,
  //   target_macros: target_macros,
  //   constraints: Constraints(locked_meals: [], travel_dates: []),
  //   week_of: "2025-01-06",
  // )

  // For now, this test MUST FAIL because the function doesn't exist
  should.fail()
  // Once implemented, assertions would be:
  // result |> should.be_ok
  //
  // case result {
  //   Ok(plan) -> {
  //     // Check each day's macros
  //     plan.days
  //     |> list.each(fn(day) {
  //       let daily_macros = weekly.calculate_daily_macros(day, target_macros)
  //
  //       // Calories: 1800-2200
  //       daily_macros.calories |> should.be_true(fn(c) { c >=. 1800.0 && c <=. 2200.0 })
  //
  //       // Protein: 135-165g
  //       daily_macros.actual.protein
  //       |> should.be_true(fn(p) { p >=. 135.0 && p <=. 165.0 })
  //
  //       // Fat: 58.5-71.5g
  //       daily_macros.actual.fat
  //       |> should.be_true(fn(f) { f >=. 58.5 && f <=. 71.5 })
  //
  //       // Carbs: 225-275g
  //       daily_macros.actual.carbs
  //       |> should.be_true(fn(c) { c >=. 225.0 && c <=. 275.0 })
  //     })
  //   }
  //   Error(_) -> should.fail()
  // }
}

// ============================================================================
// Test 4: Travel Constraints and Locked Meals
// ============================================================================

/// Test that generation handles travel constraints and locked meals
///
/// Input:
///   - Constraints: travel_dates = ["Monday", "Tuesday", "Wednesday"]
///   - Locked meal: Friday dinner = "Grilled Salmon"
///
/// Expected:
///   - Monday, Tuesday, Wednesday meals are quick_prep recipes (≤15 min)
///   - Friday dinner is exactly "Grilled Salmon"
///
/// Assertion: Travel days use quick meals AND locked meal is applied
pub fn test_generation_handles_travel_constraints_test() {
  let available_breakfasts = breakfast_recipe_pool()
  let available_lunches = lunch_recipe_pool()
  let available_dinners = dinner_recipe_pool()
  let quick_recipes = quick_prep_recipe_pool()

  let target_macros = Macros(protein: 150.0, fat: 65.0, carbs: 250.0)

  // Create locked meal for Friday dinner
  let locked_salmon = test_recipe("Grilled Salmon", 52.0, 20.0, 85.0)
  let locked_meal =
    LockedMeal(day: "Friday", meal_type: Dinner, recipe: locked_salmon)

  // Create constraints with travel dates
  let constraints =
    Constraints(locked_meals: [locked_meal], travel_dates: [
      "Monday",
      "Tuesday",
      "Wednesday",
    ])

  // Call the generation function
  // let result = weekly.generate_meal_plan(
  //   available_breakfasts: available_breakfasts,
  //   available_lunches: available_lunches,
  //   available_dinners: available_dinners,
  //   quick_prep_recipes: quick_recipes,
  //   target_macros: target_macros,
  //   constraints: constraints,
  //   week_of: "2025-01-06",
  // )

  // For now, this test MUST FAIL because the function doesn't exist
  should.fail()
  // Once implemented, assertions would be:
  // result |> should.be_ok
  //
  // case result {
  //   Ok(plan) -> {
  //     // Check travel days (Mon, Tue, Wed) use quick prep
  //     let monday = plan.days |> list.first |> should.be_ok
  //     let tuesday = plan.days |> list.drop(1) |> list.first |> should.be_ok
  //     let wednesday = plan.days |> list.drop(2) |> list.first |> should.be_ok
  //
  //     // All travel day meals should be from quick_prep pool
  //     // (In real implementation, would check prep_time <= 15)
  //     list.contains(quick_recipes, monday.breakfast) |> should.be_true
  //     list.contains(quick_recipes, tuesday.lunch) |> should.be_true
  //     list.contains(quick_recipes, wednesday.dinner) |> should.be_true
  //
  //     // Check Friday dinner is locked
  //     let friday = plan.days |> list.drop(4) |> list.first |> should.be_ok
  //     friday.dinner.name |> should.equal("Grilled Salmon")
  //     friday.dinner.macros.protein |> should.equal(52.0)
  //   }
  //   Error(_) -> should.fail()
  // }
}

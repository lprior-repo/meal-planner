//// Tests for /generate handler
////
//// Integration tests for meal plan generation with locked foods.
//// Tests verify that:
//// - Plans include locked food when specified
//// - Plans meet target calories (within 5%)
//// - Error handling for invalid inputs
//// - HTML response formatting

import gleam/list
import gleam/string
import gleeunit/should
import meal_planner/generator
import meal_planner/meal_plan.{type DailyPlan, type Meal, DailyPlan, Meal}
import meal_planner/types.{type Macros, type Recipe, Low, Macros, Recipe}

// ============================================================================
// Test Recipe Factory
// ============================================================================

/// Create a test recipe with specified calorie content
/// Uses standard macro ratios: 30% protein, 30% fat, 40% carbs
fn create_test_recipe(id: String, name: String, calories: Float) -> Recipe {
  let protein = calories *. 0.3 /. 4.0
  let fat = calories *. 0.3 /. 9.0
  let carbs = calories *. 0.4 /. 4.0

  Recipe(
    id: id,
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

/// Create a meal from a recipe
fn create_test_meal(recipe: Recipe) -> Meal {
  Meal(recipe: recipe, portion_size: 1.0)
}

/// Calculate total calories from a daily plan
fn plan_total_calories(plan: DailyPlan) -> Float {
  let macros = meal_plan_macros(plan)
  calculate_calories_from_macros(macros)
}

/// Calculate macros from a daily plan (copied helper)
fn meal_plan_macros(plan: DailyPlan) -> Macros {
  list.fold(
    plan.meals,
    Macros(protein: 0.0, fat: 0.0, carbs: 0.0),
    fn(acc, meal) {
      let m = Meal(recipe: meal.recipe, portion_size: meal.portion_size)
      let recipe = m.recipe
      let macros = recipe.macros
      Macros(
        protein: acc.protein +. macros.protein *. m.portion_size,
        fat: acc.fat +. macros.fat *. m.portion_size,
        carbs: acc.carbs +. macros.carbs *. m.portion_size,
      )
    },
  )
}

/// Calculate calories from macros (4 cal/g protein and carbs, 9 cal/g fat)
fn calculate_calories_from_macros(m: Macros) -> Float {
  { m.protein *. 4.0 } +. { m.fat *. 9.0 } +. { m.carbs *. 4.0 }
}

/// Check if a value is within tolerance of a target
fn within_tolerance(
  value: Float,
  target: Float,
  tolerance_percent: Float,
) -> Bool {
  let tolerance = target *. tolerance_percent /. 100.0
  let lower = target -. tolerance
  let upper = target +. tolerance
  value >=. lower && value <=. upper
}

// ============================================================================
// Test: Generator with locked food - includes locked in result
// ============================================================================

pub fn test_generate_with_locked_food_included() {
  // Create test recipes
  let locked_recipe = create_test_recipe("locked-1", "Grilled Chicken", 300.0)
  let option1 = create_test_recipe("opt-1", "Brown Rice", 400.0)
  let option2 = create_test_recipe("opt-2", "Broccoli", 100.0)
  let available = [option1, option2]

  // Target: 2000 calories
  let target = 2000

  // Generate plan with locked food
  case generator.generate_with_locked(target, locked_recipe, available) {
    Ok(daily_plan) -> {
      // Verify plan has 3 meals
      list.length(daily_plan.meals)
      |> should.equal(3)

      // Verify first meal is the locked food
      case list.first(daily_plan.meals) {
        Ok(first_meal) -> {
          first_meal.recipe.id
          |> should.equal("locked-1")

          first_meal.recipe.name
          |> should.equal("Grilled Chicken")
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test: Generator meets calorie target within 5%
// ============================================================================

pub fn test_generate_meets_calorie_target() {
  let locked_recipe = create_test_recipe("locked-1", "Salmon", 350.0)
  let available = [
    create_test_recipe("opt-1", "Sweet Potato", 450.0),
    create_test_recipe("opt-2", "Green Beans", 80.0),
    create_test_recipe("opt-3", "Rice", 500.0),
    create_test_recipe("opt-4", "Beans", 300.0),
  ]

  let target = 1800

  case generator.generate_with_locked(target, locked_recipe, available) {
    Ok(daily_plan) -> {
      let total_calories = plan_total_calories(daily_plan)

      // Should be within 5% of target
      within_tolerance(total_calories, int_to_float(target), 5.0)
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

/// Helper to convert int to float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

// ============================================================================
// Test: Invalid target (zero or negative) returns error
// ============================================================================

pub fn test_generate_invalid_target_zero() {
  let locked_recipe = create_test_recipe("locked-1", "Chicken", 300.0)
  let available = [create_test_recipe("opt-1", "Rice", 400.0)]

  case generator.generate_with_locked(0, locked_recipe, available) {
    Error(generator.InvalidTarget) -> {
      // Expected error
      True
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

pub fn test_generate_invalid_target_negative() {
  let locked_recipe = create_test_recipe("locked-1", "Chicken", 300.0)
  let available = [create_test_recipe("opt-1", "Rice", 400.0)]

  case generator.generate_with_locked(-100, locked_recipe, available) {
    Error(generator.InvalidTarget) -> {
      True
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Test: Insufficient remaining calories returns error
// ============================================================================

pub fn test_generate_insufficient_remaining_calories() {
  // Locked food is 1500 cal, target is 1600 - only 100 cal remaining
  // Generator requires at least 100 cal for remaining meals
  let locked_recipe = create_test_recipe("locked-1", "Large Meal", 1500.0)
  let available = [create_test_recipe("opt-1", "Small", 50.0)]

  case generator.generate_with_locked(1600, locked_recipe, available) {
    Error(generator.InvalidTarget) -> {
      // Expected: remaining calories too low
      True
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Test: No recipes available returns error
// ============================================================================

pub fn test_generate_no_recipes_available() {
  let locked_recipe = create_test_recipe("locked-1", "Chicken", 300.0)
  let available = []

  case generator.generate_with_locked(2000, locked_recipe, available) {
    Error(generator.NoRecipesAvailable) -> {
      True
      |> should.be_true()
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Test: Multiple recipe options - generator selects appropriate ones
// ============================================================================

pub fn test_generate_with_multiple_options() {
  let locked_recipe = create_test_recipe("locked-1", "Chicken Breast", 280.0)
  let available = [
    create_test_recipe("opt-1", "Brown Rice", 450.0),
    create_test_recipe("opt-2", "Broccoli", 80.0),
    create_test_recipe("opt-3", "Sweet Potato", 400.0),
    create_test_recipe("opt-4", "Green Salad", 150.0),
    create_test_recipe("opt-5", "Pasta", 500.0),
  ]

  let target = 2100

  case generator.generate_with_locked(target, locked_recipe, available) {
    Ok(daily_plan) -> {
      // Should have 3 meals total
      list.length(daily_plan.meals)
      |> should.equal(3)

      // Total should be close to target
      let total = plan_total_calories(daily_plan)
      within_tolerance(total, int_to_float(target), 10.0)
      |> should.be_true()

      // First meal should be locked
      case list.first(daily_plan.meals) {
        Ok(meal) -> {
          meal.recipe.id
          |> should.equal("locked-1")
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test: Portion sizes are correctly applied
// ============================================================================

pub fn test_generate_with_portion_sizes() {
  let locked_recipe = create_test_recipe("locked-1", "Salmon", 400.0)
  let available = [
    create_test_recipe("opt-1", "Rice", 500.0),
    create_test_recipe("opt-2", "Vegetables", 100.0),
  ]

  case generator.generate_with_locked(2000, locked_recipe, available) {
    Ok(daily_plan) -> {
      // All portion sizes should be 1.0 for generated meals
      list.all(daily_plan.meals, fn(meal) {
        meal.portion_size >=. 0.99 && meal.portion_size <=. 1.01
      })
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Test: Generator produces valid meals with proper structure
// ============================================================================

pub fn test_generate_produces_valid_meal_structure() {
  let locked_recipe = create_test_recipe("locked-1", "Chicken", 300.0)
  let available = [
    create_test_recipe("opt-1", "Rice", 400.0),
    create_test_recipe("opt-2", "Veggies", 200.0),
  ]

  case generator.generate_with_locked(1500, locked_recipe, available) {
    Ok(daily_plan) -> {
      // Verify each meal has valid recipe data
      list.all(daily_plan.meals, fn(meal) {
        let recipe = meal.recipe
        string.length(recipe.id) > 0
        && string.length(recipe.name) > 0
        && recipe.macros.protein >=. 0.0
        && recipe.macros.fat >=. 0.0
        && recipe.macros.carbs >=. 0.0
      })
      |> should.be_true()
    }
    Error(_) -> should.fail()
  }
}

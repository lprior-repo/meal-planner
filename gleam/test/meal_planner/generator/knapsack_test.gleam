import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/generator/knapsack
import meal_planner/types.{type Recipe, Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// Helper to create test recipes
fn make_recipe(
  id: String,
  name: String,
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Recipe {
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

// Test 1: Simple successful solve with 3 meals
pub fn test_solve_basic() {
  let recipes = [
    make_recipe("1", "Chicken Breast", 31.0, 3.6, 0.0),
    // 31*4 + 3.6*9 = 124 + 32.4 = 156.4 cal
    make_recipe("2", "Rice", 2.7, 0.3, 28.0),
    // 2.7*4 + 0.3*9 + 28*4 = 10.8 + 2.7 + 112 = 125.5 cal
    make_recipe("3", "Broccoli", 2.8, 0.4, 7.0),
    // 2.8*4 + 0.4*9 + 7*4 = 11.2 + 3.6 + 28 = 42.8 cal
  ]

  let result = knapsack.solve(450, recipes, 3)
  result
  |> should.be_ok()
}

// Test 2: Target exceeded error
pub fn test_solve_target_exceeded() {
  let recipes = [
    make_recipe("1", "Chicken Breast", 31.0, 3.6, 0.0),
    make_recipe("2", "Salmon", 25.0, 11.0, 0.0),
    // 25*4 + 11*9 = 100 + 99 = 199 cal
  ]

  // Request 2 meals but they total > 200
  let result = knapsack.solve(200, recipes, 2)

  case result {
    Error(knapsack.TargetExceeded(_)) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

// Test 3: No recipes error
pub fn test_solve_no_recipes() {
  let result = knapsack.solve(2000, [], 3)

  case result {
    Error(knapsack.NoRecipes) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

// Test 4: Not enough recipes error
pub fn test_solve_not_enough_recipes() {
  let recipes = [
    make_recipe("1", "Chicken Breast", 31.0, 3.6, 0.0),
    make_recipe("2", "Rice", 2.7, 0.3, 28.0),
  ]

  let result = knapsack.solve(1000, recipes, 5)

  case result {
    Error(knapsack.NotEnoughRecipes) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

// Test 5: Invalid target error
pub fn test_solve_invalid_target() {
  let recipes = [
    make_recipe("1", "Chicken Breast", 31.0, 3.6, 0.0),
  ]

  let result = knapsack.solve(-100, recipes, 1)

  case result {
    Error(knapsack.InvalidTarget) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

// Test 6: Single meal selection
pub fn test_solve_single_meal() {
  let recipes = [
    make_recipe("1", "Chicken Breast", 31.0, 3.6, 0.0),
    // 31*4 + 3.6*9 = 156.4 cal
    make_recipe("2", "Rice", 2.7, 0.3, 28.0),
    // 125.5 cal
  ]

  let result = knapsack.solve(500, recipes, 1)

  case result {
    Ok(selected) -> {
      list.length(selected)
      |> should.equal(1)
    }
    Error(_) -> should.be_true(False)
  }
}

// Test 7: Greedy selection picks closest calories
pub fn test_solve_greedy_selection() {
  // Test that greedy selects recipe closest to per-meal target
  let recipes = [
    make_recipe("1", "Low Cal", 5.0, 1.0, 5.0),
    // 5*4 + 1*9 + 5*4 = 20 + 9 + 20 = 49 cal
    make_recipe("2", "High Cal", 50.0, 10.0, 10.0),
    // 50*4 + 10*9 + 10*4 = 200 + 90 + 40 = 330 cal
    make_recipe("3", "Medium Cal", 20.0, 5.0, 10.0),
    // 20*4 + 5*9 + 10*4 = 80 + 45 + 40 = 165 cal
  ]

  // Target 400 for 2 meals = 200 per meal
  // Medium (165) is closest to 200, then either High (330) or Low (49)
  let result = knapsack.solve(400, recipes, 2)

  case result {
    Ok(selected) -> {
      list.length(selected)
      |> should.equal(2)
    }
    Error(_) -> should.be_true(False)
  }
}

// Test 8: Recipe order doesn't matter
pub fn test_solve_order_independent() {
  let recipe_a = make_recipe("1", "A", 10.0, 2.0, 5.0)
  let recipe_b = make_recipe("2", "B", 15.0, 3.0, 8.0)
  let recipe_c = make_recipe("3", "C", 5.0, 1.0, 2.0)

  let recipes_ordered = [recipe_a, recipe_b, recipe_c]
  let recipes_reversed = [recipe_c, recipe_b, recipe_a]

  let result1 = knapsack.solve(600, recipes_ordered, 3)
  let result2 = knapsack.solve(600, recipes_reversed, 3)

  case result1, result2 {
    Ok(selected1), Ok(selected2) -> {
      list.length(selected1)
      |> should.equal(list.length(selected2))
    }
    _, _ -> should.be_true(False)
  }
}

// Test 9: Very low calorie recipes
pub fn test_solve_low_calorie() {
  let recipes = [
    make_recipe("1", "Salad", 1.0, 0.1, 2.0),
    // 1*4 + 0.1*9 + 2*4 = 4 + 0.9 + 8 = 12.9 cal
    make_recipe("2", "Cucumber", 0.5, 0.1, 1.0),
    // 0.5*4 + 0.1*9 + 1*4 = 2 + 0.9 + 4 = 6.9 cal
  ]

  // Request very low calorie target
  let result = knapsack.solve(40, recipes, 2)

  case result {
    Ok(selected) -> {
      list.length(selected)
      |> should.equal(2)
    }
    Error(_) -> should.be_true(False)
  }
}

// Test 10: Large calorie values
pub fn test_solve_large_calories() {
  let recipes = [
    make_recipe("1", "Protein Shake", 30.0, 5.0, 5.0),
    // 30*4 + 5*9 + 5*4 = 120 + 45 + 20 = 185 cal
    make_recipe("2", "Burger", 25.0, 20.0, 45.0),
    // 25*4 + 20*9 + 45*4 = 100 + 180 + 180 = 460 cal
  ]

  // Target 3000 calories for 3 meals
  let result = knapsack.solve(3000, recipes, 3)

  case result {
    Ok(selected) -> {
      list.length(selected)
      |> should.equal(3)
    }
    Error(_) -> should.be_true(False)
  }
}

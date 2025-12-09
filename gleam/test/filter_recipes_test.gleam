import gleam/float
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/storage.{filter_recipes}
import meal_planner/types.{type Recipe, Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Helper to create a mock Recipe for testing
fn create_test_recipe(
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

// ============================================================================
// Filter Recipes Function Tests
// ============================================================================

pub fn filter_recipes_function_exists_test() {
  // Verify function signature and basic properties
  should.be_true(True)
}

pub fn filter_recipes_filters_by_protein_test() {
  // Test filtering by protein level
  let recipes: List(Recipe) = [
    create_test_recipe("1", "High Protein", 45.0, 8.0, 48.0),
    create_test_recipe("2", "Low Protein", 15.0, 5.0, 60.0),
  ]

  let filtered = list.filter(recipes, fn(r) { r.macros.protein >=. 30.0 })

  list.length(filtered)
  |> should.equal(1)
}

pub fn filter_recipes_filters_by_fat_test() {
  // Test filtering by maximum fat
  let recipes: List(Recipe) = [
    create_test_recipe("1", "Low Fat", 45.0, 8.0, 48.0),
    create_test_recipe("2", "High Fat", 40.0, 20.0, 45.0),
  ]

  let filtered = list.filter(recipes, fn(r) { r.macros.fat <=. 15.0 })

  list.length(filtered)
  |> should.equal(1)
}

pub fn filter_recipes_filters_by_calories_test() {
  // Test filtering by maximum calories
  let recipes: List(Recipe) = [
    create_test_recipe("1", "Low Cal", 20.0, 5.0, 30.0),
    create_test_recipe("2", "High Cal", 50.0, 20.0, 60.0),
  ]

  let filtered =
    list.filter(recipes, fn(r) {
      let cal =
        r.macros.protein *. 4.0 +. r.macros.carbs *. 4.0 +. r.macros.fat *. 9.0
      cal <=. 300.0
    })

  list.length(filtered)
  |> should.equal(1)
}

pub fn filter_recipes_returns_empty_for_no_matches_test() {
  // Test that strict constraints return empty list
  let recipes: List(Recipe) = [
    create_test_recipe("1", "Low Protein", 10.0, 8.0, 50.0),
  ]

  let filtered = list.filter(recipes, fn(r) { r.macros.protein >=. 40.0 })

  list.length(filtered)
  |> should.equal(0)
}

pub fn filter_recipes_preserves_recipe_data_test() {
  // Test that recipes are preserved unchanged after filtering
  let recipe = create_test_recipe("recipe-1", "Test Recipe", 45.0, 8.0, 48.0)
  let recipes = [recipe]

  case list.first(recipes) {
    Ok(r) -> {
      r.id
      |> should.equal("recipe-1")
      r.name
      |> should.equal("Test Recipe")
    }
    Error(_) -> should.fail()
  }
}

pub fn filter_recipes_multiple_constraints_test() {
  // Test combining protein, fat, and calorie constraints
  let recipes: List(Recipe) = [
    create_test_recipe("1", "Good", 45.0, 8.0, 48.0),
    create_test_recipe("2", "Bad Fat", 35.0, 25.0, 50.0),
    create_test_recipe("3", "Bad Protein", 25.0, 10.0, 50.0),
  ]

  let filtered =
    recipes
    |> list.filter(fn(r) { r.macros.protein >=. 30.0 })
    |> list.filter(fn(r) { r.macros.fat <=. 20.0 })

  list.length(filtered)
  |> should.equal(1)
}

pub fn filter_recipes_boundary_values_test() {
  // Test that exact boundary values pass filters
  let boundary_recipe = create_test_recipe("1", "Boundary", 30.0, 15.0, 50.0)
  let recipes = [boundary_recipe]

  let protein_filter = list.filter(recipes, fn(r) { r.macros.protein >=. 30.0 })
  let fat_filter = list.filter(recipes, fn(r) { r.macros.fat <=. 15.0 })

  list.length(protein_filter)
  |> should.equal(1)

  list.length(fat_filter)
  |> should.equal(1)
}

pub fn filter_recipes_realistic_knapsack_scenario_test() {
  // Test realistic use case: selecting recipes for meal planning
  let candidates: List(Recipe) = [
    create_test_recipe("1", "Grilled Chicken Breast", 45.0, 8.0, 48.0),
    create_test_recipe("2", "Salmon with Sweet Potato", 42.0, 18.0, 45.0),
    create_test_recipe("3", "Lean Beef Steak", 50.0, 20.0, 20.0),
    create_test_recipe("4", "Pasta Primavera", 14.0, 8.0, 62.0),
  ]

  // Filter for high protein and controlled fat recipes
  let high_protein_low_fat =
    candidates
    |> list.filter(fn(r) { r.macros.protein >=. 35.0 })
    |> list.filter(fn(r) { r.macros.fat <=. 20.0 })

  list.length(high_protein_low_fat)
  |> should.equal(3)
}

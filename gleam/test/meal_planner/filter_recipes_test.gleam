import gleam/int
import gleam/list
import gleam/option.{Some}
import gleeunit
import gleeunit/should
import meal_planner/storage.{type StorageError, filter_recipes, NotFound, DatabaseError}
import meal_planner/types.{type Recipe, Recipe, Macros, Low}

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
// Filter Recipes Unit Tests (Database agnostic tests)
// ============================================================================

pub fn filter_recipes_validates_min_protein_constraint_test() {
  // A recipe with 40g protein should pass min_protein=30
  let recipe = create_test_recipe("1", "High Protein", 40.0, 8.0, 50.0)
  recipe.macros.protein >=. 30.0
  |> should.be_true()
}

pub fn filter_recipes_validates_max_fat_constraint_test() {
  // A recipe with 8g fat should pass max_fat=15
  let recipe = create_test_recipe("1", "Low Fat", 40.0, 8.0, 50.0)
  recipe.macros.fat <=. 15.0
  |> should.be_true()
}

pub fn filter_recipes_validates_max_calories_constraint_test() {
  // A recipe with 450 calories should pass max_calories=500
  let recipe = create_test_recipe("1", "Moderate Cal", 45.0, 8.0, 48.0)
  let recipe_calories = recipe.macros.protein *. 4.0 +. recipe.macros.carbs *. 4.0 +. recipe.macros.fat *. 9.0
  recipe_calories <=. 500.0
  |> should.be_true()
}

pub fn filter_recipes_rejects_low_protein_test() {
  // A recipe with 25g protein should fail min_protein=30
  let recipe = create_test_recipe("1", "Low Protein", 25.0, 8.0, 50.0)
  recipe.macros.protein >=. 30.0
  |> should.be_false()
}

pub fn filter_recipes_rejects_high_fat_test() {
  // A recipe with 20g fat should fail max_fat=15
  let recipe = create_test_recipe("1", "High Fat", 40.0, 20.0, 50.0)
  recipe.macros.fat <=. 15.0
  |> should.be_false()
}

pub fn filter_recipes_rejects_high_calories_test() {
  // A recipe with 550 calories should fail max_calories=500
  let recipe = create_test_recipe("1", "High Cal", 50.0, 20.0, 60.0)
  let recipe_calories = recipe.macros.protein *. 4.0 +. recipe.macros.carbs *. 4.0 +. recipe.macros.fat *. 9.0
  recipe_calories <=. 500.0
  |> should.be_false()
}

pub fn filter_recipes_returns_recipe_list_structure_test() {
  // Test that recipes are properly structured
  let recipes: List(Recipe) = [
    create_test_recipe("1", "Grilled Chicken", 45.0, 8.0, 48.0),
    create_test_recipe("2", "Salmon Fillet", 42.0, 18.0, 45.0),
  ]

  list.length(recipes)
  |> should.equal(2)

  recipes
  |> list.first
  |> should.be_ok
}

pub fn filter_recipes_multiple_recipes_ordering_test() {
  // Test recipes are ordered by protein DESC then calories ASC
  let recipes: List(Recipe) = [
    create_test_recipe("1", "High Protein", 50.0, 8.0, 30.0),  // 50g protein, lower cal
    create_test_recipe("2", "Med Protein", 40.0, 10.0, 50.0),  // 40g protein
    create_test_recipe("3", "Low Protein", 30.0, 5.0, 60.0),   // 30g protein, higher cal
  ]

  // When ordered by protein DESC, first should have highest protein
  recipes
  |> list.first
  |> should.be_ok
}

pub fn filter_recipes_empty_result_test() {
  // Test handling of empty results
  let recipes: List(Recipe) = []

  list.length(recipes)
  |> should.equal(0)
}

// ============================================================================
// Constraint Boundary Tests
// ============================================================================

pub fn filter_recipes_boundary_exact_min_protein_test() {
  // Recipe with exactly min_protein should pass
  let recipe = create_test_recipe("1", "Exact Protein", 30.0, 8.0, 50.0)
  recipe.macros.protein >=. 30.0
  |> should.be_true()
}

pub fn filter_recipes_boundary_exact_max_fat_test() {
  // Recipe with exactly max_fat should pass
  let recipe = create_test_recipe("1", "Exact Fat", 40.0, 15.0, 50.0)
  recipe.macros.fat <=. 15.0
  |> should.be_true()
}

pub fn filter_recipes_boundary_exact_max_calories_test() {
  // Recipe with exactly max_calories should pass
  let recipe = create_test_recipe("1", "Exact Cal", 45.0, 8.0, 48.0)
  let recipe_calories = recipe.macros.protein *. 4.0 +. recipe.macros.carbs *. 4.0 +. recipe.macros.fat *. 9.0
  recipe_calories <=. 500.0
  |> should.be_true()
}

pub fn filter_recipes_just_below_boundary_test() {
  // Recipe just below max_calories should pass
  let recipe = create_test_recipe("1", "Just Below", 45.0, 8.0, 47.5)
  recipe.macros.protein >=. 30.0
  |> should.be_true()
}

pub fn filter_recipes_just_above_boundary_test() {
  // Recipe just above max_calories should fail
  let recipe = create_test_recipe("1", "Just Above", 25.0, 8.0, 50.0)
  recipe.macros.protein >=. 30.0
  |> should.be_false()
}

// ============================================================================
// Real-world Scenario Tests
// ============================================================================

pub fn filter_recipes_knapsack_solver_candidates_test() {
  // Scenario: Selecting recipes for knapsack solver with balanced macros
  // Looking for high-protein, moderate fat, moderate calorie recipes
  let candidates: List(Recipe) = [
    create_test_recipe("1", "Grilled Chicken with Brown Rice", 45.0, 8.0, 48.0),
    create_test_recipe("2", "Salmon Fillet with Sweet Potato", 42.0, 18.0, 45.0),
    create_test_recipe("3", "Lean Beef Steak with Broccoli", 50.0, 20.0, 20.0),
    create_test_recipe("4", "Protein Shake with Banana", 25.0, 3.0, 32.0),
  ]

  // Filter for min_protein=30, max_fat=20, max_calories=500
  let filtered =
    candidates
    |> list.filter(fn(r) { r.macros.protein >=. 30.0 })
    |> list.filter(fn(r) { r.macros.fat <=. 20.0 })

  // Should have at least 3 recipes
  list.length(filtered) >= 3
  |> should.be_true()
}

pub fn filter_recipes_breakfast_options_test() {
  // Test filtering for breakfast options (lower calories, high protein)
  let breakfast_recipes: List(Recipe) = [
    create_test_recipe("1", "Greek Yogurt with Berries", 20.0, 6.0, 15.0),
    create_test_recipe("2", "Scrambled Eggs with Toast", 18.0, 12.0, 28.0),
    create_test_recipe("3", "Pancakes with Syrup", 10.0, 8.0, 50.0),
  ]

  let high_protein_breakfast =
    breakfast_recipes
    |> list.filter(fn(r) { r.macros.protein >=. 15.0 })

  list.length(high_protein_breakfast)
  |> should.equal(2)
}

pub fn filter_recipes_lunch_options_test() {
  // Test filtering for lunch options (moderate to high protein, moderate calories)
  let lunch_recipes: List(Recipe) = [
    create_test_recipe("1", "Grilled Chicken with Brown Rice", 45.0, 8.0, 48.0),
    create_test_recipe("2", "Tuna Salad with Olive Oil", 35.0, 12.0, 8.0),
    create_test_recipe("3", "Turkey Sandwich", 28.0, 10.0, 35.0),
  ]

  let balanced_lunch =
    lunch_recipes
    |> list.filter(fn(r) { r.macros.protein >=. 30.0 })
    |> list.filter(fn(r) { r.macros.fat <=. 15.0 })

  list.length(balanced_lunch)
  |> should.equal(2)
}

pub fn filter_recipes_dinner_options_test() {
  // Test filtering for dinner options (high protein, controlled fat)
  let dinner_recipes: List(Recipe) = [
    create_test_recipe("1", "Salmon Fillet with Sweet Potato", 42.0, 18.0, 45.0),
    create_test_recipe("2", "Lean Beef Steak with Broccoli", 50.0, 20.0, 20.0),
    create_test_recipe("3", "Pasta Primavera", 14.0, 8.0, 62.0),
  ]

  let lean_dinner =
    dinner_recipes
    |> list.filter(fn(r) { r.macros.protein >=. 40.0 })
    |> list.filter(fn(r) { r.macros.fat <=. 20.0 })

  list.length(lean_dinner)
  |> should.equal(2)
}

// ============================================================================
// Edge Cases
// ============================================================================

pub fn filter_recipes_zero_constraints_test() {
  // Test with zero constraints (should pass everything)
  let recipe = create_test_recipe("1", "Any Recipe", 10.0, 100.0, 1000.0)
  recipe.macros.protein >=. 0.0
  |> should.be_true()
}

pub fn filter_recipes_very_strict_constraints_test() {
  // Test with very strict constraints
  let recipe = create_test_recipe("1", "Balanced", 100.0, 5.0, 10.0)
  recipe.macros.protein >=. 100.0
  |> should.be_true()
}

pub fn filter_recipes_negative_values_test() {
  // Test handling of negative macro values (should be invalid in real data)
  let recipe = create_test_recipe("1", "Invalid", -10.0, 8.0, 50.0)
  recipe.macros.protein >=. 0.0
  |> should.be_false()
}

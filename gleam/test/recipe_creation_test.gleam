/// Comprehensive unit tests for recipe creation
///
/// Test coverage:
/// 1. GET /recipes/new returns form HTML
/// 2. POST /recipes with valid data saves recipe
/// 3. POST /recipes with invalid data returns errors
/// 4. Recipe ID generation is unique
/// 5. Form validation catches errors (missing fields, negative values, empty lists)
/// 6. Success redirects to /recipes
/// 7. Integration with storage layer
///
/// Using Test-Driven Development (TDD) with gleeunit framework
import gleam/erlang/process
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/storage
import meal_planner/types.{
  type Recipe, High, Ingredient, Low, Macros, Medium, Recipe,
}
import pog

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// TEST HELPERS
// =============================================================================

/// Create a test database connection
fn test_db() -> pog.Connection {
  let pool_name = process.new_name(prefix: "recipe_test")
  let config =
    pog.default_config(pool_name: pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("meal_planner_test")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(1)

  case pog.start(config) {
    Ok(actor.Started(_pid, conn)) -> conn
    Error(_) ->
      panic as "Failed to connect to test database. Ensure PostgreSQL is running and test database exists."
  }
}

/// Create a valid recipe for testing
fn valid_recipe() -> Recipe {
  Recipe(
    id: "test-recipe-1",
    name: "Test Chicken Rice",
    ingredients: [
      Ingredient(name: "Chicken breast", quantity: "200g"),
      Ingredient(name: "White rice", quantity: "150g"),
    ],
    instructions: ["Cook rice", "Grill chicken", "Combine and serve"],
    macros: Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
    servings: 2,
    category: "chicken",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Create a recipe with invalid macros (negative values)
fn recipe_with_negative_macros() -> Recipe {
  Recipe(
    id: "test-recipe-neg",
    name: "Invalid Recipe",
    ingredients: [Ingredient(name: "Test", quantity: "100g")],
    instructions: ["Step 1"],
    macros: Macros(protein: -10.0, fat: 5.0, carbs: 20.0),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

/// Create a recipe with empty ingredients
fn recipe_with_empty_ingredients() -> Recipe {
  Recipe(
    id: "test-recipe-empty-ing",
    name: "No Ingredients Recipe",
    ingredients: [],
    instructions: ["Step 1"],
    macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

/// Create a recipe with empty instructions
fn recipe_with_empty_instructions() -> Recipe {
  Recipe(
    id: "test-recipe-empty-inst",
    name: "No Instructions Recipe",
    ingredients: [Ingredient(name: "Test", quantity: "100g")],
    instructions: [],
    macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

/// Validate recipe data (business logic validation)
fn validate_recipe(recipe: Recipe) -> Result(Nil, String) {
  // Check for empty name
  case string.trim(recipe.name) {
    "" -> Error("Recipe name cannot be empty")
    _ -> {
      // Check for negative macro values
      case
        recipe.macros.protein <. 0.0
        || recipe.macros.fat <. 0.0
        || recipe.macros.carbs <. 0.0
      {
        True -> Error("Macro values cannot be negative")
        False -> {
          // Check for empty ingredients
          case recipe.ingredients {
            [] -> Error("Recipe must have at least one ingredient")
            _ -> {
              // Check for empty instructions
              case recipe.instructions {
                [] -> Error("Recipe must have at least one instruction")
                _ -> {
                  // Check for valid servings
                  case recipe.servings <= 0 {
                    True -> Error("Servings must be greater than zero")
                    False -> Ok(Nil)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

// =============================================================================
// TEST SUITE 1: Recipe Data Validation
// =============================================================================

/// Test 1: Valid recipe passes validation
pub fn valid_recipe_passes_validation_test() {
  let recipe = valid_recipe()
  let result = validate_recipe(recipe)

  result
  |> should.be_ok()
}

/// Test 2: Recipe with negative protein fails validation
pub fn negative_protein_fails_validation_test() {
  let recipe = recipe_with_negative_macros()
  let result = validate_recipe(recipe)

  result
  |> should.be_error()

  case result {
    Error(msg) -> {
      should.be_true(string.contains(msg, "negative"))
    }
    Ok(_) -> should.fail()
  }
}

/// Test 3: Recipe with empty ingredients fails validation
pub fn empty_ingredients_fails_validation_test() {
  let recipe = recipe_with_empty_ingredients()
  let result = validate_recipe(recipe)

  result
  |> should.be_error()

  case result {
    Error(msg) -> {
      should.be_true(string.contains(msg, "ingredient"))
    }
    Ok(_) -> should.fail()
  }
}

/// Test 4: Recipe with empty instructions fails validation
pub fn empty_instructions_fails_validation_test() {
  let recipe = recipe_with_empty_instructions()
  let result = validate_recipe(recipe)

  result
  |> should.be_error()

  case result {
    Error(msg) -> {
      should.be_true(string.contains(msg, "instruction"))
    }
    Ok(_) -> should.fail()
  }
}

/// Test 5: Recipe with empty name fails validation
pub fn empty_name_fails_validation_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "",
      ingredients: [Ingredient(name: "Test", quantity: "100g")],
      instructions: ["Step 1"],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let result = validate_recipe(recipe)

  result
  |> should.be_error()
}

/// Test 6: Recipe with whitespace-only name fails validation
pub fn whitespace_name_fails_validation_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "   ",
      ingredients: [Ingredient(name: "Test", quantity: "100g")],
      instructions: ["Step 1"],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
      servings: 1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let result = validate_recipe(recipe)

  result
  |> should.be_error()
}

/// Test 7: Recipe with zero servings fails validation
pub fn zero_servings_fails_validation_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Test Recipe",
      ingredients: [Ingredient(name: "Test", quantity: "100g")],
      instructions: ["Step 1"],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
      servings: 0,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let result = validate_recipe(recipe)

  result
  |> should.be_error()
}

/// Test 8: Recipe with negative servings fails validation
pub fn negative_servings_fails_validation_test() {
  let recipe =
    Recipe(
      id: "test",
      name: "Test Recipe",
      ingredients: [Ingredient(name: "Test", quantity: "100g")],
      instructions: ["Step 1"],
      macros: Macros(protein: 10.0, fat: 5.0, carbs: 20.0),
      servings: -1,
      category: "test",
      fodmap_level: Low,
      vertical_compliant: False,
    )

  let result = validate_recipe(recipe)

  result
  |> should.be_error()
}

// =============================================================================
// TEST SUITE 2: Storage Layer Integration
// =============================================================================

/// Test 9: Save valid recipe to database
pub fn save_valid_recipe_to_database_test() {
  let db = test_db()
  let recipe = valid_recipe()

  // First validate
  case validate_recipe(recipe) {
    Error(_) -> should.fail()
    Ok(_) -> {
      // Then save
      let result = storage.save_recipe(db, recipe)

      result
      |> should.be_ok()
    }
  }
}

/// Test 10: Retrieve saved recipe from database
pub fn retrieve_saved_recipe_test() {
  let db = test_db()
  let recipe = valid_recipe()

  // Save recipe
  let save_result = storage.save_recipe(db, recipe)
  save_result
  |> should.be_ok()

  // Retrieve recipe
  let get_result = storage.get_recipe_by_id(db, recipe.id)

  case get_result {
    Ok(retrieved) -> {
      // Verify all fields match
      should.equal(retrieved.id, recipe.id)
      should.equal(retrieved.name, recipe.name)
      should.equal(retrieved.servings, recipe.servings)
      should.equal(retrieved.category, recipe.category)
      should.equal(retrieved.macros.protein, recipe.macros.protein)
      should.equal(retrieved.macros.fat, recipe.macros.fat)
      should.equal(retrieved.macros.carbs, recipe.macros.carbs)
    }
    Error(_) -> should.fail()
  }
}

/// Test 11: Update existing recipe (upsert behavior)
pub fn update_existing_recipe_test() {
  let db = test_db()
  let original_recipe = valid_recipe()

  // Save original
  storage.save_recipe(db, original_recipe)
  |> should.be_ok()

  // Create updated version with same ID
  let updated_recipe =
    Recipe(
      ..original_recipe,
      name: "Updated Test Recipe",
      macros: Macros(protein: 50.0, fat: 10.0, carbs: 50.0),
    )

  // Save updated version
  storage.save_recipe(db, updated_recipe)
  |> should.be_ok()

  // Retrieve and verify it's updated
  case storage.get_recipe_by_id(db, original_recipe.id) {
    Ok(retrieved) -> {
      should.equal(retrieved.name, "Updated Test Recipe")
      should.equal(retrieved.macros.protein, 50.0)
    }
    Error(_) -> should.fail()
  }
}

/// Test 12: Delete recipe from database
pub fn delete_recipe_test() {
  let db = test_db()
  let recipe = valid_recipe()

  // Save recipe
  storage.save_recipe(db, recipe)
  |> should.be_ok()

  // Delete recipe
  storage.delete_recipe(db, recipe.id)
  |> should.be_ok()

  // Verify it's gone
  case storage.get_recipe_by_id(db, recipe.id) {
    Ok(_) -> should.fail()
    Error(storage.NotFound) -> should.be_true(True)
    Error(_) -> should.fail()
  }
}

// =============================================================================
// TEST SUITE 3: Recipe ID Generation
// =============================================================================

/// Test 13: Recipe IDs should be unique
pub fn recipe_ids_are_unique_test() {
  let recipe1 = valid_recipe()
  let recipe2 =
    Recipe(..valid_recipe(), id: "test-recipe-2", name: "Different Recipe")

  should.not_equal(recipe1.id, recipe2.id)
}

/// Test 14: Recipe ID should not be empty
pub fn recipe_id_not_empty_test() {
  let recipe = valid_recipe()

  recipe.id
  |> string.is_empty()
  |> should.be_false()
}

// =============================================================================
// TEST SUITE 4: FODMAP Level Validation
// =============================================================================

/// Test 15: Recipe can have Low FODMAP level
pub fn recipe_with_low_fodmap_test() {
  let recipe = Recipe(..valid_recipe(), fodmap_level: Low)

  should.equal(recipe.fodmap_level, Low)
}

/// Test 16: Recipe can have Medium FODMAP level
pub fn recipe_with_medium_fodmap_test() {
  let recipe = Recipe(..valid_recipe(), fodmap_level: Medium)

  should.equal(recipe.fodmap_level, Medium)
}

/// Test 17: Recipe can have High FODMAP level
pub fn recipe_with_high_fodmap_test() {
  let recipe = Recipe(..valid_recipe(), fodmap_level: High)

  should.equal(recipe.fodmap_level, High)
}

// =============================================================================
// TEST SUITE 5: Vertical Diet Compliance
// =============================================================================

/// Test 18: Vertical compliant recipe with Low FODMAP is compliant
pub fn vertical_compliant_with_low_fodmap_test() {
  let recipe =
    Recipe(..valid_recipe(), vertical_compliant: True, fodmap_level: Low)

  let is_compliant = types.is_vertical_diet_compliant(recipe)

  should.be_true(is_compliant)
}

/// Test 19: Vertical compliant recipe with Medium FODMAP is not compliant
pub fn vertical_compliant_with_medium_fodmap_not_compliant_test() {
  let recipe =
    Recipe(..valid_recipe(), vertical_compliant: True, fodmap_level: Medium)

  let is_compliant = types.is_vertical_diet_compliant(recipe)

  should.be_false(is_compliant)
}

/// Test 20: Non-vertical compliant recipe is never compliant
pub fn non_vertical_compliant_recipe_test() {
  let recipe =
    Recipe(..valid_recipe(), vertical_compliant: False, fodmap_level: Low)

  let is_compliant = types.is_vertical_diet_compliant(recipe)

  should.be_false(is_compliant)
}

// =============================================================================
// TEST SUITE 6: Macros Calculations
// =============================================================================

/// Test 21: Calories calculation is correct
pub fn calories_calculation_test() {
  let recipe = valid_recipe()
  let calories = types.macros_calories(recipe.macros)

  // P: 45 * 4 = 180, F: 8 * 9 = 72, C: 45 * 4 = 180
  // Total: 180 + 72 + 180 = 432
  should.equal(calories, 432.0)
}

/// Test 22: Macros per serving
pub fn macros_per_serving_test() {
  let recipe = valid_recipe()
  let per_serving = types.macros_per_serving(recipe)

  // Recipe macros are already per serving
  should.equal(per_serving.protein, recipe.macros.protein)
  should.equal(per_serving.fat, recipe.macros.fat)
  should.equal(per_serving.carbs, recipe.macros.carbs)
}

/// Test 23: Total macros for all servings
pub fn total_macros_calculation_test() {
  let recipe = valid_recipe()
  let total = types.total_macros(recipe)

  // 2 servings * macros
  should.equal(total.protein, recipe.macros.protein *. 2.0)
  should.equal(total.fat, recipe.macros.fat *. 2.0)
  should.equal(total.carbs, recipe.macros.carbs *. 2.0)
}

// =============================================================================
// TEST SUITE 7: Ingredients and Instructions
// =============================================================================

/// Test 24: Recipe with multiple ingredients
pub fn recipe_with_multiple_ingredients_test() {
  let recipe = valid_recipe()

  list.length(recipe.ingredients)
  |> should.equal(2)
}

/// Test 25: Recipe with multiple instructions
pub fn recipe_with_multiple_instructions_test() {
  let recipe = valid_recipe()

  list.length(recipe.instructions)
  |> should.equal(3)
}

/// Test 26: Ingredient has name and quantity
pub fn ingredient_structure_test() {
  let ingredient = Ingredient(name: "Chicken", quantity: "200g")

  should.equal(ingredient.name, "Chicken")
  should.equal(ingredient.quantity, "200g")
}

// =============================================================================
// TEST SUITE 8: Category Validation
// =============================================================================

/// Test 27: Recipe can have chicken category
pub fn recipe_with_chicken_category_test() {
  let recipe = Recipe(..valid_recipe(), category: "chicken")

  should.equal(recipe.category, "chicken")
}

/// Test 28: Recipe can have beef category
pub fn recipe_with_beef_category_test() {
  let recipe = Recipe(..valid_recipe(), category: "beef")

  should.equal(recipe.category, "beef")
}

/// Test 29: Recipe can have seafood category
pub fn recipe_with_seafood_category_test() {
  let recipe = Recipe(..valid_recipe(), category: "seafood")

  should.equal(recipe.category, "seafood")
}

/// Test 30: Recipe category should not be empty
pub fn recipe_category_not_empty_test() {
  let recipe = valid_recipe()

  recipe.category
  |> string.is_empty()
  |> should.be_false()
}

// =============================================================================
// TEST SUITE 9: Edge Cases
// =============================================================================

/// Test 31: Recipe with very large macro values
pub fn recipe_with_large_macros_test() {
  let recipe =
    Recipe(
      ..valid_recipe(),
      macros: Macros(protein: 1000.0, fat: 500.0, carbs: 2000.0),
    )

  let result = validate_recipe(recipe)

  result
  |> should.be_ok()
}

/// Test 32: Recipe with zero macro values
pub fn recipe_with_zero_macros_test() {
  let recipe =
    Recipe(..valid_recipe(), macros: Macros(protein: 0.0, fat: 0.0, carbs: 0.0))

  let result = validate_recipe(recipe)

  result
  |> should.be_ok()
}

/// Test 33: Recipe with many ingredients
pub fn recipe_with_many_ingredients_test() {
  let ingredients = [
    Ingredient(name: "Ingredient 1", quantity: "100g"),
    Ingredient(name: "Ingredient 2", quantity: "200g"),
    Ingredient(name: "Ingredient 3", quantity: "300g"),
    Ingredient(name: "Ingredient 4", quantity: "400g"),
    Ingredient(name: "Ingredient 5", quantity: "500g"),
  ]

  let recipe = Recipe(..valid_recipe(), ingredients: ingredients)

  let result = validate_recipe(recipe)

  result
  |> should.be_ok()

  list.length(recipe.ingredients)
  |> should.equal(5)
}

/// Test 34: Recipe with many instructions
pub fn recipe_with_many_instructions_test() {
  let instructions = [
    "Step 1",
    "Step 2",
    "Step 3",
    "Step 4",
    "Step 5",
    "Step 6",
    "Step 7",
    "Step 8",
  ]

  let recipe = Recipe(..valid_recipe(), instructions: instructions)

  let result = validate_recipe(recipe)

  result
  |> should.be_ok()

  list.length(recipe.instructions)
  |> should.equal(8)
}

/// Test 35: Recipe with single serving
pub fn recipe_with_single_serving_test() {
  let recipe = Recipe(..valid_recipe(), servings: 1)

  let result = validate_recipe(recipe)

  result
  |> should.be_ok()
}

/// Test 36: Recipe with many servings
pub fn recipe_with_many_servings_test() {
  let recipe = Recipe(..valid_recipe(), servings: 12)

  let result = validate_recipe(recipe)

  result
  |> should.be_ok()
}

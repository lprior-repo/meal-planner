import gleam/list
import gleeunit/should
import meal_planner/types.{
  type Ingredient, type Recipe, Ingredient, Low, Macros, Recipe,
}
import meal_planner/validation.{validate_recipe_strict}

// Helper to create a test recipe
fn make_recipe(name: String, ingredients: List(Ingredient)) -> Recipe {
  Recipe(
    name: name,
    ingredients: ingredients,
    instructions: [],
    macros: Macros(protein: 30.0, fat: 10.0, carbs: 20.0),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

// Test valid recipe with no violations
pub fn validate_recipe_strict_valid_test() {
  let recipe =
    make_recipe("Grilled Steak", [
      Ingredient(name: "Ribeye steak", quantity: "12 oz"),
      Ingredient(name: "Olive oil", quantity: "1 tbsp"),
      Ingredient(name: "Salt", quantity: "1 tsp"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_true()
  result.violations |> should.equal([])
}

// Test recipe with forbidden seed oil
pub fn validate_recipe_strict_seed_oil_test() {
  let recipe =
    make_recipe("Bad Recipe", [
      Ingredient(name: "Chicken breast", quantity: "8 oz"),
      Ingredient(name: "Canola oil", quantity: "2 tbsp"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
  list.length(result.violations) |> should.equal(1)
}

pub fn validate_recipe_strict_soybean_oil_test() {
  let recipe =
    make_recipe("Soy Dish", [
      Ingredient(name: "Vegetables", quantity: "1 cup"),
      Ingredient(name: "Soybean oil", quantity: "1 tbsp"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
}

pub fn validate_recipe_strict_vegetable_oil_test() {
  let recipe =
    make_recipe("Fried Food", [
      Ingredient(name: "Chicken", quantity: "8 oz"),
      Ingredient(name: "Vegetable oil", quantity: "2 cups"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
}

// Test recipe with forbidden grain
pub fn validate_recipe_strict_wheat_test() {
  let recipe =
    make_recipe("Pasta Dish", [
      Ingredient(name: "Ground beef", quantity: "1 lb"),
      Ingredient(name: "Whole wheat pasta", quantity: "8 oz"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
}

pub fn validate_recipe_strict_bread_test() {
  let recipe =
    make_recipe("Sandwich", [
      Ingredient(name: "Turkey", quantity: "4 oz"),
      Ingredient(name: "Whole wheat bread", quantity: "2 slices"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
}

pub fn validate_recipe_strict_oats_test() {
  let recipe =
    make_recipe("Oatmeal", [
      Ingredient(name: "Oatmeal", quantity: "1 cup"),
      Ingredient(name: "Milk", quantity: "1/2 cup"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
}

// Test allowed grains (white rice is OK)
pub fn validate_recipe_strict_white_rice_allowed_test() {
  let recipe =
    make_recipe("Rice Bowl", [
      Ingredient(name: "Ground beef", quantity: "8 oz"),
      Ingredient(name: "White rice", quantity: "1 cup"),
      Ingredient(name: "Salt", quantity: "1 tsp"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_true()
}

pub fn validate_recipe_strict_rice_cereal_allowed_test() {
  let recipe =
    make_recipe("Breakfast", [
      Ingredient(name: "Rice cereal", quantity: "1 cup"),
      Ingredient(name: "Milk", quantity: "1/2 cup"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_true()
}

// Test brown rice is NOT allowed
pub fn validate_recipe_strict_brown_rice_forbidden_test() {
  let recipe =
    make_recipe("Brown Rice Bowl", [
      Ingredient(name: "Chicken", quantity: "8 oz"),
      Ingredient(name: "Brown rice", quantity: "1 cup"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
}

// Test high FODMAP ingredients
pub fn validate_recipe_strict_garlic_test() {
  let recipe =
    make_recipe("Garlic Chicken", [
      Ingredient(name: "Chicken breast", quantity: "8 oz"),
      Ingredient(name: "Garlic", quantity: "3 cloves"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
}

pub fn validate_recipe_strict_onion_test() {
  let recipe =
    make_recipe("Onion Steak", [
      Ingredient(name: "Ribeye steak", quantity: "12 oz"),
      Ingredient(name: "Onion", quantity: "1 medium"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
}

// Test FODMAP exception (garlic-infused oil is OK)
pub fn validate_recipe_strict_garlic_infused_oil_allowed_test() {
  let recipe =
    make_recipe("Garlic Oil Steak", [
      Ingredient(name: "Ribeye steak", quantity: "12 oz"),
      Ingredient(name: "Garlic-infused oil", quantity: "1 tbsp"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_true()
}

// Test multiple violations
pub fn validate_recipe_strict_multiple_violations_test() {
  let recipe =
    make_recipe("Bad Everything", [
      Ingredient(name: "Ground beef", quantity: "1 lb"),
      Ingredient(name: "Canola oil", quantity: "2 tbsp"),
      Ingredient(name: "Whole wheat pasta", quantity: "8 oz"),
      Ingredient(name: "Garlic", quantity: "2 cloves"),
    ])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_false()
  // Should have at least 3 violations (seed oil, grain, FODMAP)
  { list.length(result.violations) >= 3 } |> should.be_true()
}

// Test empty ingredients
pub fn validate_recipe_strict_empty_ingredients_test() {
  let recipe = make_recipe("Empty Recipe", [])

  let result = validate_recipe_strict(recipe)
  result.is_valid |> should.be_true()
}

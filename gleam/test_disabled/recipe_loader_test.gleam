import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/recipe_loader

pub fn main() {
  gleeunit.main()
}

// Test loading a single YAML file with multiple recipes
pub fn load_yaml_file_test() {
  let yaml_content =
    "recipes:
  - name: Test Recipe 1
    ingredients:
      - name: ingredient 1
        quantity: 1 cup
      - name: ingredient 2
        quantity: 2 tbsp
    instructions:
      - Step 1
      - Step 2
    macros:
      protein: 25.0
      fat: 10.0
      carbs: 30.0
    servings: 4
    category: beef
    fodmap_level: low
    vertical_compliant: true
  - name: Test Recipe 2
    ingredients:
      - name: ingredient 3
        quantity: 1 lb
    instructions:
      - Step A
    macros:
      protein: 30.0
      fat: 15.0
      carbs: 20.0
    servings: 2
    category: chicken
    fodmap_level: medium
    vertical_compliant: false
"

  let result = recipe_loader.parse_yaml(yaml_content)

  result
  |> should.be_ok()

  let recipes = result |> should.be_ok()
  list.length(recipes) |> should.equal(2)

  // Check first recipe
  let assert Ok(first) = list.first(recipes)
  first.name |> should.equal("Test Recipe 1")
  list.length(first.ingredients) |> should.equal(2)
  list.length(first.instructions) |> should.equal(2)
  first.servings |> should.equal(4)
  first.category |> should.equal("beef")
}

// Test loading recipes from directory
pub fn load_recipes_from_directory_test() {
  // This test will check loading from recipes/ directory
  let result = recipe_loader.load_recipes("../recipes", "sides.yaml")

  result
  |> should.be_ok()

  let recipes = result |> should.be_ok()

  // Should load multiple recipes from multiple files
  list.length(recipes) |> should.not_equal(0)
}

// Test parsing empty YAML
pub fn parse_empty_yaml_test() {
  let yaml_content = "recipes: []"

  let result = recipe_loader.parse_yaml(yaml_content)

  result
  |> should.be_ok()

  let recipes = result |> should.be_ok()
  list.length(recipes) |> should.equal(0)
}

// Test parsing invalid YAML
pub fn parse_invalid_yaml_test() {
  let invalid_yaml = "this is not valid yaml: {"

  let result = recipe_loader.parse_yaml(invalid_yaml)

  result
  |> should.be_error()
}

// Test recipe with all FODMAP levels
pub fn parse_yaml_fodmap_levels_test() {
  let yaml_content =
    "recipes:
  - name: Low FODMAP Recipe
    ingredients:
      - name: chicken
        quantity: 8 oz
    instructions:
      - Cook it
    macros:
      protein: 40.0
      fat: 10.0
      carbs: 0.0
    servings: 1
    category: chicken
    fodmap_level: low
    vertical_compliant: true
  - name: Medium FODMAP Recipe
    ingredients:
      - name: something
        quantity: 1 cup
    instructions:
      - Prepare
    macros:
      protein: 10.0
      fat: 5.0
      carbs: 20.0
    servings: 1
    category: other
    fodmap_level: medium
    vertical_compliant: false
  - name: High FODMAP Recipe
    ingredients:
      - name: onions
        quantity: 1 cup
    instructions:
      - Cook
    macros:
      protein: 2.0
      fat: 0.0
      carbs: 12.0
    servings: 1
    category: vegetable
    fodmap_level: high
    vertical_compliant: false
"

  let result = recipe_loader.parse_yaml(yaml_content)
  result |> should.be_ok()

  let recipes = result |> should.be_ok()
  list.length(recipes) |> should.equal(3)
}

// Test recipe with auto-generated ID from name
pub fn parse_yaml_auto_id_test() {
  let yaml_content =
    "recipes:
  - name: Grilled Chicken Breast
    ingredients:
      - name: chicken breast
        quantity: 8 oz
    instructions:
      - Season and grill
    macros:
      protein: 45.0
      fat: 8.0
      carbs: 0.0
    servings: 1
    category: chicken
    fodmap_level: low
    vertical_compliant: true
"

  let result = recipe_loader.parse_yaml(yaml_content)
  result |> should.be_ok()

  let recipes = result |> should.be_ok()
  let assert Ok(first) = list.first(recipes)
  // ID should be auto-generated from name: "grilled-chicken-breast"
  first.id |> should.equal("grilled-chicken-breast")
}

// Test recipe with explicit ID
pub fn parse_yaml_explicit_id_test() {
  let yaml_content =
    "recipes:
  - id: my-custom-id
    name: Custom Recipe
    ingredients:
      - name: beef
        quantity: 6 oz
    instructions:
      - Cook beef
    macros:
      protein: 40.0
      fat: 20.0
      carbs: 0.0
    servings: 1
    category: beef
    fodmap_level: low
    vertical_compliant: true
"

  let result = recipe_loader.parse_yaml(yaml_content)
  result |> should.be_ok()

  let recipes = result |> should.be_ok()
  let assert Ok(first) = list.first(recipes)
  first.id |> should.equal("my-custom-id")
}

// Test recipe macros with integer values (should convert to float)
pub fn parse_yaml_integer_macros_test() {
  let yaml_content =
    "recipes:
  - name: Integer Macros
    ingredients:
      - name: rice
        quantity: 1 cup
    instructions:
      - Cook rice
    macros:
      protein: 4
      fat: 1
      carbs: 45
    servings: 1
    category: rice
    fodmap_level: low
    vertical_compliant: true
"

  let result = recipe_loader.parse_yaml(yaml_content)
  result |> should.be_ok()

  let recipes = result |> should.be_ok()
  let assert Ok(first) = list.first(recipes)
  first.macros.protein |> should.equal(4.0)
  first.macros.fat |> should.equal(1.0)
  first.macros.carbs |> should.equal(45.0)
}

// Test recipe with multiple ingredients
pub fn parse_yaml_multiple_ingredients_test() {
  let yaml_content =
    "recipes:
  - name: Complex Meal
    ingredients:
      - name: ribeye steak
        quantity: 8 oz
      - name: white rice
        quantity: 1 cup
      - name: butter
        quantity: 1 tbsp
      - name: salt
        quantity: 1 tsp
      - name: black pepper
        quantity: 1/2 tsp
    instructions:
      - Season steak
      - Grill to medium
      - Serve with rice
    macros:
      protein: 52.0
      fat: 38.0
      carbs: 45.0
    servings: 1
    category: beef
    fodmap_level: low
    vertical_compliant: true
"

  let result = recipe_loader.parse_yaml(yaml_content)
  result |> should.be_ok()

  let recipes = result |> should.be_ok()
  let assert Ok(first) = list.first(recipes)
  list.length(first.ingredients) |> should.equal(5)
  list.length(first.instructions) |> should.equal(3)
}

// Test YAML missing recipes key
pub fn parse_yaml_missing_recipes_key_test() {
  let yaml_content =
    "items:
  - name: Not a recipe
"

  let result = recipe_loader.parse_yaml(yaml_content)
  result |> should.be_error()
}

// Test YAML with missing required field
pub fn parse_yaml_missing_required_field_test() {
  let yaml_content =
    "recipes:
  - name: Missing Fields
    ingredients: []
    instructions: []
    macros:
      protein: 10.0
      fat: 5.0
      carbs: 20.0
"
  // Missing servings, category, fodmap_level, vertical_compliant

  let result = recipe_loader.parse_yaml(yaml_content)
  result |> should.be_error()
}

// Test recipe with vertical_compliant as true/false
pub fn parse_yaml_vertical_compliant_test() {
  let yaml_content =
    "recipes:
  - name: Compliant Recipe
    ingredients:
      - name: beef
        quantity: 8 oz
    instructions:
      - Cook
    macros:
      protein: 40.0
      fat: 20.0
      carbs: 0.0
    servings: 1
    category: beef
    fodmap_level: low
    vertical_compliant: true
  - name: Non-Compliant Recipe
    ingredients:
      - name: pasta
        quantity: 2 cups
    instructions:
      - Boil
    macros:
      protein: 8.0
      fat: 1.0
      carbs: 50.0
    servings: 1
    category: pasta
    fodmap_level: high
    vertical_compliant: false
"

  let result = recipe_loader.parse_yaml(yaml_content)
  result |> should.be_ok()

  let recipes = result |> should.be_ok()
  let assert Ok(first) = list.first(recipes)
  first.vertical_compliant |> should.be_true()

  let assert Ok(second) = list.at(recipes, 1)
  second.vertical_compliant |> should.be_false()
}

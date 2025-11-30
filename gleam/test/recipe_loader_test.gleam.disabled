import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/recipe_loader
import meal_planner/types.{type Recipe, Ingredient, Macros}

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

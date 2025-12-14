/// Tests for Test Fixtures
///
/// This test suite validates JSON fixtures for all Tandoor domain types.
import gleam/json
import gleeunit/should
import meal_planner/tandoor/testing/fixtures

/// Test: Recipe fixture
pub fn recipe_fixture_test() {
  let fixture = fixtures.recipe()

  fixture.id |> should.equal(1)
  fixture.name |> should.equal("Test Recipe")
  fixture.description |> should.equal("A test recipe for unit tests")
}

/// Test: Recipe fixture with custom values
pub fn recipe_fixture_custom_test() {
  let fixture =
    fixtures.recipe()
    |> fixtures.with_id(42)
    |> fixtures.with_name("Custom Recipe")
    |> fixtures.with_servings(6)

  fixture.id |> should.equal(42)
  fixture.name |> should.equal("Custom Recipe")
  fixture.servings |> should.equal(6)
}

/// Test: Recipe simple fixture
pub fn recipe_simple_fixture_test() {
  let fixture = fixtures.recipe_simple()

  fixture.id |> should.equal(1)
  fixture.name |> should.equal("Simple Recipe")
}

/// Test: Food fixture
pub fn food_fixture_test() {
  let fixture = fixtures.food()

  fixture.id |> should.equal(1)
  fixture.name |> should.equal("Test Food")
}

/// Test: Food fixture with custom values
pub fn food_fixture_custom_test() {
  let fixture =
    fixtures.food()
    |> fixtures.with_food_id(99)
    |> fixtures.with_food_name("Custom Food")

  fixture.id |> should.equal(99)
  fixture.name |> should.equal("Custom Food")
}

/// Test: Ingredient fixture
pub fn ingredient_fixture_test() {
  let fixture = fixtures.ingredient()

  fixture.amount |> should.equal(1.5)
  fixture.unit.name |> should.equal("cup")
  fixture.food.name |> should.equal("Flour")
}

/// Test: Keyword fixture
pub fn keyword_fixture_test() {
  let fixture = fixtures.keyword()

  fixture.id |> should.equal(1)
  fixture.name |> should.equal("vegetarian")
}

/// Test: Unit fixture
pub fn unit_fixture_test() {
  let fixture = fixtures.unit()

  fixture.id |> should.equal(1)
  fixture.name |> should.equal("gram")
}

/// Test: MealPlan fixture
pub fn mealplan_fixture_test() {
  let fixture = fixtures.mealplan()

  fixture.id |> should.equal(1)
  fixture.recipe.id |> should.equal(1)
}

/// Test: User fixture
pub fn user_fixture_test() {
  let fixture = fixtures.user()

  fixture.id |> should.equal(1)
  fixture.username |> should.equal("testuser")
}

/// Test: Paginated response fixture
pub fn paginated_fixture_test() {
  let fixture = fixtures.paginated_recipes(count: 50, page_size: 10)

  fixture.count |> should.equal(50)
  fixture.results |> should.have_length(10)
}

/// Test: Empty list fixture
pub fn empty_list_fixture_test() {
  let fixture = fixtures.empty_list()

  fixture.count |> should.equal(0)
  fixture.results |> should.have_length(0)
}

/// Test: Error response fixture
pub fn error_response_fixture_test() {
  let fixture = fixtures.error_response(status: 404, detail: "Recipe not found")

  fixture.status |> should.equal(404)
  fixture.detail |> should.equal("Recipe not found")
}

/// Test: JSON serialization of fixtures
pub fn fixture_json_serialization_test() {
  let recipe = fixtures.recipe()
  let json_string = fixtures.to_json(recipe)

  // Verify JSON contains expected fields
  json_string |> should.contain("\"id\"")
  json_string |> should.contain("\"name\"")
  json_string |> should.contain("Test Recipe")
}

/// Test: Load fixture from file
pub fn load_fixture_from_file_test() {
  let fixture = fixtures.load("recipe_full.json")

  // Verify fixture loaded successfully
  fixture |> should.be_ok()
}

/// Test: Fixture builder pattern
pub fn fixture_builder_pattern_test() {
  let recipe =
    fixtures.recipe_builder()
    |> fixtures.set_id(100)
    |> fixtures.set_name("Builder Recipe")
    |> fixtures.add_keyword("vegan")
    |> fixtures.add_keyword("gluten-free")
    |> fixtures.set_servings(4)
    |> fixtures.build()

  recipe.id |> should.equal(100)
  recipe.name |> should.equal("Builder Recipe")
  recipe.keywords |> should.have_length(2)
}

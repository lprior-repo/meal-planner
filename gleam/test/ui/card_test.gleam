/// Card Component Tests
///
/// This module defines failing tests that establish contracts for card components.
/// Tests verify that card components render correct HTML structure and content.
///
/// All tests are expected to FAIL until the card component functions are implemented.

import gleeunit
import gleeunit/should
import gleam/option
import meal_planner/ui/components/card
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// BASIC CARD TESTS
// ===================================================================

pub fn card_renders_container_test() {
  card.card([])
  |> should.contain("class=\"card\"")
}

pub fn card_contains_div_element_test() {
  card.card([])
  |> should.contain("<div")
}

pub fn card_with_content_test() {
  card.card(["<p>Content</p>"])
  |> should.contain("Content")
}

pub fn card_with_multiple_content_items_test() {
  let content = [
    "<p>First</p>",
    "<p>Second</p>",
    "<p>Third</p>",
  ]
  let result = card.card(content)
  result
  |> should.contain("First")
  |> should.contain("Second")
  |> should.contain("Third")
}

pub fn card_empty_content_test() {
  card.card([])
  |> should.contain("card")
}

// ===================================================================
// CARD WITH HEADER TESTS
// ===================================================================

pub fn card_with_header_renders_header_test() {
  card.card_with_header("My Header", [])
  |> should.contain("My Header")
}

pub fn card_with_header_contains_header_class_test() {
  card.card_with_header("Header", [])
  |> should.contain("card-header")
}

pub fn card_with_header_contains_body_class_test() {
  card.card_with_header("Header", ["<p>Body</p>"])
  |> should.contain("card-body")
}

pub fn card_with_header_contains_body_content_test() {
  card.card_with_header("Header", ["<p>Content</p>"])
  |> should.contain("Content")
}

pub fn card_with_header_structure_test() {
  let result = card.card_with_header("Title", ["<p>Body</p>"])
  result
  |> should.contain("card")
  |> should.contain("card-header")
  |> should.contain("Title")
  |> should.contain("card-body")
  |> should.contain("Body")
}

// ===================================================================
// CARD WITH ACTIONS TESTS
// ===================================================================

pub fn card_with_actions_renders_header_test() {
  card.card_with_actions("Header", [], [])
  |> should.contain("Header")
}

pub fn card_with_actions_renders_actions_test() {
  let actions = ["<button>Edit</button>"]
  card.card_with_actions("Header", [], actions)
  |> should.contain("Edit")
}

pub fn card_with_actions_contains_actions_class_test() {
  card.card_with_actions("Header", [], ["<button>Delete</button>"])
  |> should.contain("card-actions")
}

pub fn card_with_actions_multiple_actions_test() {
  let actions = [
    "<button>Edit</button>",
    "<button>Delete</button>",
    "<button>Share</button>",
  ]
  let result = card.card_with_actions("Header", [], actions)
  result
  |> should.contain("Edit")
  |> should.contain("Delete")
  |> should.contain("Share")
}

pub fn card_with_actions_body_content_test() {
  card.card_with_actions("Header", ["<p>Content</p>"], [])
  |> should.contain("Content")
}

// ===================================================================
// STAT CARD TESTS
// ===================================================================

pub fn stat_card_renders_value_test() {
  let stat = ui_types.StatCard(
    label: "Calories",
    value: "2100",
    unit: "kcal",
    trend: option.None,
    color: "primary",
  )
  card.stat_card(stat)
  |> should.contain("2100")
}

pub fn stat_card_renders_unit_test() {
  let stat = ui_types.StatCard(
    label: "Protein",
    value: "150",
    unit: "g",
    trend: option.None,
    color: "success",
  )
  card.stat_card(stat)
  |> should.contain("g")
}

pub fn stat_card_renders_label_test() {
  let stat = ui_types.StatCard(
    label: "Calories",
    value: "2100",
    unit: "kcal",
    trend: option.None,
    color: "primary",
  )
  card.stat_card(stat)
  |> should.contain("Calories")
}

pub fn stat_card_contains_stat_card_class_test() {
  let stat = ui_types.StatCard(
    label: "Test",
    value: "100",
    unit: "unit",
    trend: option.None,
    color: "primary",
  )
  card.stat_card(stat)
  |> should.contain("stat-card")
}

pub fn stat_card_with_trend_test() {
  let stat = ui_types.StatCard(
    label: "Weight",
    value: "75",
    unit: "kg",
    trend: option.Some(0.5),
    color: "warning",
  )
  card.stat_card(stat)
  |> should.contain("75")
}

pub fn stat_card_color_field_test() {
  let stat = ui_types.StatCard(
    label: "Stat",
    value: "50",
    unit: "%",
    trend: option.None,
    color: "danger",
  )
  card.stat_card(stat)
  |> should.contain("danger")
}

// ===================================================================
// RECIPE CARD TESTS
// ===================================================================

pub fn recipe_card_renders_name_test() {
  let recipe = ui_types.RecipeCardData(
    id: "123",
    name: "Grilled Chicken",
    category: "Main Dish",
    calories: 450.0,
    image_url: option.None,
  )
  card.recipe_card(recipe)
  |> should.contain("Grilled Chicken")
}

pub fn recipe_card_renders_category_test() {
  let recipe = ui_types.RecipeCardData(
    id: "456",
    name: "Salad",
    category: "Appetizer",
    calories: 200.0,
    image_url: option.None,
  )
  card.recipe_card(recipe)
  |> should.contain("Appetizer")
}

pub fn recipe_card_renders_calories_test() {
  let recipe = ui_types.RecipeCardData(
    id: "789",
    name: "Pasta",
    category: "Main",
    calories: 600.0,
    image_url: option.None,
  )
  card.recipe_card(recipe)
  |> should.contain("600")
}

pub fn recipe_card_with_image_test() {
  let recipe = ui_types.RecipeCardData(
    id: "999",
    name: "Burger",
    category: "Main",
    calories: 550.0,
    image_url: option.Some("https://example.com/burger.jpg"),
  )
  card.recipe_card(recipe)
  |> should.contain("https://example.com/burger.jpg")
}

pub fn recipe_card_without_image_test() {
  let recipe = ui_types.RecipeCardData(
    id: "111",
    name: "Soup",
    category: "Appetizer",
    calories: 150.0,
    image_url: option.None,
  )
  card.recipe_card(recipe)
  |> should.contain("Soup")
}

pub fn recipe_card_contains_recipe_card_class_test() {
  let recipe = ui_types.RecipeCardData(
    id: "222",
    name: "Steak",
    category: "Main",
    calories: 800.0,
    image_url: option.None,
  )
  card.recipe_card(recipe)
  |> should.contain("recipe-card")
}

// ===================================================================
// FOOD CARD TESTS
// ===================================================================

pub fn food_card_renders_description_test() {
  let food = ui_types.FoodCardData(
    fdc_id: 12345,
    description: "Chicken, raw",
    data_type: "Survey (FNDDS)",
    category: "Poultry Products",
  )
  card.food_card(food)
  |> should.contain("Chicken, raw")
}

pub fn food_card_renders_category_test() {
  let food = ui_types.FoodCardData(
    fdc_id: 54321,
    description: "Apple, red",
    data_type: "SR Legacy",
    category: "Fruits and Fruit Juices",
  )
  card.food_card(food)
  |> should.contain("Fruits and Fruit Juices")
}

pub fn food_card_renders_data_type_test() {
  let food = ui_types.FoodCardData(
    fdc_id: 11111,
    description: "Beef, ground",
    data_type: "Foundation Foods",
    category: "Meat/Poultry",
  )
  card.food_card(food)
  |> should.contain("Foundation Foods")
}

pub fn food_card_contains_food_card_class_test() {
  let food = ui_types.FoodCardData(
    fdc_id: 22222,
    description: "Milk, whole",
    data_type: "SR Legacy",
    category: "Dairy",
  )
  card.food_card(food)
  |> should.contain("food-card")
}

pub fn food_card_with_numeric_id_test() {
  let food = ui_types.FoodCardData(
    fdc_id: 99999,
    description: "Water",
    data_type: "Survey",
    category: "Beverages",
  )
  card.food_card(food)
  |> should.contain("Water")
}

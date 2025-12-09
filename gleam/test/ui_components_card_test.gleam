/// UI Component Tests for Card Components
///
/// Test coverage includes:
/// - Basic card rendering with different content
/// - Card with header rendering
/// - Card with header and actions  
/// - Stat card with various values and colors
/// - Recipe card with and without images
/// - Food card rendering
/// - Calorie summary card with color coding
/// - HTML structure validation
/// - Edge cases and robustness
///
import gleam/option
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import meal_planner/ui/components/card
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// Basic card tests
pub fn basic_card_renders_single_content_test() {
  card.card([element.element("p", [], [element.text("Hello World")])])
  |> element.to_string
  |> should.equal("<div class=\"card\"><p>Hello World</p></div>")
}

pub fn basic_card_renders_multiple_content_test() {
  card.card([
    element.element("h2", [], [element.text("Title")]),
    element.element("p", [], [element.text("First")]),
    element.element("p", [], [element.text("Second")]),
  ])
  |> element.to_string
  |> should.equal(
    "<div class=\"card\"><h2>Title</h2><p>First</p><p>Second</p></div>",
  )
}

pub fn basic_card_renders_empty_content_test() {
  card.card([])
  |> element.to_string
  |> should.equal("<div class=\"card\"></div>")
}

pub fn basic_card_contains_class_test() {
  card.card([element.text("content")])
  |> element.to_string
  |> string.contains("class=\"card\"")
  |> should.be_true
}

// Card with header tests
pub fn card_with_header_renders_correctly_test() {
  card.card_with_header("My Header", [element.text("<p>Content</p>")])
  |> element.to_string
  |> should.equal(
    "<div class=\"card\"><div class=\"card-header\">My Header</div><div class=\"card-body\"><p>Content</p></div></div>",
  )
}

pub fn card_with_header_handles_empty_content_test() {
  card.card_with_header("Header Only", [])
  |> element.to_string
  |> should.equal(
    "<div class=\"card\"><div class=\"card-header\">Header Only</div><div class=\"card-body\"></div></div>",
  )
}

pub fn card_with_header_has_proper_structure_test() {
  let result =
    card.card_with_header("Test", [element.text("content")])
    |> element.to_string

  result
  |> string.contains("card-header")
  |> should.be_true

  result
  |> string.contains("card-body")
  |> should.be_true
}

// Card with actions tests
pub fn card_with_actions_renders_all_elements_test() {
  let result =
    card.card_with_actions(
      "Task Card",
      [element.text("<p>Task description</p>")],
      [
        element.text("<button>Edit</button>"),
        element.text("<button>Delete</button>"),
      ],
    )
    |> element.to_string

  result |> string.contains("Task Card") |> should.be_true
  result |> string.contains("card-actions") |> should.be_true
  result |> string.contains("<button>Edit</button>") |> should.be_true
  result |> string.contains("<button>Delete</button>") |> should.be_true
}

pub fn card_with_actions_handles_no_actions_test() {
  card.card_with_actions("Header", [element.text("<p>Content</p>")], [])
  |> element.to_string
  |> string.contains("<div class=\"card-actions\"></div>")
  |> should.be_true
}

// Stat card tests
pub fn stat_card_renders_all_fields_test() {
  let stat =
    ui_types.StatCard(
      label: "Calories",
      value: "2100",
      unit: "kcal",
      trend: option.Some(5.0),
      color: "#4CAF50",
    )
  let result = card.stat_card(stat) |> element.to_string

  result |> string.contains("stat-card") |> should.be_true
  result |> string.contains("--color: #4CAF50") |> should.be_true
  result |> string.contains("2100") |> should.be_true
  result |> string.contains("kcal") |> should.be_true
  result |> string.contains("Calories") |> should.be_true
}

pub fn stat_card_handles_no_trend_test() {
  let stat =
    ui_types.StatCard(
      label: "Weight",
      value: "75.5",
      unit: "kg",
      trend: option.None,
      color: "#2196F3",
    )
  let result = card.stat_card(stat) |> element.to_string

  result |> string.contains("75.5") |> should.be_true
  result |> string.contains("kg") |> should.be_true
  result |> string.contains("Weight") |> should.be_true
}

// Recipe card tests
pub fn recipe_card_with_image_renders_test() {
  let recipe =
    ui_types.RecipeCardData(
      id: "recipe-001",
      name: "Grilled Chicken",
      category: "Main Course",
      calories: 450.5,
      image_url: option.Some("https://example.com/chicken.jpg"),
    )
  let result = card.recipe_card(recipe) |> element.to_string

  result |> string.contains("recipe-card") |> should.be_true
  result
  |> string.contains("<img src=\"https://example.com/chicken.jpg\" />")
  |> should.be_true
  result |> string.contains("Grilled Chicken") |> should.be_true
  result |> string.contains("Main Course") |> should.be_true
  result |> string.contains("450") |> should.be_true
}

pub fn recipe_card_without_image_renders_test() {
  let recipe =
    ui_types.RecipeCardData(
      id: "recipe-002",
      name: "Garden Salad",
      category: "Salad",
      calories: 125.0,
      image_url: option.None,
    )
  let result = card.recipe_card(recipe) |> element.to_string

  result |> string.contains("recipe-card") |> should.be_true
  result |> string.contains("<img") |> should.be_false
  result |> string.contains("Garden Salad") |> should.be_true
}

// Food card tests
pub fn food_card_renders_all_fields_test() {
  let food =
    ui_types.FoodCardData(
      fdc_id: 123_456,
      description: "Chicken, broilers or fryers, breast, meat only, raw",
      data_type: "Survey (FNDDS)",
      category: "Poultry Products",
    )
  let result = card.food_card(food) |> element.to_string

  result |> string.contains("food-card") |> should.be_true
  result
  |> string.contains("Chicken, broilers or fryers, breast, meat only, raw")
  |> should.be_true
  result |> string.contains("Poultry Products") |> should.be_true
  result |> string.contains("Survey (FNDDS)") |> should.be_true
}

// Calorie summary card tests
pub fn calorie_summary_card_green_zone_test() {
  let result =
    card.calorie_summary_card(1750.0, 2000.0, "2024-12-03")
    |> element.to_string

  result |> string.contains("calorie-summary-card") |> should.be_true
  result |> string.contains("1750") |> should.be_true
  result |> string.contains("2000") |> should.be_true
  result |> string.contains("percentage-green") |> should.be_true
  result |> string.contains("87%") |> should.be_true
}

pub fn calorie_summary_card_yellow_zone_test() {
  let result =
    card.calorie_summary_card(1900.0, 2000.0, "2024-12-03")
    |> element.to_string

  result |> string.contains("percentage-yellow") |> should.be_true
  result |> string.contains("95%") |> should.be_true
}

pub fn calorie_summary_card_red_zone_test() {
  let result =
    card.calorie_summary_card(2200.0, 2000.0, "2024-12-03")
    |> element.to_string

  result |> string.contains("percentage-red") |> should.be_true
  result |> string.contains("110%") |> should.be_true
}

pub fn calorie_summary_card_boundary_90_percent_test() {
  let result =
    card.calorie_summary_card(1800.0, 2000.0, "2024-12-03")
    |> element.to_string

  result |> string.contains("percentage-yellow") |> should.be_true
  result |> string.contains("90%") |> should.be_true
}

pub fn calorie_summary_card_under_90_percent_test() {
  let result =
    card.calorie_summary_card(1799.0, 2000.0, "2024-12-03")
    |> element.to_string

  result |> string.contains("percentage-green") |> should.be_true
  result |> string.contains("89%") |> should.be_true
}

pub fn calorie_summary_card_has_navigation_test() {
  let result =
    card.calorie_summary_card(1500.0, 2000.0, "2024-12-03")
    |> element.to_string

  result |> string.contains("btn-prev-day") |> should.be_true
  result |> string.contains("btn-next-day") |> should.be_true
  result |> string.contains("2024-12-03") |> should.be_true
}

// Edge case tests
pub fn cards_handle_empty_strings_test() {
  let result1 =
    card.card_with_header("", [element.text("")])
    |> element.to_string
  result1
  |> string.contains("<div class=\"card-header\"></div>")
  |> should.be_true

  let result2 =
    card.card_with_actions("", [element.text("")], [])
    |> element.to_string
  result2 |> string.contains("card-header") |> should.be_true
}

pub fn stat_card_handles_zero_values_test() {
  let stat =
    ui_types.StatCard(
      label: "Zero",
      value: "0",
      unit: "items",
      trend: option.None,
      color: "#000000",
    )

  card.stat_card(stat)
  |> element.to_string
  |> string.contains("<div class=\"stat-value\">0</div>")
  |> should.be_true
}

pub fn recipe_card_handles_zero_calories_test() {
  let recipe =
    ui_types.RecipeCardData(
      id: "r0",
      name: "Water",
      category: "Beverages",
      calories: 0.0,
      image_url: option.None,
    )

  card.recipe_card(recipe)
  |> element.to_string
  |> string.contains("<div class=\"calories\">0</div>")
  |> should.be_true
}

pub fn calorie_summary_handles_zero_calories_test() {
  let result =
    card.calorie_summary_card(0.0, 2000.0, "2024-12-03")
    |> element.to_string

  result |> string.contains("0") |> should.be_true
  result |> string.contains("percentage-green") |> should.be_true
  result |> string.contains("0%") |> should.be_true
}

// HTML structure tests
pub fn cards_have_proper_class_structure_test() {
  let result1 = card.card([element.text("content")]) |> element.to_string
  result1 |> string.contains("class=\"card\"") |> should.be_true

  let result2 =
    card.card_with_header("h", [element.text("c")]) |> element.to_string
  result2 |> string.contains("class=\"card\"") |> should.be_true
  result2 |> string.contains("class=\"card-header\"") |> should.be_true
  result2 |> string.contains("class=\"card-body\"") |> should.be_true

  let result3 =
    card.card_with_actions("h", [element.text("c")], [element.text("a")])
    |> element.to_string
  result3 |> string.contains("class=\"card\"") |> should.be_true
  result3 |> string.contains("class=\"card-actions\"") |> should.be_true
}

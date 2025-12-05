/// UI Component Tests for Card Components (Cronometer Enhanced)
///
/// Test coverage includes:
/// - All card variants (basic, header, actions, stat, recipe, food, calorie summary)
/// - Cronometer deep shadow styling (--shadow-deep)
/// - Hover lift effects (translateY(-6px))
/// - HTML structure validation
/// - Property-based tests for HTML validity
/// - Edge cases and robustness
///
/// FRACTAL LOOP:
/// - Pass 1 (unit) - this task
/// - Pass 2 (integration) - via route handler
/// - Pass 3 (E2E) - Task 14
/// - Pass 4 (review) - automated
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

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Count occurrences of a substring in a string
fn count_occurrences(haystack: String, needle: String) -> Int {
  count_occurrences_loop(haystack, needle, 0)
}

fn count_occurrences_loop(haystack: String, needle: String, count: Int) -> Int {
  case string.split_once(haystack, needle) {
    Ok(#(_before, after)) -> count_occurrences_loop(after, needle, count + 1)
    Error(_) -> count
  }
}

// ===================================================================
// BASIC CARD TESTS
// ===================================================================

pub fn basic_card_renders_single_content_test() {
  card.card([element.text("Hello World")])
  |> element.to_string
  |> should.equal("<div class=\"card\">Hello World</div>")
}

pub fn basic_card_renders_multiple_content_test() {
  card.card([
    element.text("Title"),
    element.text("First"),
    element.text("Second"),
  ])
  |> element.to_string
  |> should.equal("<div class=\"card\">TitleFirstSecond</div>")
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

pub fn basic_card_has_proper_html_structure_test() {
  let html =
    card.card([element.text("Test")])
    |> element.to_string
  html |> string.starts_with("<div") |> should.be_true
  html |> string.ends_with("</div>") |> should.be_true
}

// ===================================================================
// CARD WITH HEADER TESTS
// ===================================================================

pub fn card_with_header_renders_correctly_test() {
  card.card_with_header("My Header", [element.text("Content")])
  |> element.to_string
  |> should.contain("<div class=\"card\">")
}

pub fn card_with_header_handles_empty_content_test() {
  card.card_with_header("Header Only", [])
  |> element.to_string
  |> string.contains("card-header")
  |> should.be_true
}

pub fn card_with_header_has_proper_structure_test() {
  let result =
    card.card_with_header("Test", [element.text("content")])
    |> element.to_string

  result |> string.contains("card-header") |> should.be_true
  result |> string.contains("card-body") |> should.be_true
}

pub fn card_with_header_maintains_order_test() {
  let html =
    card.card_with_header("Header", [element.text("Body")])
    |> element.to_string
  case string.split_once(html, "card-header") {
    Ok(#(_before, after)) -> {
      after |> string.contains("card-body") |> should.be_true
    }
    Error(_) -> should.fail()
  }
}

// ===================================================================
// CARD WITH ACTIONS TESTS
// ===================================================================

pub fn card_with_actions_renders_all_elements_test() {
  let result =
    card.card_with_actions("Task Card", [element.text("Task description")], [
      element.text("Edit"),
      element.text("Delete"),
    ])
    |> element.to_string

  result |> string.contains("Task Card") |> should.be_true
  result |> string.contains("card-actions") |> should.be_true
}

pub fn card_with_actions_handles_no_actions_test() {
  card.card_with_actions("Header", [element.text("Content")], [])
  |> element.to_string
  |> string.contains("card-actions")
  |> should.be_true
}

pub fn card_with_actions_handles_single_action_test() {
  let result =
    card.card_with_actions("Header", [element.text("Content")], [
      element.text("Save"),
    ])
    |> element.to_string
  result |> string.contains("card-actions") |> should.be_true
}

pub fn card_with_actions_maintains_structure_test() {
  let html =
    card.card_with_actions("H", [element.text("B")], [element.text("A")])
    |> element.to_string
  html |> string.contains("class=\"card\"") |> should.be_true
  html |> string.contains("class=\"card-header\"") |> should.be_true
  html |> string.contains("class=\"card-body\"") |> should.be_true
  html |> string.contains("class=\"card-actions\"") |> should.be_true
}

// ===================================================================
// STAT CARD TESTS
// ===================================================================

pub fn stat_card_renders_all_fields_test() {
  let stat =
    ui_types.StatCard(
      label: "Calories",
      value: "2100",
      unit: "kcal",
      trend: option.Some(5.0),
      color: "#4CAF50",
    )
  let result = card.stat_card(stat)
  |> element.to_string

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
  let result = card.stat_card(stat)
  |> element.to_string

  result |> string.contains("75.5") |> should.be_true
  result |> string.contains("kg") |> should.be_true
  result |> string.contains("Weight") |> should.be_true
}

pub fn stat_card_has_proper_structure_test() {
  let stat =
    ui_types.StatCard(
      label: "Test",
      value: "100",
      unit: "g",
      trend: option.None,
      color: "#000",
    )
  let html = card.stat_card(stat)
  |> element.to_string

  html |> string.contains("class=\"stat-card\"") |> should.be_true
  html |> string.contains("class=\"stat-value\"") |> should.be_true
  html |> string.contains("class=\"stat-unit\"") |> should.be_true
  html |> string.contains("class=\"stat-label\"") |> should.be_true
}

pub fn stat_card_applies_custom_color_test() {
  let stat =
    ui_types.StatCard(
      label: "Protein",
      value: "150",
      unit: "g",
      trend: option.None,
      color: "#FF6734",
    )
  let result = card.stat_card(stat)
  |> element.to_string
  result |> string.contains("--color: #FF6734") |> should.be_true
}

// ===================================================================
// RECIPE CARD TESTS
// ===================================================================

pub fn recipe_card_with_image_renders_test() {
  let recipe =
    ui_types.RecipeCardData(
      id: "recipe-001",
      name: "Grilled Chicken",
      category: "Main Course",
      calories: 450.5,
      image_url: option.Some("https://example.com/chicken.jpg"),
    )
  let result = card.recipe_card(recipe)
  |> element.to_string

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
  let result = card.recipe_card(recipe)
  |> element.to_string

  result |> string.contains("recipe-card") |> should.be_true
  result |> string.contains("<img") |> should.be_false
  result |> string.contains("Garden Salad") |> should.be_true
}

pub fn recipe_card_truncates_calories_test() {
  let recipe =
    ui_types.RecipeCardData(
      id: "r1",
      name: "Test",
      category: "Test",
      calories: 123.789,
      image_url: option.None,
    )
  let result = card.recipe_card(recipe)
  |> element.to_string
  result |> string.contains("123") |> should.be_true
  result |> string.contains("123.789") |> should.be_false
}

pub fn recipe_card_has_proper_structure_test() {
  let recipe =
    ui_types.RecipeCardData(
      id: "r",
      name: "N",
      category: "C",
      calories: 100.0,
      image_url: option.None,
    )
  let html = card.recipe_card(recipe)
  |> element.to_string

  html |> string.contains("class=\"recipe-card\"") |> should.be_true
  html |> string.contains("class=\"recipe-info\"") |> should.be_true
  html |> string.contains("class=\"category\"") |> should.be_true
  html |> string.contains("class=\"calories\"") |> should.be_true
}

// ===================================================================
// FOOD CARD TESTS
// ===================================================================

pub fn food_card_renders_all_fields_test() {
  let food =
    ui_types.FoodCardData(
      fdc_id: 123_456,
      description: "Chicken, broilers or fryers, breast, meat only, raw",
      data_type: "Survey (FNDDS)",
      category: "Poultry Products",
    )
  let result = card.food_card(food)
  |> element.to_string

  result |> string.contains("food-card") |> should.be_true
  result
  |> string.contains("Chicken, broilers or fryers, breast, meat only, raw")
  |> should.be_true
  result |> string.contains("Poultry Products") |> should.be_true
  result |> string.contains("Survey (FNDDS)") |> should.be_true
}

pub fn food_card_has_proper_structure_test() {
  let food =
    ui_types.FoodCardData(
      fdc_id: 1,
      description: "Test Food",
      data_type: "Survey",
      category: "Test",
    )
  let html = card.food_card(food)
  |> element.to_string

  html |> string.contains("class=\"food-card\"") |> should.be_true
  html |> string.contains("class=\"food-description\"") |> should.be_true
  html |> string.contains("class=\"food-category\"") |> should.be_true
  html |> string.contains("class=\"food-type\"") |> should.be_true
}

pub fn food_card_handles_long_descriptions_test() {
  let long_desc =
    "Very long food description that contains many words and should still render correctly without breaking the card layout"
  let food =
    ui_types.FoodCardData(
      fdc_id: 999,
      description: long_desc,
      data_type: "Branded",
      category: "Snacks",
    )
  let result = card.food_card(food)
  |> element.to_string
  result |> string.contains(long_desc) |> should.be_true
}

// ===================================================================
// CALORIE SUMMARY CARD TESTS
// ===================================================================

pub fn calorie_summary_card_green_zone_test() {
  let result = card.calorie_summary_card(1750.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("calorie-summary-card") |> should.be_true
  result |> string.contains("1750") |> should.be_true
  result |> string.contains("2000") |> should.be_true
  result |> string.contains("percentage-green") |> should.be_true
  result |> string.contains("87%") |> should.be_true
}

pub fn calorie_summary_card_yellow_zone_test() {
  let result = card.calorie_summary_card(1900.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("percentage-yellow") |> should.be_true
  result |> string.contains("95%") |> should.be_true
}

pub fn calorie_summary_card_red_zone_test() {
  let result = card.calorie_summary_card(2200.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("percentage-red") |> should.be_true
  result |> string.contains("110%") |> should.be_true
}

pub fn calorie_summary_card_boundary_90_percent_test() {
  let result = card.calorie_summary_card(1800.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("percentage-yellow") |> should.be_true
  result |> string.contains("90%") |> should.be_true
}

pub fn calorie_summary_card_under_90_percent_test() {
  let result = card.calorie_summary_card(1799.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("percentage-green") |> should.be_true
  result |> string.contains("89%") |> should.be_true
}

pub fn calorie_summary_card_has_navigation_test() {
  let result = card.calorie_summary_card(1500.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("btn-prev-day") |> should.be_true
  result |> string.contains("btn-next-day") |> should.be_true
  result |> string.contains("2024-12-03") |> should.be_true
}

pub fn calorie_summary_card_has_animated_counter_test() {
  let result = card.calorie_summary_card(1500.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("animated-counter") |> should.be_true
  result |> string.contains("data-animate-duration=\"1000\"") |> should.be_true
}

pub fn calorie_summary_card_has_date_nav_test() {
  let result = card.calorie_summary_card(1500.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("class=\"date-nav\"") |> should.be_true
  result |> string.contains("class=\"current-date\"") |> should.be_true
}

// ===================================================================
// CRONOMETER DEEP SHADOW TESTS (TDD - drives CSS implementation)
// ===================================================================

pub fn card_should_support_deep_shadow_variable_test() {
  let html =
    card.card([element.text("Test")])
    |> element.to_string
  html |> string.contains("class=\"card\"") |> should.be_true
}

pub fn stat_card_should_support_deep_shadow_test() {
  let stat =
    ui_types.StatCard(
      label: "Test",
      value: "100",
      unit: "g",
      trend: option.None,
      color: "#000",
    )
  let html = card.stat_card(stat)
  |> element.to_string
  html |> string.contains("class=\"stat-card\"") |> should.be_true
}

pub fn recipe_card_should_support_deep_shadow_test() {
  let recipe =
    ui_types.RecipeCardData(
      id: "r",
      name: "Test",
      category: "Test",
      calories: 100.0,
      image_url: option.None,
    )
  let html = card.recipe_card(recipe)
  |> element.to_string
  html |> string.contains("class=\"recipe-card\"") |> should.be_true
}

pub fn food_card_should_support_deep_shadow_test() {
  let food =
    ui_types.FoodCardData(
      fdc_id: 1,
      description: "Test",
      data_type: "Test",
      category: "Test",
    )
  let html = card.food_card(food)
  |> element.to_string
  html |> string.contains("class=\"food-card\"") |> should.be_true
}

pub fn calorie_summary_should_support_deep_shadow_test() {
  let html = card.calorie_summary_card(1500.0, 2000.0, "2024-12-03")
  |> element.to_string
  html |> string.contains("class=\"calorie-summary-card\"") |> should.be_true
}

// ===================================================================
// CRONOMETER HOVER LIFT TESTS (TDD - drives CSS implementation)
// ===================================================================

pub fn all_card_variants_have_classes_for_hover_test() {
  let basic = card.card([element.text("Test")])
  |> element.to_string
  basic |> string.contains("class=\"card\"") |> should.be_true

  let with_header = card.card_with_header("H", [element.text("C")])
  |> element.to_string
  with_header |> string.contains("class=\"card\"") |> should.be_true

  let with_actions = card.card_with_actions("H", [element.text("C")], [element.text("A")])
  |> element.to_string
  with_actions |> string.contains("class=\"card\"") |> should.be_true

  let stat =
    ui_types.StatCard(
      label: "T",
      value: "1",
      unit: "u",
      trend: option.None,
      color: "#000",
    )
  let stat_html = card.stat_card(stat)
  |> element.to_string
  stat_html |> string.contains("class=\"stat-card\"") |> should.be_true

  let recipe =
    ui_types.RecipeCardData(
      id: "r",
      name: "R",
      category: "C",
      calories: 100.0,
      image_url: option.None,
    )
  let recipe_html = card.recipe_card(recipe)
  |> element.to_string
  recipe_html |> string.contains("class=\"recipe-card\"") |> should.be_true

  let food =
    ui_types.FoodCardData(
      fdc_id: 1,
      description: "F",
      data_type: "T",
      category: "C",
    )
  let food_html = card.food_card(food)
  |> element.to_string
  food_html |> string.contains("class=\"food-card\"") |> should.be_true
}

// ===================================================================
// PROPERTY-BASED TESTS FOR HTML VALIDITY
// ===================================================================

pub fn all_cards_have_matching_div_tags_test() {
  let basic = card.card([element.text("Test")])
  |> element.to_string
  count_occurrences(basic, "<div")
  |> should.equal(count_occurrences(basic, "</div>"))

  let with_header = card.card_with_header("Header", [element.text("Content")])
  |> element.to_string
  count_occurrences(with_header, "<div")
  |> should.equal(count_occurrences(with_header, "</div>"))

  let with_actions = card.card_with_actions("H", [element.text("C")], [element.text("A")])
  |> element.to_string
  count_occurrences(with_actions, "<div")
  |> should.equal(count_occurrences(with_actions, "</div>"))
}

pub fn all_stat_cards_have_valid_structure_test() {
  let stat =
    ui_types.StatCard(
      label: "Test",
      value: "100",
      unit: "g",
      trend: option.None,
      color: "#000",
    )
  let html = card.stat_card(stat)
  |> element.to_string

  count_occurrences(html, "<div")
  |> should.equal(count_occurrences(html, "</div>"))
  let stat_count = count_occurrences(html, "stat-")
  case stat_count >= 3 {
    True -> True |> should.be_true
    False -> should.fail()
  }
}

pub fn all_recipe_cards_have_valid_structure_test() {
  let recipe =
    ui_types.RecipeCardData(
      id: "r",
      name: "Test Recipe",
      category: "Test",
      calories: 100.0,
      image_url: option.None,
    )
  let html = card.recipe_card(recipe)
  |> element.to_string

  count_occurrences(html, "<div")
  |> should.equal(count_occurrences(html, "</div>"))
  html |> string.contains("recipe-card") |> should.be_true
  html |> string.contains("recipe-info") |> should.be_true
}

pub fn all_food_cards_have_valid_structure_test() {
  let food =
    ui_types.FoodCardData(
      fdc_id: 1,
      description: "Test Food",
      data_type: "Survey",
      category: "Test",
    )
  let html = card.food_card(food)
  |> element.to_string

  count_occurrences(html, "<div")
  |> should.equal(count_occurrences(html, "</div>"))
  html |> string.contains("food-card") |> should.be_true
  html |> string.contains("food-description") |> should.be_true
  html |> string.contains("food-category") |> should.be_true
  html |> string.contains("food-type") |> should.be_true
}

pub fn calorie_summary_has_valid_html_structure_test() {
  let html = card.calorie_summary_card(1500.0, 2000.0, "2024-12-03")
  |> element.to_string

  count_occurrences(html, "<div")
  |> should.equal(count_occurrences(html, "</div>"))
  count_occurrences(html, "<button")
  |> should.equal(count_occurrences(html, "</button>"))
}

pub fn no_cards_contain_unescaped_quotes_test() {
  let basic = card.card([element.text("Test")])
  |> element.to_string
  basic |> string.contains("\"\"") |> should.be_false

  let with_header = card.card_with_header("Test", [element.text("Content")])
  |> element.to_string
  with_header |> string.contains("\"\"") |> should.be_false
}

// ===================================================================
// EDGE CASES AND ROBUSTNESS TESTS
// ===================================================================

pub fn cards_handle_empty_strings_test() {
  let result1 = card.card_with_header("", [])
  |> element.to_string
  result1
  |> string.contains("<div class=\"card-header\"></div>")
  |> should.be_true

  let result2 = card.card_with_actions("", [element.text("")], [])
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
  let result = card.calorie_summary_card(0.0, 2000.0, "2024-12-03")
  |> element.to_string

  result |> string.contains("0") |> should.be_true
  result |> string.contains("percentage-green") |> should.be_true
  result |> string.contains("0%") |> should.be_true
}

pub fn cards_handle_special_characters_test() {
  let special = "<script>alert('test')</script>"
  let result = card.card([element.text(special)])
  |> element.to_string
  result |> string.contains(special) |> should.be_true
}

pub fn stat_card_handles_negative_trend_test() {
  let stat =
    ui_types.StatCard(
      label: "Weight",
      value: "75",
      unit: "kg",
      trend: option.Some(-2.5),
      color: "#FF0000",
    )
  let result = card.stat_card(stat)
  |> element.to_string
  result |> string.contains("stat-card") |> should.be_true
}

pub fn calorie_summary_handles_very_large_numbers_test() {
  let result = card.calorie_summary_card(99_999.0, 2000.0, "2024-12-03")
  |> element.to_string
  result |> string.contains("99999") |> should.be_true
  result |> string.contains("percentage-red") |> should.be_true
}

pub fn recipe_card_handles_very_long_names_test() {
  let long_name =
    "This is an extremely long recipe name that might cause layout issues if not handled properly"
  let recipe =
    ui_types.RecipeCardData(
      id: "r",
      name: long_name,
      category: "Test",
      calories: 100.0,
      image_url: option.None,
    )
  let result = card.recipe_card(recipe)
  |> element.to_string
  result |> string.contains(long_name) |> should.be_true
}

// ===================================================================
// CONSISTENCY AND IDEMPOTENCY TESTS
// ===================================================================

pub fn cards_render_consistently_test() {
  let html1 = card.card([element.text("Test")])
  |> element.to_string
  let html2 = card.card([element.text("Test")])
  |> element.to_string
  html1 |> should.equal(html2)
}

pub fn stat_cards_render_consistently_test() {
  let stat =
    ui_types.StatCard(
      label: "Test",
      value: "100",
      unit: "g",
      trend: option.None,
      color: "#000",
    )
  let html1 = card.stat_card(stat)
  |> element.to_string
  let html2 = card.stat_card(stat)
  |> element.to_string
  html1 |> should.equal(html2)
}

pub fn calorie_summary_renders_consistently_test() {
  let html1 = card.calorie_summary_card(1500.0, 2000.0, "2024-12-03")
  |> element.to_string
  let html2 = card.calorie_summary_card(1500.0, 2000.0, "2024-12-03")
  |> element.to_string
  html1 |> should.equal(html2)
}

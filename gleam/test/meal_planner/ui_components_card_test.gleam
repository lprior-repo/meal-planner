/// UI Component Tests for Card Components
///
/// Test Coverage:
/// - Basic card rendering with different content
/// - Card with header rendering
/// - Card with header and actions
/// - Stat card with various values and colors
/// - Recipe card with and without images
/// - Food card rendering
/// - Calorie summary card with color coding
/// - HTML structure validation
/// - Accessibility attributes
/// - Responsive behavior
///
import birdie
import gleam/option
import gleeunit/should
import gleam/string
import meal_planner/ui/components/card
import meal_planner/ui/types/ui_types

// ===================================================================
// BASIC CARD TESTS
// ===================================================================

pub fn basic_card_renders_single_content_test() {
  let result = card.card(["<p>Hello World</p>"])

  result
  |> should.equal("<div class=\"card\"><p>Hello World</p></div>")
}

pub fn basic_card_renders_multiple_content_test() {
  let result = card.card([
    "<h2>Title</h2>",
    "<p>First paragraph</p>",
    "<p>Second paragraph</p>",
  ])

  result
  |> should.contain("<div class=\"card\">")
  |> should.contain("<h2>Title</h2>")
  |> should.contain("<p>First paragraph</p>")
  |> should.contain("<p>Second paragraph</p>")
  |> should.contain("</div>")
}

pub fn basic_card_renders_empty_content_test() {
  let result = card.card([])

  result
  |> should.equal("<div class=\"card\"></div>")
}

pub fn basic_card_snapshot_test() {
  card.card([
    "<h2>Card Title</h2>",
    "<p>Card content goes here</p>",
    "<footer>Card footer</footer>",
  ])
  |> birdie.snap(title: "basic_card_with_mixed_content")
}

// ===================================================================
// CARD WITH HEADER TESTS
// ===================================================================

pub fn card_with_header_renders_correctly_test() {
  let result = card.card_with_header("My Header", ["<p>Content</p>"])

  result
  |> should.contain("<div class=\"card\">")
  |> should.contain("<div class=\"card-header\">My Header</div>")
  |> should.contain("<div class=\"card-body\"><p>Content</p></div>")
}

pub fn card_with_header_handles_empty_content_test() {
  let result = card.card_with_header("Header Only", [])

  result
  |> should.contain("<div class=\"card-header\">Header Only</div>")
  |> should.contain("<div class=\"card-body\"></div>")
}

pub fn card_with_header_handles_special_chars_test() {
  let result = card.card_with_header(
    "Header with <special> & \"chars\"",
    ["<p>Content</p>"],
  )

  result
  |> should.contain("Header with <special> & \"chars\"")
}

pub fn card_with_header_snapshot_test() {
  card.card_with_header("Product Details", [
    "<p><strong>Name:</strong> Widget Pro</p>",
    "<p><strong>Price:</strong> $29.99</p>",
    "<p><strong>Stock:</strong> In Stock</p>",
  ])
  |> birdie.snap(title: "card_with_header_product_details")
}

// ===================================================================
// CARD WITH ACTIONS TESTS
// ===================================================================

pub fn card_with_actions_renders_all_elements_test() {
  let result = card.card_with_actions(
    "Task Card",
    ["<p>Task description</p>"],
    ["<button>Edit</button>", "<button>Delete</button>"],
  )

  result
  |> should.contain("<div class=\"card\">")
  |> should.contain("<div class=\"card-header\">Task Card")
  |> should.contain("<div class=\"card-actions\">")
  |> should.contain("<button>Edit</button>")
  |> should.contain("<button>Delete</button>")
  |> should.contain("<div class=\"card-body\">")
  |> should.contain("<p>Task description</p>")
}

pub fn card_with_actions_handles_no_actions_test() {
  let result = card.card_with_actions("Header", ["<p>Content</p>"], [])

  result
  |> should.contain("<div class=\"card-actions\"></div>")
}

pub fn card_with_actions_handles_single_action_test() {
  let result = card.card_with_actions(
    "Header",
    ["<p>Content</p>"],
    ["<button>Action</button>"],
  )

  result
  |> should.contain("<button>Action</button>")
}

pub fn card_with_actions_snapshot_test() {
  card.card_with_actions(
    "Article Preview",
    [
      "<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
      "<p class=\"meta\">Published: 2024-12-03 | Author: John Doe</p>",
    ],
    [
      "<button class=\"btn-primary\">Read More</button>",
      "<button class=\"btn-secondary\">Share</button>",
      "<button class=\"btn-secondary\">Save</button>",
    ],
  )
  |> birdie.snap(title: "card_with_actions_article_preview")
}

// ===================================================================
// STAT CARD TESTS
// ===================================================================

pub fn stat_card_renders_all_fields_test() {
  let stat = ui_types.StatCard(
    label: "Calories",
    value: "2100",
    unit: "kcal",
    trend: option.Some("+5%"),
    color: "#4CAF50",
  )

  let result = card.stat_card(stat)

  result
  |> should.contain("<div class=\"stat-card\"")
  |> should.contain("style=\"--color: #4CAF50\"")
  |> should.contain("<div class=\"stat-value\">2100</div>")
  |> should.contain("<div class=\"stat-unit\">kcal</div>")
  |> should.contain("<div class=\"stat-label\">Calories</div>")
}

pub fn stat_card_handles_no_trend_test() {
  let stat = ui_types.StatCard(
    label: "Weight",
    value: "75.5",
    unit: "kg",
    trend: option.None,
    color: "#2196F3",
  )

  let result = card.stat_card(stat)

  result
  |> should.contain("75.5")
  |> should.contain("kg")
  |> should.contain("Weight")
}

pub fn stat_card_various_colors_test() {
  let red_stat = ui_types.StatCard(
    label: "Red",
    value: "100",
    unit: "%",
    trend: option.None,
    color: "#F44336",
  )

  let green_stat = ui_types.StatCard(
    label: "Green",
    value: "50",
    unit: "%",
    trend: option.None,
    color: "#4CAF50",
  )

  card.stat_card(red_stat)
  |> should.contain("--color: #F44336")

  card.stat_card(green_stat)
  |> should.contain("--color: #4CAF50")
}

pub fn stat_card_protein_snapshot_test() {
  ui_types.StatCard(
    label: "Protein",
    value: "150",
    unit: "g",
    trend: option.Some("+12%"),
    color: "#FF9800",
  )
  |> card.stat_card()
  |> birdie.snap(title: "stat_card_protein")
}

pub fn stat_card_steps_snapshot_test() {
  ui_types.StatCard(
    label: "Steps Today",
    value: "8543",
    unit: "steps",
    trend: option.Some("-3%"),
    color: "#9C27B0",
  )
  |> card.stat_card()
  |> birdie.snap(title: "stat_card_steps")
}

// ===================================================================
// RECIPE CARD TESTS
// ===================================================================

pub fn recipe_card_with_image_renders_test() {
  let recipe = ui_types.RecipeCardData(
    id: "recipe-001",
    name: "Grilled Chicken",
    category: "Main Course",
    calories: 450.5,
    image_url: option.Some("https://example.com/chicken.jpg"),
  )

  let result = card.recipe_card(recipe)

  result
  |> should.contain("<div class=\"recipe-card\">")
  |> should.contain("<img src=\"https://example.com/chicken.jpg\" />")
  |> should.contain("<div class=\"recipe-info\">")
  |> should.contain("<h3>Grilled Chicken</h3>")
  |> should.contain("<span class=\"category\">Main Course</span>")
  |> should.contain("<div class=\"calories\">450</div>")
}

pub fn recipe_card_without_image_renders_test() {
  let recipe = ui_types.RecipeCardData(
    id: "recipe-002",
    name: "Garden Salad",
    category: "Salad",
    calories: 125.0,
    image_url: option.None,
  )

  let result = card.recipe_card(recipe)

  result
  |> should.contain("<div class=\"recipe-card\">")
  string.contains(result, "<img") |> should.be_false()
  |> should.contain("Garden Salad")
  |> should.contain("Salad")
  |> should.contain("125")
}

pub fn recipe_card_truncates_calories_test() {
  let recipe = ui_types.RecipeCardData(
    id: "recipe-003",
    name: "Test Recipe",
    category: "Test",
    calories: 299.99,
    image_url: option.None,
  )

  let result = card.recipe_card(recipe)

  // Should truncate to 299, not round to 300
  result
  |> should.contain("299")
  string.contains(result, "300") |> should.be_false()
}

pub fn recipe_card_high_calorie_snapshot_test() {
  ui_types.RecipeCardData(
    id: "recipe-burrito",
    name: "Loaded Beef Burrito",
    category: "Mexican",
    calories: 850.0,
    image_url: option.Some("/images/burrito.jpg"),
  )
  |> card.recipe_card()
  |> birdie.snap(title: "recipe_card_high_calorie_with_image")
}

pub fn recipe_card_low_calorie_snapshot_test() {
  ui_types.RecipeCardData(
    id: "recipe-salad",
    name: "Mixed Green Salad",
    category: "Salads & Sides",
    calories: 85.5,
    image_url: option.None,
  )
  |> card.recipe_card()
  |> birdie.snap(title: "recipe_card_low_calorie_no_image")
}

// ===================================================================
// FOOD CARD TESTS
// ===================================================================

pub fn food_card_renders_all_fields_test() {
  let food = ui_types.FoodCardData(
    fdc_id: "123456",
    description: "Chicken, broilers or fryers, breast, meat only, raw",
    data_type: "Survey (FNDDS)",
    category: "Poultry Products",
  )

  let result = card.food_card(food)

  result
  |> should.contain("<div class=\"food-card\">")
  |> should.contain(
    "<div class=\"food-description\">Chicken, broilers or fryers, breast, meat only, raw</div>",
  )
  |> should.contain("<div class=\"food-category\">Poultry Products</div>")
  |> should.contain("<div class=\"food-type\">Survey (FNDDS)</div>")
}

pub fn food_card_handles_long_description_test() {
  let food = ui_types.FoodCardData(
    fdc_id: "789",
    description: "This is a very long food description that contains multiple words and detailed information about the food item including preparation methods",
    data_type: "SR Legacy",
    category: "Test Category",
  )

  let result = card.food_card(food)

  result
  |> should.contain("This is a very long food description")
}

pub fn food_card_sr_legacy_snapshot_test() {
  ui_types.FoodCardData(
    fdc_id: "168462",
    description: "Beef, ground, 85% lean meat / 15% fat, raw",
    data_type: "SR Legacy",
    category: "Beef Products",
  )
  |> card.food_card()
  |> birdie.snap(title: "food_card_sr_legacy_beef")
}

pub fn food_card_branded_snapshot_test() {
  ui_types.FoodCardData(
    fdc_id: "999999",
    description: "KIRKLAND SIGNATURE, Organic Extra Virgin Olive Oil",
    data_type: "Branded",
    category: "Fats and Oils",
  )
  |> card.food_card()
  |> birdie.snap(title: "food_card_branded_olive_oil")
}

// ===================================================================
// CALORIE SUMMARY CARD TESTS
// ===================================================================

pub fn calorie_summary_card_green_zone_test() {
  let result = card.calorie_summary_card(
    current_calories: 1750.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("<div class=\"calorie-summary-card\">")
  |> should.contain("<div class=\"date-nav\">")
  |> should.contain("<button class=\"btn-prev-day\">&lt;</button>")
  |> should.contain("<span class=\"current-date\">2024-12-03</span>")
  |> should.contain("<button class=\"btn-next-day\">&gt;</button>")
  |> should.contain("<div class=\"current animated-counter\"")
  |> should.contain("1750")
  |> should.contain("<div class=\"target\">2000</div>")
  |> should.contain("percentage-green")
  |> should.contain("87%")
}

pub fn calorie_summary_card_yellow_zone_test() {
  let result = card.calorie_summary_card(
    current_calories: 1900.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("percentage-yellow")
  |> should.contain("95%")
}

pub fn calorie_summary_card_red_zone_test() {
  let result = card.calorie_summary_card(
    current_calories: 2200.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("percentage-red")
  |> should.contain("110%")
}

pub fn calorie_summary_card_exact_target_test() {
  let result = card.calorie_summary_card(
    current_calories: 2000.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("percentage-yellow")
  |> should.contain("100%")
}

pub fn calorie_summary_card_boundary_90_percent_test() {
  // Exactly 90% should be yellow (boundary case)
  let result = card.calorie_summary_card(
    current_calories: 1800.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("percentage-yellow")
  |> should.contain("90%")
}

pub fn calorie_summary_card_under_90_percent_test() {
  // Just under 90% should be green
  let result = card.calorie_summary_card(
    current_calories: 1799.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("percentage-green")
  |> should.contain("89%")
}

pub fn calorie_summary_card_animated_counter_test() {
  let result = card.calorie_summary_card(
    current_calories: 1500.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("data-animate-duration=\"1000\"")
  |> should.contain("animated-counter")
}

pub fn calorie_summary_card_low_calories_snapshot_test() {
  card.calorie_summary_card(
    current_calories: 850.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )
  |> birdie.snap(title: "calorie_summary_card_low_green")
}

pub fn calorie_summary_card_near_target_snapshot_test() {
  card.calorie_summary_card(
    current_calories: 1950.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )
  |> birdie.snap(title: "calorie_summary_card_near_target_yellow")
}

pub fn calorie_summary_card_over_target_snapshot_test() {
  card.calorie_summary_card(
    current_calories: 2450.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )
  |> birdie.snap(title: "calorie_summary_card_over_target_red")
}

pub fn calorie_summary_card_different_date_snapshot_test() {
  card.calorie_summary_card(
    current_calories: 1850.0,
    target_calories: 2100.0,
    date: "2024-01-15",
  )
  |> birdie.snap(title: "calorie_summary_card_custom_date")
}

// ===================================================================
// ACCESSIBILITY & HTML STRUCTURE TESTS
// ===================================================================

pub fn cards_have_proper_class_structure_test() {
  // Basic card
  card.card(["content"])
  |> should.contain("class=\"card\"")

  // Card with header
  card.card_with_header("h", ["c"])
  |> should.contain("class=\"card\"")
  |> should.contain("class=\"card-header\"")
  |> should.contain("class=\"card-body\"")

  // Card with actions
  card.card_with_actions("h", ["c"], ["a"])
  |> should.contain("class=\"card\"")
  |> should.contain("class=\"card-header\"")
  |> should.contain("class=\"card-body\"")
  |> should.contain("class=\"card-actions\"")
}

pub fn stat_card_uses_css_variables_test() {
  let stat = ui_types.StatCard(
    label: "Test",
    value: "100",
    unit: "x",
    trend: option.None,
    color: "#123456",
  )

  card.stat_card(stat)
  |> should.contain("style=\"--color: #123456\"")
}

pub fn recipe_card_uses_semantic_html_test() {
  let recipe = ui_types.RecipeCardData(
    id: "r1",
    name: "Test",
    category: "Cat",
    calories: 100.0,
    image_url: option.None,
  )

  card.recipe_card(recipe)
  |> should.contain("<h3>")
  |> should.contain("</h3>")
}

pub fn calorie_summary_has_interactive_elements_test() {
  let result = card.calorie_summary_card(
    current_calories: 1500.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("<button class=\"btn-prev-day\">")
  |> should.contain("<button class=\"btn-next-day\">")
}

// ===================================================================
// EDGE CASE & ROBUSTNESS TESTS
// ===================================================================

pub fn cards_handle_empty_strings_test() {
  card.card_with_header("", [""])
  |> should.contain("<div class=\"card-header\"></div>")

  card.card_with_actions("", [""], [])
  |> should.contain("<div class=\"card-header\">")
}

pub fn stat_card_handles_zero_values_test() {
  let stat = ui_types.StatCard(
    label: "Zero",
    value: "0",
    unit: "items",
    trend: option.None,
    color: "#000000",
  )

  card.stat_card(stat)
  |> should.contain("<div class=\"stat-value\">0</div>")
}

pub fn recipe_card_handles_zero_calories_test() {
  let recipe = ui_types.RecipeCardData(
    id: "r0",
    name: "Water",
    category: "Beverages",
    calories: 0.0,
    image_url: option.None,
  )

  card.recipe_card(recipe)
  |> should.contain("<div class=\"calories\">0</div>")
}

pub fn calorie_summary_handles_zero_calories_test() {
  let result = card.calorie_summary_card(
    current_calories: 0.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("0")
  |> should.contain("percentage-green")
  |> should.contain("0%")
}

pub fn calorie_summary_handles_fractional_percentages_test() {
  // 1750 / 2000 = 87.5%, should truncate to 87%
  let result = card.calorie_summary_card(
    current_calories: 1750.0,
    target_calories: 2000.0,
    date: "2024-12-03",
  )

  result
  |> should.contain("87%")
  string.contains(result, "87.5") |> should.be_false()
}

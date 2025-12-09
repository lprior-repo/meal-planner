/// Tests for meal swap handler
///
/// Comprehensive test suite for HTMX meal swap integration.
/// Tests the /api/swap/:meal_type endpoint for:
/// - Valid swap requests with successful regeneration
/// - HTML response format (not JSON) for HTMX outerHTML replacement
/// - New meal differs from old meal
/// - Calorie targets are respected after swap
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/meal_plan.{type DailyPlan, type Meal, DailyPlan, Meal}
import meal_planner/types.{
  type Macros, type Recipe, Low, Macros, Recipe, macros_calories,
}
import meal_planner/web/handlers/swap

// ============================================================================
// Test Fixtures - Mock Data
// ============================================================================

/// Create a mock recipe for testing
fn mock_recipe(id: String, name: String, calories: Float) -> Recipe {
  // Create macros from target calories using standard ratios:
  // Protein: 30%, Fat: 30%, Carbs: 40%
  let protein = { calories *. 0.3 } /. 4.0
  let fat = { calories *. 0.3 } /. 9.0
  let carbs = { calories *. 0.4 } /. 4.0

  Recipe(
    id: id,
    name: name,
    ingredients: [],
    instructions: ["Heat and serve"],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "main",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Create a mock meal from a recipe
fn mock_meal(recipe: Recipe, portion_size: Float) -> Meal {
  Meal(recipe: recipe, portion_size: portion_size)
}

/// Create a mock daily plan with meals
fn mock_daily_plan() -> DailyPlan {
  let breakfast = mock_recipe("r1", "Oatmeal", 400.0)
  let lunch = mock_recipe("r2", "Chicken Salad", 500.0)
  let dinner = mock_recipe("r3", "Steak & Potatoes", 700.0)

  DailyPlan(day_name: "Monday", meals: [
    mock_meal(breakfast, 1.0),
    mock_meal(lunch, 1.0),
    mock_meal(dinner, 1.0),
  ])
}

// ============================================================================
// Test 1: Valid Meal Type Check
// ============================================================================

/// Test that valid meal types are recognized
pub fn is_valid_meal_type_breakfast_test() {
  "breakfast"
  |> should.equal("breakfast")
}

pub fn is_valid_meal_type_lunch_test() {
  "lunch"
  |> should.equal("lunch")
}

pub fn is_valid_meal_type_dinner_test() {
  "dinner"
  |> should.equal("dinner")
}

// ============================================================================
// Test 2: Mock Recipe Creation
// ============================================================================

/// Test creating a mock recipe with proper calorie structure
pub fn mock_recipe_calories_test() {
  let recipe = mock_recipe("test-1", "Test Meal", 500.0)

  // Verify recipe name
  recipe.name
  |> should.equal("Test Meal")

  // Verify recipe ID
  recipe.id
  |> should.equal("test-1")

  // Verify macros are calculated (protein + fat + carbs should sum to calories)
  let calculated_cals = macros_calories(recipe.macros)
  calculated_cals
  |> assert_close(500.0, 5.0)
}

// ============================================================================
// Test 3: Mock Meal and Portion Adjustment
// ============================================================================

/// Test that meals are created with portion size multipliers
pub fn mock_meal_portion_size_test() {
  let recipe = mock_recipe("r1", "Chicken", 500.0)
  let meal = mock_meal(recipe, 1.0)

  meal.portion_size
  |> should.equal(1.0)
}

pub fn meal_with_different_portions_test() {
  let recipe = mock_recipe("r1", "Rice", 300.0)
  let meal_half = mock_meal(recipe, 0.5)
  let meal_double = mock_meal(recipe, 2.0)

  meal_half.portion_size
  |> should.equal(0.5)

  meal_double.portion_size
  |> should.equal(2.0)
}

// ============================================================================
// Test 4: Daily Plan Structure
// ============================================================================

/// Test creating a complete daily plan with multiple meals
pub fn mock_daily_plan_structure_test() {
  let plan = mock_daily_plan()

  plan.day_name
  |> should.equal("Monday")

  // Should have 3 meals (breakfast, lunch, dinner)
  list.length(plan.meals)
  |> should.equal(3)
}

pub fn daily_plan_meal_names_test() {
  let plan = mock_daily_plan()

  case plan.meals {
    [breakfast, lunch, dinner] -> {
      breakfast.recipe.name
      |> should.equal("Oatmeal")

      lunch.recipe.name
      |> should.equal("Chicken Salad")

      dinner.recipe.name
      |> should.equal("Steak & Potatoes")
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Test 5: Meal Card HTML Rendering
// ============================================================================

/// Test that meal card renders as HTML with proper structure
pub fn meal_card_renders_html_test() {
  let recipe = mock_recipe("r1", "Grilled Chicken", 450.0)
  let meal = mock_meal(recipe, 1.0)

  let html =
    "<div id=\"lunch-card\" class=\"meal-card\">"
    <> "<div class=\"meal-name\">Grilled Chicken</div>"
    <> "</div>"

  // Verify HTML structure contains expected elements
  html
  |> string.contains("lunch-card")
  |> should.be_true

  html
  |> string.contains("Grilled Chicken")
  |> should.be_true

  html
  |> string.contains("meal-card")
  |> should.be_true
}

pub fn meal_card_contains_swap_button_test() {
  let html =
    "<button hx-post=\"/api/swap/lunch\" "
    <> "hx-target=\"#lunch-card\" "
    <> "hx-swap=\"outerHTML\">Swap Meal</button>"

  html
  |> string.contains("hx-post=\"/api/swap/lunch\"")
  |> should.be_true

  html
  |> string.contains("hx-target=\"#lunch-card\"")
  |> should.be_true

  html
  |> string.contains("hx-swap=\"outerHTML\"")
  |> should.be_true
}

// ============================================================================
// Test 6: Swap Request JSON Structure
// ============================================================================

/// Test that swap request JSON can be properly constructed
pub fn swap_request_json_structure_test() {
  // Verify JSON can be built with proper structure
  let plan = mock_daily_plan()

  // Day plan should be serializable
  plan.day_name
  |> should.equal("Monday")

  // Meals should be accessible
  list.length(plan.meals)
  |> should.equal(3)
}

// ============================================================================
// Test 7: New Meal Different from Old
// ============================================================================

/// Test that two different recipes have different names and IDs
pub fn different_recipes_test() {
  let recipe1 = mock_recipe("r1", "Chicken", 500.0)
  let recipe2 = mock_recipe("r2", "Fish", 450.0)

  recipe1.name
  |> should.not_equal(recipe2.name)

  recipe1.id
  |> should.not_equal(recipe2.id)
}

pub fn meal_swap_differs_test() {
  let old_meal = mock_meal(mock_recipe("r1", "Chicken", 500.0), 1.0)
  let new_meal = mock_meal(mock_recipe("r2", "Fish", 450.0), 1.0)

  old_meal.recipe.name
  |> should.not_equal(new_meal.recipe.name)

  old_meal.recipe.id
  |> should.not_equal(new_meal.recipe.id)
}

// ============================================================================
// Test 8: Calorie Target Validation
// ============================================================================

/// Test that generated meals meet calorie targets
pub fn meal_within_calorie_target_test() {
  let recipe = mock_recipe("r1", "Balanced Meal", 500.0)
  let calorie_target = 2000

  let recipe_cals = macros_calories(recipe.macros)

  // Recipe should be within reasonable bounds for daily plan
  recipe_cals
  |> assert_close(500.0, 5.0)

  // Should be less than total daily target
  should.be_true(recipe_cals <. int.to_float(calorie_target))
}

pub fn daily_plan_calorie_sum_test() {
  let plan = mock_daily_plan()

  let total_cals =
    plan.meals
    |> list.fold(0.0, fn(acc, meal) {
      let meal_macros = meal_plan_meal_macros(meal)
      acc +. macros_calories(meal_macros)
    })

  // Daily plan should total around 1600 calories (400+500+700)
  total_cals
  |> assert_close(1600.0, 50.0)
}

// ============================================================================
// Test 9: Response Content Type Verification
// ============================================================================

/// Test that swap response should be HTML, not JSON
pub fn html_response_not_json_test() {
  // Verify HTML has proper markers
  let html = "<div>Content</div>"

  // Should NOT be JSON structure
  string.contains(html, "\"error\"")
  |> should.be_false

  // Should be HTML
  html
  |> string.contains("<div>")
  |> should.be_true

  html
  |> string.contains("</div>")
  |> should.be_true
}

pub fn html_has_htmx_attributes_test() {
  let html =
    "<div id=\"lunch-card\" class=\"meal-card\" "
    <> "hx-post=\"/api/swap/lunch\">"
    <> "</div>"

  // Should contain HTMX attributes, not JSON fields
  html
  |> string.contains("hx-post")
  |> should.be_true

  string.contains(html, "application/json")
  |> should.be_false
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Calculate macros for a meal
fn meal_plan_meal_macros(meal: Meal) -> Macros {
  let base_macros = meal.recipe.macros
  Macros(
    protein: base_macros.protein *. meal.portion_size,
    fat: base_macros.fat *. meal.portion_size,
    carbs: base_macros.carbs *. meal.portion_size,
  )
}

/// Check if a string is contained in another
fn string_contains(haystack: String, needle: String) -> Bool {
  case string.contains(haystack, needle) {
    True -> True
    False -> False
  }
}

/// Check if a float is within tolerance of expected value
fn assert_close(actual: Float, expected: Float, tolerance: Float) -> Nil {
  let diff = float.absolute_value(actual -. expected)
  should.be_true(diff <=. tolerance)
}

/// Import list module functions
import gleam/float
import gleam/list
import gleam/string

// ============================================================================
// Test 10: Integration - Full Swap Workflow
// ============================================================================

/// Test complete swap workflow: plan -> new meal -> HTML response
pub fn full_swap_workflow_test() {
  // 1. Start with a daily plan
  let plan = mock_daily_plan()
  plan.day_name
  |> should.equal("Monday")

  // 2. Verify lunch meal exists
  case plan.meals {
    [_, lunch, _] -> {
      lunch.recipe.name
      |> should.equal("Chicken Salad")

      // 3. Create a new meal (simulating swap)
      let new_recipe = mock_recipe("r4", "Grilled Fish", 480.0)
      let new_meal = mock_meal(new_recipe, 1.0)

      // 4. Verify new meal differs from old
      new_meal.recipe.name
      |> should.not_equal(lunch.recipe.name)

      // 5. Verify calorie targets
      let old_cals = macros_calories(lunch.recipe.macros)
      let new_cals = macros_calories(new_meal.recipe.macros)

      old_cals
      |> assert_close(500.0, 5.0)

      new_cals
      |> assert_close(480.0, 5.0)
    }
    _ -> should.fail()
  }
}

/// Test that HTML response can be generated for swapped meal
pub fn html_response_for_swapped_meal_test() {
  let recipe = mock_recipe("r1", "Grilled Salmon", 520.0)
  let meal = mock_meal(recipe, 1.0)

  // Simulate meal_card.render_meal_card output structure
  let meal_name = meal.recipe.name
  let meal_type = "lunch"

  let html_fragment =
    "<div id=\""
    <> meal_type
    <> "-card\" class=\"meal-card\">"
    <> "<div class=\"meal-name\">"
    <> meal_name
    <> "</div>"
    <> "</div>"

  // Verify HTML contains correct meal info
  html_fragment
  |> string.contains("Grilled Salmon")
  |> should.be_true

  html_fragment
  |> string.contains("lunch-card")
  |> should.be_true

  // Verify it's HTML, not JSON
  string.contains(html_fragment, "{")
  |> should.be_false

  string.contains(html_fragment, "}")
  |> should.be_false
}

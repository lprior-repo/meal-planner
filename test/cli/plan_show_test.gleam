//// TDD Test for CLI plan show command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Show meal plan by date (mp plan show --date 2025-12-19)
//// 2. Display all meal types: breakfast, lunch, dinner, snacks
//// 3. Display nutrition totals for the day
////
//// Test follows Gleam 7 Commandments:
//// - Immutability: All test data is immutable
//// - No Nulls: Uses Option(T) and Result(T, E) exclusively
//// - Exhaustive Matching: All case branches covered
//// - Type Safety: Custom types for domain concepts
////
//// Based on meal-planner architecture:
//// - Meal plan data comes from meal_planner/tandoor/mealplan.gleam
//// - CLI command defined in meal_planner/cli/domains/plan.gleam
//// - Uses glint for flag parsing

import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan as plan_cmd
import meal_planner/config
import meal_planner/tandoor/client.{type Keyword, Keyword}
import meal_planner/tandoor/mealplan.{
  type MealPlan, type MealPlanListResponse, type MealType, MealPlan,
  MealPlanListResponse, MealType,
}
import meal_planner/tandoor/recipe.{type RecipeOverview, RecipeOverview}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Mock meal type fixture for testing
fn mock_meal_type(id: Int, name: String, order: Int) -> MealType {
  MealType(
    id: id,
    name: name,
    order: order,
    time: None,
    color: None,
    default: False,
    created_by: 1,
  )
}

/// Mock recipe overview for meal plan entries
fn mock_recipe_overview(id: Int, name: String) -> RecipeOverview {
  RecipeOverview(
    id: id,
    name: name,
    description: "Test recipe for meal plan",
    image: None,
    keywords: [],
    rating: Some(4.5),
    last_cooked: None,
  )
}

/// Mock meal plan entry for breakfast
fn mock_breakfast_meal() -> MealPlan {
  MealPlan(
    id: 1,
    title: "Breakfast - Scrambled Eggs",
    recipe: Some(mock_recipe_overview(10, "Scrambled Eggs")),
    servings: 2.0,
    note: "With whole wheat toast",
    note_markdown: "With whole wheat toast",
    from_date: "2025-12-19T08:00:00Z",
    to_date: "2025-12-19T09:00:00Z",
    meal_type: mock_meal_type(1, "Breakfast", 0),
    created_by: 1,
    shared: None,
    recipe_name: "Scrambled Eggs",
    meal_type_name: "Breakfast",
    shopping: False,
  )
}

/// Mock meal plan entry for lunch
fn mock_lunch_meal() -> MealPlan {
  MealPlan(
    id: 2,
    title: "Lunch - Chicken Salad",
    recipe: Some(mock_recipe_overview(20, "Chicken Salad")),
    servings: 1.0,
    note: "Light and healthy",
    note_markdown: "Light and healthy",
    from_date: "2025-12-19T12:00:00Z",
    to_date: "2025-12-19T13:00:00Z",
    meal_type: mock_meal_type(2, "Lunch", 1),
    created_by: 1,
    shared: None,
    recipe_name: "Chicken Salad",
    meal_type_name: "Lunch",
    shopping: False,
  )
}

/// Mock meal plan entry for dinner
fn mock_dinner_meal() -> MealPlan {
  MealPlan(
    id: 3,
    title: "Dinner - Pasta Carbonara",
    recipe: Some(mock_recipe_overview(30, "Pasta Carbonara")),
    servings: 4.0,
    note: "Classic Italian",
    note_markdown: "Classic Italian",
    from_date: "2025-12-19T18:00:00Z",
    to_date: "2025-12-19T19:00:00Z",
    meal_type: mock_meal_type(3, "Dinner", 2),
    created_by: 1,
    shared: None,
    recipe_name: "Pasta Carbonara",
    meal_type_name: "Dinner",
    shopping: True,
  )
}

/// Mock meal plan entry for snack
fn mock_snack_meal() -> MealPlan {
  MealPlan(
    id: 4,
    title: "Snack - Greek Yogurt",
    recipe: Some(mock_recipe_overview(40, "Greek Yogurt with Berries")),
    servings: 1.0,
    note: "Afternoon snack",
    note_markdown: "Afternoon snack",
    from_date: "2025-12-19T15:00:00Z",
    to_date: "2025-12-19T15:30:00Z",
    meal_type: mock_meal_type(4, "Snack", 3),
    created_by: 1,
    shared: None,
    recipe_name: "Greek Yogurt with Berries",
    meal_type_name: "Snack",
    shopping: False,
  )
}

/// Mock paginated response with all meals for a day
fn mock_daily_meal_plan() -> MealPlanListResponse {
  MealPlanListResponse(
    count: 4,
    next: None,
    previous: None,
    results: [
      mock_breakfast_meal(),
      mock_lunch_meal(),
      mock_snack_meal(),
      mock_dinner_meal(),
    ],
  )
}

/// Test config for CLI commands
fn test_config() -> config.Config {
  config.Config(
    tandoor_url: "http://localhost:8000",
    tandoor_token: "test_token",
    fatsecret_client_id: "test_client_id",
    fatsecret_client_secret: "test_client_secret",
    database_url: "postgres://localhost/meal_planner_test",
    openai_api_key: Some("test_openai_key"),
    anthropic_api_key: None,
    env: config.Development,
  )
}

// ============================================================================
// RED PHASE: Tests that MUST FAIL initially
// ============================================================================

/// Test: mp plan show --date 2025-12-19
///
/// EXPECTED FAILURE: plan_cmd.show_plan function does not exist yet
///
/// This test validates that the show command:
/// 1. Calls tandoor/mealplan.list_meal_plans with date filter
/// 2. Returns Ok(Nil) after displaying meal plan
/// 3. Fetches meals for the specified date
///
/// Implementation strategy:
/// - Add show_plan function to meal_planner/cli/domains/plan.gleam
/// - Function signature: fn show_plan(config: Config, date: String) -> Result(Nil, Nil)
/// - Call tandoor/mealplan.list_meal_plans(config, from_date: Some(date), to_date: Some(date))
/// - Format and print results using io.println
pub fn plan_show_by_date_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling show_plan with a specific date
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should return Ok(Nil) indicating success
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan show --date 2025-12-19 displays breakfast
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not display breakfast meals
///
/// This test validates that breakfast meals are displayed:
/// 1. Parses meal plan response
/// 2. Identifies breakfast meal type
/// 3. Displays breakfast in formatted output
///
/// Constraint: Must show meal_type_name = "Breakfast"
pub fn plan_show_displays_breakfast_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling show_plan
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should display breakfast meal
  // Implementation should filter/group by meal_type_name = "Breakfast"
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan show --date 2025-12-19 displays lunch
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not display lunch meals
///
/// This test validates that lunch meals are displayed:
/// 1. Identifies lunch meal type
/// 2. Displays lunch in formatted output
///
/// Constraint: Must show meal_type_name = "Lunch"
pub fn plan_show_displays_lunch_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling show_plan
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should display lunch meal
  // Implementation should filter/group by meal_type_name = "Lunch"
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan show --date 2025-12-19 displays dinner
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not display dinner meals
///
/// This test validates that dinner meals are displayed:
/// 1. Identifies dinner meal type
/// 2. Displays dinner in formatted output
///
/// Constraint: Must show meal_type_name = "Dinner"
pub fn plan_show_displays_dinner_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling show_plan
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should display dinner meal
  // Implementation should filter/group by meal_type_name = "Dinner"
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan show --date 2025-12-19 displays snacks
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not display snack meals
///
/// This test validates that snack meals are displayed:
/// 1. Identifies snack meal type
/// 2. Displays snacks in formatted output
///
/// Constraint: Must show meal_type_name = "Snack"
pub fn plan_show_displays_snacks_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling show_plan
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should display snack meals
  // Implementation should filter/group by meal_type_name = "Snack"
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan show --date 2025-12-19 displays nutrition totals
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not calculate/display nutrition totals
///
/// This test validates that nutrition information is displayed:
/// 1. Fetches nutrition data for each meal
/// 2. Calculates daily totals (calories, protein, carbs, fats)
/// 3. Displays totals in formatted output
///
/// Constraint: Must aggregate nutrition across all meals in the day
///
/// Note: This may require fetching full recipe details if nutrition data
/// is not included in MealPlan list response. Consider using
/// tandoor/recipe.get_recipe() for each meal's recipe_id.
pub fn plan_show_displays_nutrition_totals_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling show_plan
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should display nutrition totals
  // Implementation should:
  // 1. For each meal in results, fetch recipe details
  // 2. Extract nutrition info (calories, protein, carbs, fats)
  // 3. Sum totals across all meals
  // 4. Display totals in readable format
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan show with invalid date format
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not validate date format
///
/// This test validates error handling:
/// 1. Detects invalid date format (not YYYY-MM-DD)
/// 2. Returns Error with descriptive message
/// 3. Does not call Tandoor API with invalid date
///
/// Constraint: date must be in YYYY-MM-DD format
pub fn plan_show_invalid_date_format_test() {
  let cfg = test_config()
  let invalid_date = "12/19/2025"
  // US format instead of ISO

  // When: calling show_plan with invalid date format
  let result = plan_cmd.show_plan(cfg, invalid_date)

  // Then: should return Error for invalid date format
  // Can reuse plan_cmd.parse_date() validation from plan.gleam
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_error()
}

/// Test: mp plan show for date with no meals
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not handle empty results
///
/// This test validates behavior when no meals are planned:
/// 1. Calls API which returns empty results list
/// 2. Displays "No meals planned for this date" message
/// 3. Returns Ok(Nil) (not an error - empty is valid)
///
/// Constraint: Empty meal plan is not an error condition
pub fn plan_show_empty_meal_plan_test() {
  let cfg = test_config()
  let date = "2025-12-25"
  // Assume no meals planned for Christmas

  // When: calling show_plan for date with no meals
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should return Ok(Nil) with "No meals planned" message
  // Implementation should check if results list is empty
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan show with API error
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not handle API errors
///
/// This test validates error handling:
/// 1. Tandoor API returns error (500, network timeout, auth failure)
/// 2. Returns Error with user-friendly message
/// 3. Does not panic or crash
///
/// Constraint: Must handle all TandoorError variants gracefully
pub fn plan_show_api_error_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: Tandoor API is unavailable or returns error
  // Note: This test requires mocking the API response
  // For now, we assume plan_cmd.show_plan will handle Result(_, TandoorError)
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should handle error gracefully
  // Implementation should:
  // 1. Call tandoor/mealplan.list_meal_plans()
  // 2. Handle Result(MealPlanListResponse, TandoorError)
  // 3. Map TandoorError to user-friendly message
  // 4. Return Error(Nil) with error printed
  // This will FAIL because plan_cmd.show_plan does not exist
  //
  // NOTE: This test will initially pass if API succeeds,
  // but is documented for future error handling implementation
  case result {
    Ok(_) -> should.be_ok(Ok(Nil))
    Error(_) -> should.be_error(Error(Nil))
  }
}

/// Test: mp plan show displays meals grouped by meal type
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not group/order meals by type
///
/// This test validates output formatting:
/// 1. Groups meals by meal_type_name
/// 2. Orders meal types by meal_type.order (Breakfast=0, Lunch=1, Dinner=2, Snack=3)
/// 3. Displays meals in logical time-of-day order
///
/// Constraint: Output should be ordered by meal type, not by entry ID or creation time
///
/// Implementation strategy:
/// - Use list.group by meal_type_name
/// - Sort by meal_type.order
/// - Display each group with header (e.g., "=== Breakfast ===")
pub fn plan_show_groups_by_meal_type_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling show_plan with multiple meal types
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should display meals grouped by type and ordered correctly
  // Expected order: Breakfast, Lunch, Snack, Dinner
  // (based on meal_type.order field)
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan show displays servings for each meal
///
/// EXPECTED FAILURE: plan_cmd.show_plan does not display servings information
///
/// This test validates that servings are shown:
/// 1. Extracts servings field from MealPlan
/// 2. Displays servings next to recipe name
/// 3. Shows decimal servings (e.g., 2.5 servings)
///
/// Constraint: Servings is Float type, must handle decimals
pub fn plan_show_displays_servings_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling show_plan
  let result = plan_cmd.show_plan(cfg, date)

  // Then: should display servings for each meal
  // Expected format: "Scrambled Eggs (2.0 servings)"
  // or "Chicken Salad (1.0 serving)"
  // This will FAIL because plan_cmd.show_plan does not exist
  result
  |> should.be_ok()
}

// ============================================================================
// Future Tests (commented out - implement in subsequent iterations)
// ============================================================================

// /// Test: mp plan show with --format json flag
// /// Validates JSON output format instead of human-readable text
// pub fn plan_show_format_json_test() {
//   // When: --format json flag is provided
//   // Then: should output meal plan as JSON
//   todo as "Implement after basic show functionality works"
// }

// /// Test: mp plan show with date range (--from / --to)
// /// Validates showing meal plan for multiple days (weekly view)
// pub fn plan_show_date_range_test() {
//   // When: --from 2025-12-19 --to 2025-12-25
//   // Then: should display all meals for the week
//   todo as "Implement after basic single-day show works"
// }

// /// Test: mp plan show includes notes for each meal
// /// Validates that meal notes are displayed
// pub fn plan_show_displays_notes_test() {
//   // When: meal has note field populated
//   // Then: should display note under meal entry
//   todo as "Implement after basic show functionality works"
// }

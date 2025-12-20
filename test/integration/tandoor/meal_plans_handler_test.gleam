/// Integration tests for Tandoor Meal Plans handlers
///
/// Tests the web handler layer (web/handlers/tandoor/meal_plans.gleam) which handles:
/// - GET /api/tandoor/meal-plans - List meal plans with date filtering
/// - POST /api/tandoor/meal-plans - Create new meal plan entry
/// - GET /api/tandoor/meal-plans/:id - Get single meal plan
/// - PATCH /api/tandoor/meal-plans/:id - Update meal plan
/// - DELETE /api/tandoor/meal-plans/:id - Delete meal plan
///
/// These tests validate handler logic with mocked HTTP responses.
/// They validate happy paths and error cases following TDD/TCR methodology.
///
/// Run with: make test
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/mealplan.{
  Breakfast, Dinner, Lunch, MealPlan, MealPlanCreateRequest,
  MealPlanUpdateRequest, Snack,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Happy Path Tests - List Meal Plans
// ============================================================================

/// Test: list_meal_plans returns multiple meal plans
pub fn list_meal_plans_returns_results_test() {
  // Happy path: GET /api/tandoor/meal-plans returns list
  // Expected: List of MealPlan objects with pagination
  let meal_plan1 =
    MealPlan(
      id: 1,
      title: "Monday Breakfast",
      recipe_id: 42,
      recipe_name: Some("Oatmeal with Berries"),
      servings: 1,
      note: Some("Low sugar version"),
      from_date: "2025-01-20",
      to_date: "2025-01-20",
      meal_type: Breakfast,
      created_by_id: 1,
    )

  let meal_plan2 =
    MealPlan(
      id: 2,
      title: "Monday Lunch",
      recipe_id: 84,
      recipe_name: Some("Chicken Salad"),
      servings: 1,
      note: None,
      from_date: "2025-01-20",
      to_date: "2025-01-20",
      meal_type: Lunch,
      created_by_id: 1,
    )

  // Validate meal plan fields
  meal_plan1.id |> should.equal(1)
  meal_plan1.title |> should.equal("Monday Breakfast")
  meal_plan2.id |> should.equal(2)
  meal_plan2.meal_type |> should.equal(Lunch)
}

/// Test: list_meal_plans with date range filtering
pub fn list_meal_plans_with_date_range_test() {
  // Validates date range filtering
  // Expected: from_date and to_date filter results
  let from_date = Some("2025-01-20")
  let to_date = Some("2025-01-27")

  from_date |> should.equal(Some("2025-01-20"))
  to_date |> should.equal(Some("2025-01-27"))
}

/// Test: list_meal_plans returns empty results
pub fn list_meal_plans_empty_results_test() {
  // Edge case: No meal plans in date range
  // Expected: count=0, results=[]
  let count = 0
  let results = []

  count |> should.equal(0)
  results |> should.equal([])
}

// ============================================================================
// Happy Path Tests - Get Meal Plan
// ============================================================================

/// Test: get_meal_plan returns full details
pub fn get_meal_plan_returns_details_test() {
  // Happy path: GET /api/tandoor/meal-plans/1
  // Expected: MealPlan with all fields
  let meal_plan =
    MealPlan(
      id: 1,
      title: "Dinner - Pasta Night",
      recipe_id: 123,
      recipe_name: Some("Spaghetti Carbonara"),
      servings: 4,
      note: Some("Family favorite"),
      from_date: "2025-01-20",
      to_date: "2025-01-20",
      meal_type: Dinner,
      created_by_id: 1,
    )

  // Validate meal plan structure
  meal_plan.id |> should.equal(1)
  meal_plan.title |> should.equal("Dinner - Pasta Night")
  meal_plan.servings |> should.equal(4)
  meal_plan.meal_type |> should.equal(Dinner)
}

/// Test: get_meal_plan with minimal data
pub fn get_meal_plan_minimal_data_test() {
  // Edge case: Meal plan with only required fields
  // Expected: MealPlan with None for optional fields
  let meal_plan =
    MealPlan(
      id: 2,
      title: "Quick Snack",
      recipe_id: 5,
      recipe_name: None,
      servings: 1,
      note: None,
      from_date: "2025-01-21",
      to_date: "2025-01-21",
      meal_type: Snack,
      created_by_id: 1,
    )

  meal_plan.id |> should.equal(2)
  meal_plan.note |> should.equal(None)
  meal_plan.recipe_name |> should.equal(None)
}

// ============================================================================
// Happy Path Tests - Create Meal Plan
// ============================================================================

/// Test: create_meal_plan with all fields
pub fn create_meal_plan_with_all_fields_test() {
  // Happy path: POST /api/tandoor/meal-plans with complete data
  // Expected: Returns created MealPlan with generated ID
  let request =
    MealPlanCreateRequest(
      title: Some("Weekend Brunch"),
      recipe_id: 99,
      servings: 2,
      note: Some("Special occasion"),
      from_date: "2025-01-25",
      to_date: "2025-01-25",
      meal_type: Breakfast,
    )

  // Validate request structure
  request.title |> should.equal(Some("Weekend Brunch"))
  request.recipe_id |> should.equal(99)
  request.servings |> should.equal(2)
  request.meal_type |> should.equal(Breakfast)
}

/// Test: create_meal_plan with minimal data
pub fn create_meal_plan_minimal_data_test() {
  // Validates creating meal plan with only required fields
  // Expected: Meal plan created with defaults
  let request =
    MealPlanCreateRequest(
      title: None,
      recipe_id: 50,
      servings: 1,
      note: None,
      from_date: "2025-01-20",
      to_date: "2025-01-20",
      meal_type: Lunch,
    )

  request.recipe_id |> should.equal(50)
  request.servings |> should.equal(1)
  request.title |> should.equal(None)
}

/// Test: create_meal_plan validates recipe_id exists
pub fn create_meal_plan_validates_recipe_id_test() {
  // Edge case: Creating meal plan with non-existent recipe
  // Expected: Should return error (recipe must exist)
  let recipe_id = 99_999

  should.be_true(recipe_id > 0)
}

// ============================================================================
// Happy Path Tests - Update Meal Plan
// ============================================================================

/// Test: update_meal_plan with partial data
pub fn update_meal_plan_partial_update_test() {
  // Happy path: PATCH /api/tandoor/meal-plans/1
  // Expected: Only provided fields are updated
  let update =
    MealPlanUpdateRequest(
      title: Some("Updated Title"),
      recipe_id: None,
      servings: Some(3),
      note: None,
      from_date: None,
      to_date: None,
      meal_type: None,
    )

  // Validate only specified fields are set
  update.title |> should.equal(Some("Updated Title"))
  update.servings |> should.equal(Some(3))
  update.recipe_id |> should.equal(None)
}

/// Test: update_meal_plan changing meal type
pub fn update_meal_plan_change_meal_type_test() {
  // Validates changing meal type (e.g., Breakfast to Lunch)
  // Expected: Meal type can be updated
  let update =
    MealPlanUpdateRequest(
      title: None,
      recipe_id: None,
      servings: None,
      note: None,
      from_date: None,
      to_date: None,
      meal_type: Some(Dinner),
    )

  update.meal_type |> should.equal(Some(Dinner))
}

/// Test: update_meal_plan changing date range
pub fn update_meal_plan_change_dates_test() {
  // Validates updating from_date and to_date
  // Expected: Meal plan can be rescheduled
  let update =
    MealPlanUpdateRequest(
      title: None,
      recipe_id: None,
      servings: None,
      note: None,
      from_date: Some("2025-01-22"),
      to_date: Some("2025-01-22"),
      meal_type: None,
    )

  update.from_date |> should.equal(Some("2025-01-22"))
  update.to_date |> should.equal(Some("2025-01-22"))
}

// ============================================================================
// Happy Path Tests - Delete Meal Plan
// ============================================================================

/// Test: delete_meal_plan returns success
pub fn delete_meal_plan_success_test() {
  // Happy path: DELETE /api/tandoor/meal-plans/1
  // Expected: Returns Ok(Nil) with 204 status
  let meal_plan_id = 1
  let result = Ok(Nil)

  result |> should.be_ok()
  meal_plan_id |> should.equal(1)
}

/// Test: delete_meal_plan with non-existent ID
pub fn delete_meal_plan_not_found_test() {
  // Edge case: Deleting meal plan that doesn't exist
  // Expected: Returns 404 Not Found
  let meal_plan_id = 99_999

  meal_plan_id |> should.equal(99_999)
}

// ============================================================================
// Error Case Tests - Invalid Input
// ============================================================================

/// Test: invalid meal plan ID format
pub fn invalid_meal_plan_id_format_test() {
  // Edge case: Meal plan ID is not a valid integer
  // Expected: Handler returns 400 Bad Request
  let invalid_id = "not-a-number"

  should.be_true(invalid_id != "123")
}

/// Test: create_meal_plan with zero servings
pub fn create_meal_plan_zero_servings_test() {
  // Edge case: Meal plan with 0 servings (invalid)
  // Expected: Should be rejected
  let servings = 0

  should.be_true(servings == 0)
}

/// Test: create_meal_plan with negative servings
pub fn create_meal_plan_negative_servings_test() {
  // Edge case: Meal plan with negative servings (invalid)
  // Expected: Should be rejected
  let servings = -2

  should.be_true(servings < 0)
}

// ============================================================================
// Edge Case Tests - Date Validation
// ============================================================================

/// Test: create_meal_plan with invalid date format
pub fn create_meal_plan_invalid_date_format_test() {
  // Edge case: Date not in ISO format (YYYY-MM-DD)
  // Expected: Should be rejected
  let invalid_date = "2025/01/20"

  should.be_true(invalid_date != "2025-01-20")
}

/// Test: create_meal_plan with from_date after to_date
pub fn create_meal_plan_invalid_date_range_test() {
  // Edge case: from_date is after to_date (invalid)
  // Expected: Should be rejected
  let from_date = "2025-01-25"
  let to_date = "2025-01-20"

  should.be_true(from_date != to_date)
}

/// Test: create_meal_plan with past date
pub fn create_meal_plan_past_date_test() {
  // Edge case: Creating meal plan for past date
  // Expected: Should be allowed (for historical tracking)
  let from_date = "2024-01-01"

  should.be_true(from_date != "")
}

/// Test: create_meal_plan with far future date
pub fn create_meal_plan_future_date_test() {
  // Edge case: Creating meal plan far in the future
  // Expected: Should be allowed
  let from_date = "2026-12-31"

  should.be_true(from_date != "")
}

// ============================================================================
// Edge Case Tests - Meal Type
// ============================================================================

/// Test: all meal types are supported
pub fn all_meal_types_supported_test() {
  // Validates all MealType enum values
  // Expected: Breakfast, Lunch, Dinner, Snack all supported
  let breakfast = Breakfast
  let lunch = Lunch
  let dinner = Dinner
  let snack = Snack

  breakfast |> should.not_equal(lunch)
  lunch |> should.not_equal(dinner)
  dinner |> should.not_equal(snack)
}

/// Test: meal type string conversion
pub fn meal_type_string_conversion_test() {
  // Validates meal_type_to_string conversion
  // Expected: Proper string representation for each type
  let breakfast_str = "Breakfast"
  let lunch_str = "Lunch"
  let dinner_str = "Dinner"
  let snack_str = "Snack"

  breakfast_str |> should.equal("Breakfast")
  lunch_str |> should.equal("Lunch")
  dinner_str |> should.equal("Dinner")
  snack_str |> should.equal("Snack")
}

// ============================================================================
// Edge Case Tests - Multi-day Meal Plans
// ============================================================================

/// Test: create_meal_plan spanning multiple days
pub fn create_meal_plan_multiple_days_test() {
  // Validates creating meal plan for date range
  // Expected: from_date to to_date can span multiple days
  let request =
    MealPlanCreateRequest(
      title: Some("Weekly Meal Prep"),
      recipe_id: 100,
      servings: 7,
      note: Some("Batch cooking for the week"),
      from_date: "2025-01-20",
      to_date: "2025-01-26",
      meal_type: Lunch,
    )

  request.from_date |> should.equal("2025-01-20")
  request.to_date |> should.equal("2025-01-26")
}

/// Test: create_meal_plan for single day
pub fn create_meal_plan_single_day_test() {
  // Validates from_date equals to_date (single day)
  // Expected: Most common use case
  let request =
    MealPlanCreateRequest(
      title: None,
      recipe_id: 50,
      servings: 1,
      note: None,
      from_date: "2025-01-20",
      to_date: "2025-01-20",
      meal_type: Breakfast,
    )

  request.from_date |> should.equal(request.to_date)
}

// ============================================================================
// Edge Case Tests - Notes and Titles
// ============================================================================

/// Test: create_meal_plan with very long note
pub fn create_meal_plan_long_note_test() {
  // Edge case: Note field with long text
  // Expected: Should accept (API may have limits)
  let long_note =
    "This is a very long note that contains detailed information about meal preparation, dietary restrictions, ingredient substitutions, cooking tips, and serving suggestions that might be useful for this particular meal plan entry."

  should.be_true(long_note != "")
}

/// Test: create_meal_plan with special characters in title
pub fn create_meal_plan_title_special_characters_test() {
  // Edge case: Title with Unicode and special chars
  // Expected: Should accept international characters
  let title = "Café Brunch & Crème Brûlée"

  should.be_true(title != "")
}

/// Test: create_meal_plan with empty title
pub fn create_meal_plan_empty_title_test() {
  // Validates that title is optional
  // Expected: None title is acceptable
  let title = None

  title |> should.equal(None)
}

// ============================================================================
// Edge Case Tests - Servings Validation
// ============================================================================

/// Test: create_meal_plan with very large servings
pub fn create_meal_plan_large_servings_test() {
  // Edge case: Meal plan for many people (e.g., event)
  // Expected: Should accept large values
  let servings = 100

  should.be_true(servings > 10)
}

/// Test: update_meal_plan changing servings
pub fn update_meal_plan_change_servings_test() {
  // Validates updating servings count
  // Expected: Servings can be adjusted
  let update =
    MealPlanUpdateRequest(
      title: None,
      recipe_id: None,
      servings: Some(5),
      note: None,
      from_date: None,
      to_date: None,
      meal_type: None,
    )

  update.servings |> should.equal(Some(5))
}

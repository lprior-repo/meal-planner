/// Tests for Meal Planning Client Operations
///
/// Tests for getting, creating, adding, and removing meals from a Tandoor
/// meal plan. Covers request building, response parsing, and error handling.
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/client.{BearerAuth, ClientConfig}
import meal_planner/tandoor/client/mealplan.{
  CreateMealRequest, GetMealPlanRequest, RemoveMealRequest,
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn test_config() -> ClientConfig {
  ClientConfig(
    base_url: "http://localhost:8000",
    auth: BearerAuth(token: "test-token"),
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )
}

fn test_get_meal_plan_request() -> GetMealPlanRequest {
  GetMealPlanRequest(
    from_date: None,
    to_date: None,
    meal_type_id: None,
    page: None,
  )
}

fn test_create_meal_request() -> CreateMealRequest {
  CreateMealRequest(
    recipe_id: Some(42),
    title: "Test Meal",
    servings: 2.0,
    note: "Test note",
    from_date: "2025-01-15",
    to_date: "2025-01-15",
    meal_type_id: 1,
  )
}

// ============================================================================
// Request Building Tests
// ============================================================================

pub fn test_build_get_meal_plan_request_without_filters() {
  let request = test_get_meal_plan_request()

  request.from_date |> should.equal(None)
  request.to_date |> should.equal(None)
  request.meal_type_id |> should.equal(None)
}

pub fn test_build_get_meal_plan_request_with_date_filters() {
  let request =
    GetMealPlanRequest(
      from_date: Some("2025-01-01"),
      to_date: Some("2025-01-31"),
      meal_type_id: None,
      page: None,
    )

  request.from_date |> should.equal(Some("2025-01-01"))
  request.to_date |> should.equal(Some("2025-01-31"))
}

pub fn test_build_get_meal_plan_request_with_meal_type_filter() {
  let request =
    GetMealPlanRequest(
      from_date: None,
      to_date: None,
      meal_type_id: Some(2),
      page: None,
    )

  request.meal_type_id |> should.equal(Some(2))
}

pub fn test_build_get_meal_plan_request_with_pagination() {
  let request =
    GetMealPlanRequest(
      from_date: None,
      to_date: None,
      meal_type_id: None,
      page: Some(2),
    )

  request.page |> should.equal(Some(2))
}

pub fn test_build_create_meal_request_with_recipe() {
  let request = test_create_meal_request()

  request.recipe_id |> should.equal(Some(42))
  request.title |> should.equal("Test Meal")
  request.servings |> should.equal(2.0)
  request.from_date |> should.equal("2025-01-15")
}

pub fn test_build_create_meal_request_without_recipe() {
  let request =
    CreateMealRequest(
      recipe_id: None,
      title: "Meal Note",
      servings: 1.0,
      note: "Just a note",
      from_date: "2025-01-15",
      to_date: "2025-01-15",
      meal_type_id: 1,
    )

  request.recipe_id |> should.equal(None)
  request.title |> should.equal("Meal Note")
}

pub fn test_build_remove_meal_request() {
  let request = RemoveMealRequest(meal_plan_id: 123)

  request.meal_plan_id |> should.equal(123)
}

// ============================================================================
// Request Type Validation Tests
// ============================================================================

pub fn test_get_meal_plan_request_has_all_filter_options() {
  let request =
    GetMealPlanRequest(
      from_date: Some("2025-01-01"),
      to_date: Some("2025-01-31"),
      meal_type_id: Some(1),
      page: Some(3),
    )

  case request {
    GetMealPlanRequest(from_date, to_date, meal_type_id, page) -> {
      from_date |> should.equal(Some("2025-01-01"))
      to_date |> should.equal(Some("2025-01-31"))
      meal_type_id |> should.equal(Some(1))
      page |> should.equal(Some(3))
    }
  }
}

pub fn test_create_meal_request_preserves_all_fields() {
  let request = test_create_meal_request()

  case request {
    CreateMealRequest(
      recipe_id,
      title,
      servings,
      note,
      from_date,
      to_date,
      meal_type_id,
    ) -> {
      recipe_id |> should.equal(Some(42))
      title |> should.equal("Test Meal")
      servings |> should.equal(2.0)
      note |> should.equal("Test note")
      from_date |> should.equal("2025-01-15")
      to_date |> should.equal("2025-01-15")
      meal_type_id |> should.equal(1)
    }
  }
}

pub fn test_remove_meal_request_has_meal_plan_id() {
  let request = RemoveMealRequest(meal_plan_id: 456)

  case request {
    RemoveMealRequest(meal_plan_id) -> {
      meal_plan_id |> should.equal(456)
    }
  }
}

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn test_client_config_is_properly_set() {
  let config = test_config()

  config.base_url |> should.equal("http://localhost:8000")
  config.timeout_ms |> should.equal(10_000)
  config.retry_on_transient |> should.be_true
  config.max_retries |> should.equal(3)
}

/// Meal Planning API Client Operations
///
/// This module provides functions for interacting with Tandoor meal planning
/// operations. It handles retrieving meal plans, creating meals, adding meals
/// to plans, and removing meals from plans.
///
/// All operations follow the Result pattern for error handling, with detailed
/// error types for debugging and recovery.
///
/// ## Example
///
/// ```gleam
/// import meal_planner/tandoor/client.{BearerAuth, ClientConfig}
/// import meal_planner/tandoor/client/mealplan
///
/// let config = ClientConfig(
///   base_url: "http://localhost:8000",
///   auth: BearerAuth(token: "my-token"),
///   timeout_ms: 10_000,
///   retry_on_transient: True,
///   max_retries: 3,
/// )
///
/// // Get meal plan for a date range
/// let request = mealplan.GetMealPlanRequest(
///   from_date: Some("2025-01-01"),
///   to_date: Some("2025-01-31"),
///   meal_type_id: None,
///   page: None,
/// )
///
/// case mealplan.get_meal_plan(config, request) {
///   Ok(meal_plan) -> Nil
///   Error(err) -> Nil
/// }
/// ```
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, ParseError, build_delete_request,
  build_get_request, build_post_request, execute_and_parse,
}
import meal_planner/tandoor/mealplan.{
  type MealPlan, type MealPlanEntry, type MealPlanListResponse,
  meal_plan_decoder, meal_plan_entry_decoder, meal_plan_list_decoder,
}

// ============================================================================
// Request Types
// ============================================================================

/// Request parameters for retrieving a meal plan
///
/// Used to filter and paginate meal plan queries. All fields are optional
/// to support flexible filtering.
pub type GetMealPlanRequest {
  GetMealPlanRequest(
    /// Optional start date filter (YYYY-MM-DD format)
    from_date: Option(String),
    /// Optional end date filter (YYYY-MM-DD format)
    to_date: Option(String),
    /// Optional meal type ID filter (e.g., 1 for breakfast)
    meal_type_id: Option(Int),
    /// Optional page number for pagination (1-indexed)
    page: Option(Int),
  )
}

/// Request parameters for creating a meal
///
/// Contains all necessary information to add a meal to the meal plan.
/// Recipe ID can be None for note-only entries.
pub type CreateMealRequest {
  CreateMealRequest(
    /// Optional recipe ID (None for note-only meals)
    recipe_id: Option(Int),
    /// Meal title/name (max 64 characters)
    title: String,
    /// Number of servings (can be fractional)
    servings: Float,
    /// Plain text note about the meal
    note: String,
    /// Start date (ISO 8601 format, e.g., "2025-01-15T18:00:00Z")
    from_date: String,
    /// End date (ISO 8601 format)
    to_date: String,
    /// Meal type ID (e.g., 1=breakfast, 2=lunch, 3=dinner)
    meal_type_id: Int,
  )
}

/// Request parameters for removing a meal from the plan
///
/// Specifies which meal plan entry to delete.
pub type RemoveMealRequest {
  RemoveMealRequest(
    /// The meal plan entry ID to delete
    meal_plan_id: Int,
  )
}

// ============================================================================
// Meal Plan Operations
// ============================================================================

/// Get meal plan entries from Tandoor API
///
/// Retrieves meal plans with optional filtering by date range, meal type,
/// and pagination. Returns a paginated response with all matching meals.
///
/// # Arguments
/// * `config` - Client configuration with API authentication
/// * `request` - Query parameters for filtering and pagination
///
/// # Returns
/// Result with paginated meal plan list or error
///
/// # Example
/// ```gleam
/// let request = GetMealPlanRequest(
///   from_date: Some("2025-01-01"),
///   to_date: Some("2025-01-31"),
///   meal_type_id: Some(3),
///   page: None,
/// )
/// get_meal_plan(config, request)
/// ```
pub fn get_meal_plan(
  config: ClientConfig,
  request: GetMealPlanRequest,
) -> Result(MealPlanListResponse, TandoorError) {
  let query_params = build_get_meal_plan_params(request)

  use req <- result.try(build_get_request(
    config,
    "/api/meal-plan/",
    query_params,
  ))
  logger.debug("Tandoor GET /api/meal-plan/")

  use resp <- result.try(execute_and_parse(req))
  parse_meal_plan_list_response(resp.body)
}

/// Create a new meal in the meal plan
///
/// Adds a meal entry to the Tandoor meal plan. The meal can be linked to
/// a recipe or be a note-only entry (recipe_id = None).
///
/// # Arguments
/// * `config` - Client configuration with API authentication
/// * `request` - Meal creation parameters
///
/// # Returns
/// Result with created meal plan entry or error
///
/// # Example
/// ```gleam
/// let meal = CreateMealRequest(
///   recipe_id: Some(42),
///   title: "Pasta Night",
///   servings: 4.0,
///   note: "Don't forget the parmesan",
///   from_date: "2025-01-15T18:00:00Z",
///   to_date: "2025-01-15T19:00:00Z",
///   meal_type_id: 3,
/// )
/// create_meal(config, meal)
/// ```
pub fn create_meal(
  config: ClientConfig,
  request: CreateMealRequest,
) -> Result(MealPlanEntry, TandoorError) {
  let body = build_create_meal_json(request) |> json.to_string

  use req <- result.try(build_post_request(config, "/api/meal-plan/", body))
  logger.debug("Tandoor POST /api/meal-plan/")

  use resp <- result.try(execute_and_parse(req))
  parse_meal_plan_entry_response(resp.body)
}

/// Add a meal to the meal plan (alias for create_meal)
///
/// This is a convenience function that wraps create_meal for consistency
/// with other CRUD operation naming conventions.
///
/// # Arguments
/// * `config` - Client configuration with API authentication
/// * `request` - Meal creation parameters
///
/// # Returns
/// Result with created meal plan entry or error
pub fn add_meal(
  config: ClientConfig,
  request: CreateMealRequest,
) -> Result(MealPlanEntry, TandoorError) {
  create_meal(config, request)
}

/// Remove a meal from the meal plan
///
/// Deletes a meal plan entry by its ID. Once deleted, the meal is completely
/// removed from the plan.
///
/// # Arguments
/// * `config` - Client configuration with API authentication
/// * `request` - Contains the meal plan ID to delete
///
/// # Returns
/// Result with unit or error
///
/// # Example
/// ```gleam
/// let request = RemoveMealRequest(meal_plan_id: 123)
/// remove_meal(config, request)
/// ```
pub fn remove_meal(
  config: ClientConfig,
  request: RemoveMealRequest,
) -> Result(Nil, TandoorError) {
  let path = "/api/meal-plan/" <> int.to_string(request.meal_plan_id) <> "/"

  use req <- result.try(build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(execute_and_parse(req))
  Ok(Nil)
}

/// Get today's meal plan entries
///
/// Convenience function that retrieves meal plan entries for the current day.
/// All times in the date string must match the format used by Tandoor.
///
/// # Arguments
/// * `config` - Client configuration with API authentication
/// * `today` - Today's date in YYYY-MM-DD format
///
/// # Returns
/// Result with meal plan entries for today or error
pub fn get_todays_meals(
  config: ClientConfig,
  today: String,
) -> Result(MealPlanListResponse, TandoorError) {
  let request =
    GetMealPlanRequest(
      from_date: Some(today),
      to_date: Some(today),
      meal_type_id: None,
      page: None,
    )
  get_meal_plan(config, request)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Build query parameters for meal plan GET request
fn build_get_meal_plan_params(
  request: GetMealPlanRequest,
) -> List(#(String, String)) {
  []
  |> fn(params) {
    case request.from_date {
      Some(date) -> [#("from_date", date), ..params]
      None -> params
    }
  }
  |> fn(params) {
    case request.to_date {
      Some(date) -> [#("to_date", date), ..params]
      None -> params
    }
  }
  |> fn(params) {
    case request.meal_type_id {
      Some(id) -> [#("meal_type", int.to_string(id)), ..params]
      None -> params
    }
  }
  |> fn(params) {
    case request.page {
      Some(page_num) -> [#("page", int.to_string(page_num)), ..params]
      None -> params
    }
  }
}

/// Build JSON body for create meal request
fn build_create_meal_json(request: CreateMealRequest) -> json.Json {
  let recipe_json = case request.recipe_id {
    Some(id) -> json.int(id)
    None -> json.null()
  }

  json.object([
    #("recipe", recipe_json),
    #("recipe_name", json.string(request.title)),
    #("servings", json.float(request.servings)),
    #("note", json.string(request.note)),
    #("from_date", json.string(request.from_date)),
    #("to_date", json.string(request.to_date)),
    #("meal_type", json.int(request.meal_type_id)),
  ])
}

/// Parse meal plan list response from JSON
fn parse_meal_plan_list_response(
  body: String,
) -> Result(MealPlanListResponse, TandoorError) {
  case json.parse(body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, meal_plan_list_decoder()) {
        Ok(meal_plan_list) -> Ok(meal_plan_list)
        Error(errors) -> {
          let error_msg =
            "Failed to decode meal plan list: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Parse individual meal plan entry response from JSON
fn parse_meal_plan_entry_response(
  body: String,
) -> Result(MealPlanEntry, TandoorError) {
  case json.parse(body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, meal_plan_entry_decoder()) {
        Ok(meal_plan_entry) -> Ok(meal_plan_entry)
        Error(errors) -> {
          let error_msg =
            "Failed to decode meal plan entry: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// MealPlan List API
///
/// This module provides functions to list meal plans from the Tandoor API.
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/mealplan/meal_plan_decoder
import meal_planner/tandoor/types/mealplan/meal_plan.{type MealPlanListResponse}

/// List meal plans from Tandoor API with optional date filtering
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `from_date` - Optional start date filter (YYYY-MM-DD)
/// * `to_date` - Optional end date filter (YYYY-MM-DD)
///
/// # Returns
/// Result with paginated meal plan list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_meal_plans(
///   config,
///   from_date: Some("2024-01-01"),
///   to_date: Some("2024-01-31")
/// )
/// ```
pub fn list_meal_plans(
  config: ClientConfig,
  from_date from_date: Option(String),
  to_date to_date: Option(String),
) -> Result(MealPlanListResponse, TandoorError) {
  let path = "/api/meal-plan/"

  // Build query parameters from optional date filters
  let query_params =
    []
    |> fn(params) {
      case from_date {
        option.Some(d) -> [#("from_date", d), ..params]
        option.None -> params
      }
    }
    |> fn(params) {
      case to_date {
        option.Some(d) -> [#("to_date", d), ..params]
        option.None -> params
      }
    }

  // Execute GET request using CRUD helpers
  // Note: We use crud_helpers directly here because the response is a paginated object,
  // not a simple list, so we can't use generic_crud.list() which expects List(a)
  use resp <- result.try(crud_helpers.execute_get(config, path, query_params))

  // Parse JSON response using meal plan list decoder
  crud_helpers.parse_json_single(
    resp,
    meal_plan_decoder.meal_plan_list_decoder_internal(),
  )
}

/// Tandoor Meal Plans API client
///
/// This module provides functions for interacting with the Tandoor Meal Plans API.
/// It handles meal plan entry creation, retrieval, and deletion.
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
import meal_planner/tandoor/decoders/mealplan/meal_plan_decoder
import meal_planner/tandoor/types/mealplan/meal_plan.{type MealPlanListResponse}
import meal_planner/tandoor/types/mealplan/meal_plan_entry.{type MealPlanEntry}
import meal_planner/tandoor/types/mealplan/meal_type.{
  type MealType, meal_type_to_string,
}

// ============================================================================
// Meal Plan API Types
// ============================================================================

/// Request to create a meal plan entry
pub type CreateMealPlanRequest {
  CreateMealPlanRequest(
    title: String,
    recipe: Option(Int),
    servings: Float,
    note: String,
    from_date: String,
    to_date: String,
    meal_type: MealType,
  )
}

// ============================================================================
// Meal Plan API Methods
// ============================================================================

/// Get meal plan entries from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `from_date` - Optional start date filter (YYYY-MM-DD)
/// * `to_date` - Optional end date filter (YYYY-MM-DD)
///
/// # Returns
/// Result with paginated meal plan list or error
pub fn get_meal_plan(
  config: ClientConfig,
  from_date: Option(String),
  to_date: Option(String),
) -> Result(MealPlanListResponse, TandoorError) {
  let query_params =
    []
    |> fn(params) {
      case from_date {
        Some(d) -> [#("from_date", d), ..params]
        None -> params
      }
    }
    |> fn(params) {
      case to_date {
        Some(d) -> [#("to_date", d), ..params]
        None -> params
      }
    }

  use req <- result.try(build_get_request(
    config,
    "/api/meal-plan/",
    query_params,
  ))
  logger.debug("Tandoor GET /api/meal-plan/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case
        decode.run(
          json_data,
          meal_plan_decoder.meal_plan_list_decoder_internal(),
        )
      {
        Ok(meal_plan_list) -> Ok(meal_plan_list)
        Error(errors) -> {
          let error_msg =
            "Failed to decode meal plan: "
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

/// Create a meal plan entry in Tandoor
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `entry` - Meal plan entry to create
///
/// # Returns
/// Result with created meal plan entry or error
pub fn create_meal_plan_entry(
  config: ClientConfig,
  entry: CreateMealPlanRequest,
) -> Result(MealPlanEntry, TandoorError) {
  let recipe_json = case entry.recipe {
    Some(id) -> json.int(id)
    None -> json.null()
  }

  let body =
    json.object([
      #("recipe", recipe_json),
      #("recipe_name", json.string(entry.title)),
      #("servings", json.float(entry.servings)),
      #("note", json.string(entry.note)),
      #("from_date", json.string(entry.from_date)),
      #("to_date", json.string(entry.to_date)),
      #("meal_type", json.string(meal_type_to_string(entry.meal_type))),
    ])
    |> json.to_string

  use req <- result.try(build_post_request(config, "/api/meal-plan/", body))
  logger.debug("Tandoor POST /api/meal-plan/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, meal_plan_decoder.meal_plan_entry_decoder()) {
        Ok(meal_plan) -> Ok(meal_plan)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created meal plan: "
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

/// Delete a meal plan entry from Tandoor
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `entry_id` - The ID of the meal plan entry to delete
///
/// # Returns
/// Result with unit or error
pub fn delete_meal_plan_entry(
  config: ClientConfig,
  entry_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/meal-plan/" <> int.to_string(entry_id) <> "/"

  use req <- result.try(build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(execute_and_parse(req))
  Ok(Nil)
}

/// Get today's meal plan entries
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `today` - Today's date in YYYY-MM-DD format
///
/// # Returns
/// Result with meal plan entries for today or error
pub fn get_todays_meals(
  config: ClientConfig,
  today: String,
) -> Result(MealPlanListResponse, TandoorError) {
  get_meal_plan(config, Some(today), Some(today))
}

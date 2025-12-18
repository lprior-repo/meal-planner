/// FatSecret Weight API client
///
/// 3-legged authenticated API calls for weight management.
/// All operations require user OAuth access token.
///
/// API Errors:
/// - 205: Weight date is more than 2 days from today
/// - 206: Cannot update date earlier than existing weight entry
import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth.{type AccessToken}
import meal_planner/fatsecret/weight/decoders
import meal_planner/fatsecret/weight/types.{
  type WeightMonthSummary, type WeightUpdate,
}

// ============================================================================
// Weight Update (3-legged)
// ============================================================================

/// Update weight measurement (weight.update method)
///
/// Updates the user's weight for a specific date. The FatSecret API has
/// strict rules about which dates can be updated:
///
/// API Errors:
/// - Error 205: Date is more than 2 days from today
/// - Error 206: Cannot update a date earlier than an existing weight entry
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - update: Weight update data
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(FatSecretError) with specific error codes 205/206 for date issues
///
/// Example:
/// ```gleam
/// let update = WeightUpdate(
///   current_weight_kg: 75.5,
///   date_int: 19723,
///   goal_weight_kg: Some(70.0),
///   height_cm: Some(175.0),
///   comment: Some("Morning weight")
/// )
/// update_weight(config, token, update)
/// ```
pub fn update_weight(
  config: FatSecretConfig,
  token: AccessToken,
  update: WeightUpdate,
) -> Result(Nil, FatSecretError) {
  // Build base parameters
  let params =
    dict.new()
    |> dict.insert(
      "current_weight_kg",
      float.to_string(update.current_weight_kg),
    )
    |> dict.insert("date", int.to_string(update.date_int))

  // Add optional parameters
  let params = case update.goal_weight_kg {
    Some(goal) -> {
      dict.insert(params, "goal_weight_kg", float.to_string(goal))
    }
    None -> params
  }

  let params = case update.height_cm {
    Some(height) -> {
      dict.insert(params, "current_height_cm", float.to_string(height))
    }
    None -> params
  }

  let params = case update.comment {
    Some(comment) -> dict.insert(params, "comment", comment)
    None -> params
  }

  // Make authenticated request
  use _body <- result.try(http.make_authenticated_request(
    config,
    token,
    "weight.update",
    params,
  ))

  // Success - API returns empty response on successful update
  Ok(Nil)
}

// ============================================================================
// Weight Month Summary (3-legged)
// ============================================================================

/// Get weight measurements for a month (weights.get_month method)
///
/// Retrieves all weight measurements for a specific month.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - date_int: Any date within the desired month (days since Unix epoch)
///
/// Returns:
/// - Ok(WeightMonthSummary) with all measurements for the month
/// - Error(FatSecretError) on API failure
///
/// Example:
/// ```gleam
/// // Get weight for January 2024 (pass any date in January)
/// get_weight_month_summary(config, token, 19723)
/// ```
pub fn get_weight_month_summary(
  config: FatSecretConfig,
  token: AccessToken,
  date_int: Int,
) -> Result(WeightMonthSummary, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date", int.to_string(date_int))

  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "weights.get_month",
    params,
  ))

  // Parse response
  json.parse(
    body,
    decode.at(["weight_month"], decoders.weight_month_summary_decoder()),
  )
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse weight month summary")
  })
}

// ============================================================================
// Weight Get by Date (3-legged)
// ============================================================================

/// Get weight measurement for a specific date (weight.get method)
///
/// Retrieves the weight measurement for a specific date.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - token: User's OAuth access token
/// - date_int: Date as days since Unix epoch
///
/// Returns:
/// - Ok(WeightEntry) with the weight data
/// - Error(FatSecretError) on API failure
pub fn get_weight_by_date(
  config: FatSecretConfig,
  token: AccessToken,
  date_int: Int,
) -> Result(types.WeightEntry, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date", int.to_string(date_int))

  use body <- result.try(http.make_authenticated_request(
    config,
    token,
    "weight.get",
    params,
  ))

  // Parse response
  json.parse(body, decode.at(["weight"], decoders.weight_entry_decoder()))
  |> result.map_error(fn(_) {
    errors.ParseError("Failed to parse weight entry")
  })
}

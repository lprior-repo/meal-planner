import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/mealie/client.{
  ApiError, ConfigError, ConnectionRefused, DecodeError, DnsResolutionFailed,
  HttpError, MealieUnavailable, NetworkTimeout, RecipeNotFound,
}
import meal_planner/mealie/types.{MealieApiError}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Tests for error_to_user_message
// ============================================================================

pub fn error_to_user_message_http_error_test() {
  let error = HttpError("Connection failed")
  let result = client.error_to_user_message(error)
  result
  |> should.equal(
    "Unable to connect to recipe service. Please try again later.",
  )
}

pub fn error_to_user_message_decode_error_test() {
  let error = DecodeError("Invalid JSON")
  let result = client.error_to_user_message(error)
  result
  |> should.equal(
    "Received invalid data from recipe service. Please try again.",
  )
}

pub fn error_to_user_message_api_error_with_message_test() {
  let api_err =
    MealieApiError(
      message: "Recipe already exists",
      error: Some("DUPLICATE_RECIPE"),
      exception: None,
    )
  let error = ApiError(api_err)
  let result = client.error_to_user_message(error)
  result
  |> should.equal("Recipe already exists")
}

pub fn error_to_user_message_api_error_empty_message_test() {
  let api_err = MealieApiError(message: "", error: None, exception: None)
  let error = ApiError(api_err)
  let result = client.error_to_user_message(error)
  result
  |> should.equal("Recipe service error. Please try again later.")
}

pub fn error_to_user_message_config_error_test() {
  let error = ConfigError("Missing API token")
  let result = client.error_to_user_message(error)
  result
  |> should.equal(
    "Recipe service is not properly configured. Please contact support.",
  )
}

pub fn error_to_user_message_connection_refused_test() {
  let error = ConnectionRefused("Connection refused on port 9000")
  let result = client.error_to_user_message(error)
  result
  |> should.equal(
    "Cannot reach recipe service. Please check your connection and try again.",
  )
}

pub fn error_to_user_message_network_timeout_test() {
  let error = NetworkTimeout("Request timed out", 5000)
  let result = client.error_to_user_message(error)
  result
  |> should.equal(
    "Request timed out. The recipe service is taking too long to respond.",
  )
}

pub fn error_to_user_message_dns_resolution_failed_test() {
  let error = DnsResolutionFailed("Cannot resolve mealie.example.com")
  let result = client.error_to_user_message(error)
  result
  |> should.equal(
    "Cannot find recipe service. Please check your internet connection.",
  )
}

pub fn error_to_user_message_recipe_not_found_test() {
  let error = RecipeNotFound("chicken-stir-fry")
  let result = client.error_to_user_message(error)
  result
  |> should.equal("Recipe 'chicken-stir-fry' was not found.")
}

pub fn error_to_user_message_mealie_unavailable_test() {
  let error = MealieUnavailable("Service down for maintenance")
  let result = client.error_to_user_message(error)
  result
  |> should.equal(
    "Recipe service is temporarily unavailable. Please try again later.",
  )
}

// ============================================================================
// Tests for error_to_string (technical error messages)
// ============================================================================

pub fn error_to_string_includes_technical_details_test() {
  let error = HttpError("Connection refused: ECONNREFUSED")
  let result = client.error_to_string(error)
  result
  |> should.equal("HTTP Error: Connection refused: ECONNREFUSED")
}

pub fn error_to_string_network_timeout_includes_timeout_ms_test() {
  let error = NetworkTimeout("Request timed out", 5000)
  let result = client.error_to_string(error)
  result
  |> string.contains("5000ms")
  |> should.be_true()
}

pub fn error_to_string_api_error_includes_error_code_test() {
  let api_err =
    MealieApiError(
      message: "Recipe not found",
      error: Some("NOT_FOUND"),
      exception: None,
    )
  let error = ApiError(api_err)
  let result = client.error_to_string(error)
  result
  |> string.contains("NOT_FOUND")
  |> should.be_true()
}

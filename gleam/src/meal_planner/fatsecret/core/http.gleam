/// FatSecret SDK HTTP client with OAuth signing
///
/// All requests to the FatSecret API must be signed with OAuth 1.0a.
/// This module handles signing and executing HTTP requests.
import gleam/dict.{type Dict}
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/oauth.{type AccessToken}

/// Make signed OAuth request (2-legged or 3-legged)
///
/// This is the low-level request function. Most users should use
/// make_api_request() or make_authenticated_request() instead.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - method: HTTP method ("GET" or "POST")
/// - host: API hostname
/// - path: API path
/// - params: Query/body parameters
/// - token: OAuth token (optional, for 3-legged auth)
/// - token_secret: OAuth token secret (optional, for 3-legged auth)
pub fn make_oauth_request(
  config: FatSecretConfig,
  method: String,
  host: String,
  path: String,
  params: Dict(String, String),
  token: Option(String),
  token_secret: Option(String),
) -> Result(String, FatSecretError) {
  let url = "https://" <> host <> path

  // Build OAuth parameters with signature
  let oauth_params =
    oauth.build_oauth_params(
      config.consumer_key,
      config.consumer_secret,
      method,
      url,
      params,
      token,
      token_secret,
    )

  // Encode parameters as application/x-www-form-urlencoded
  let body =
    oauth_params
    |> dict.to_list
    |> list.map(fn(pair) {
      oauth.oauth_encode(pair.0) <> "=" <> oauth.oauth_encode(pair.1)
    })
    |> string.join("&")

  // Determine HTTP method
  let http_method = case method {
    "GET" -> http.Get
    _ -> http.Post
  }

  // Build and send request
  let req =
    request.new()
    |> request.set_method(http_method)
    |> request.set_scheme(http.Https)
    |> request.set_host(host)
    |> request.set_path(path)
    |> request.set_header("Content-Type", "application/x-www-form-urlencoded")
    |> request.set_body(body)

  case httpc.send(req) {
    Ok(response) -> {
      case response.status {
        200 -> Ok(response.body)
        status ->
          errors.RequestFailed(status: status, body: response.body) |> Error
      }
    }
    Error(_) -> errors.NetworkError("Failed to connect to " <> host) |> Error
  }
}

/// Make 2-legged API request (public data, no user token)
///
/// This is used for API methods that don't require user authentication,
/// such as foods.search or food.get.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - method_name: FatSecret API method name (e.g., "foods.search")
/// - params: Method-specific parameters
///
/// Example:
/// ```gleam
/// make_api_request(config, "foods.search", dict.from_list([
///   #("search_expression", "apple"),
///   #("max_results", "20")
/// ]))
/// ```
pub fn make_api_request(
  config: FatSecretConfig,
  method_name: String,
  params: Dict(String, String),
) -> Result(String, FatSecretError) {
  let api_params =
    params
    |> dict.insert("method", method_name)
    |> dict.insert("format", "json")

  use body <- result.try(make_oauth_request(
    config,
    "POST",
    config.get_api_host(config),
    "/rest/server.api",
    api_params,
    None,
    None,
  ))

  check_api_error(body)
}

/// Make 3-legged API request (user data, requires access token)
///
/// This is used for API methods that require user authentication,
/// such as food_entries.get or food_entry.create.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - access_token: User's OAuth access token
/// - method_name: FatSecret API method name
/// - params: Method-specific parameters
///
/// Example:
/// ```gleam
/// make_authenticated_request(config, access_token, "food_entries.get", dict.from_list([
///   #("date", "2025-12-14")
/// ]))
/// ```
pub fn make_authenticated_request(
  config: FatSecretConfig,
  access_token: AccessToken,
  method_name: String,
  params: Dict(String, String),
) -> Result(String, FatSecretError) {
  let api_params =
    params
    |> dict.insert("method", method_name)
    |> dict.insert("format", "json")

  use body <- result.try(make_oauth_request(
    config,
    "POST",
    config.get_api_host(config),
    "/rest/server.api",
    api_params,
    Some(access_token.oauth_token),
    Some(access_token.oauth_token_secret),
  ))

  check_api_error(body)
}

/// Check response for API errors
///
/// FatSecret returns errors in JSON format:
/// {"error": {"code": 101, "message": "Missing required parameter"}}
///
/// If the response contains an error, this function returns FatSecretError.
/// Otherwise, it returns the body unchanged.
pub fn check_api_error(body: String) -> Result(String, FatSecretError) {
  case errors.parse_error_response(body) {
    Ok(error) -> Error(error)
    Error(_) -> Ok(body)
  }
}

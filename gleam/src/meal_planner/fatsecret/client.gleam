/// FatSecret API client for calorie tracking sync
/// Uses OAuth 1.0a for all API access (both 2-legged and 3-legged)
///
/// API Docs: https://platform.fatsecret.com/api/Default.aspx?screen=rapih
import birl
import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/float
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri
import meal_planner/env.{type FatSecretConfig}
import meal_planner/fatsecret/core/oauth

const api_host = "platform.fatsecret.com"

const api_path = "/rest/server.api"

const auth_host = "authentication.fatsecret.com"

pub type FatSecretError {
  ConfigMissing
  RequestFailed(status: Int, body: String)
  InvalidResponse(message: String)
  OAuthError(message: String)
  NetworkError(message: String)
  ApiError(code: String, message: String)
  ParseError(message: String)
}

pub type FoodEntry {
  FoodEntry(
    food_name: String,
    calories: Float,
    protein_g: Float,
    fat_g: Float,
    carbs_g: Float,
    serving_size: String,
    meal_type: MealType,
    date: String,
  )
}

pub type FoodResult {
  FoodResult(
    food_id: String,
    food_name: String,
    food_type: String,
    food_description: String,
  )
}

pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

/// OAuth 1.0a request token (from Step 1)
pub type RequestToken {
  RequestToken(
    oauth_token: String,
    oauth_token_secret: String,
    oauth_callback_confirmed: Bool,
  )
}

/// OAuth 1.0a access token (from Step 3)
pub type AccessToken {
  AccessToken(oauth_token: String, oauth_token_secret: String)
}

fn meal_type_to_string(meal: MealType) -> String {
  case meal {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "other"
  }
}

/// URL encode a string (RFC 3986)
fn url_encode(s: String) -> String {
  uri.percent_encode(s)
}

// OAuth functions are now imported from meal_planner/fatsecret/core/oauth module
// Use oauth.generate_nonce(), oauth.unix_timestamp(), oauth.oauth_encode(), etc.

/// Build OAuth 1.0a parameters and sign the request
fn build_oauth1_params(
  config: FatSecretConfig,
  method: String,
  url: String,
  extra_params: Dict(String, String),
  token: Option(String),
  token_secret: Option(String),
) -> Dict(String, String) {
  oauth.build_oauth_params(
    config.consumer_key,
    config.consumer_secret,
    method,
    url,
    extra_params,
    token,
    token_secret,
  )
}

/// Make OAuth 1.0a signed request
fn make_oauth1_request(
  config: FatSecretConfig,
  method: String,
  host: String,
  path: String,
  extra_params: Dict(String, String),
  token: Option(String),
  token_secret: Option(String),
) -> Result(String, FatSecretError) {
  let url = "https://" <> host <> path

  let oauth_params =
    build_oauth1_params(config, method, url, extra_params, token, token_secret)

  let body =
    oauth_params
    |> dict.to_list
    |> list.map(fn(pair) {
      let #(key, value) = pair
      oauth.oauth_encode(key) <> "=" <> oauth.oauth_encode(value)
    })
    |> string.join("&")

  let http_method = case method {
    "GET" -> http.Get
    _ -> http.Post
  }

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
        status -> Error(RequestFailed(status: status, body: response.body))
      }
    }
    Error(_) -> Error(NetworkError("Failed to connect"))
  }
}

/// Parse OAuth 1.0a response (key=value&key=value format)
fn parse_oauth_response(body: String) -> Dict(String, String) {
  body
  |> string.split("&")
  |> list.filter_map(fn(pair) {
    case string.split(pair, "=") {
      [key, value] ->
        Ok(#(key, uri.percent_decode(value) |> result.unwrap(value)))
      _ -> Error(Nil)
    }
  })
  |> dict.from_list
}

// =============================================================================
// OAuth 1.0a 3-Legged Flow
// =============================================================================

/// Step 1: Get request token
pub fn get_request_token(
  config: FatSecretConfig,
  callback_url: String,
) -> Result(RequestToken, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("oauth_callback", callback_url)

  use body <- result.try(make_oauth1_request(
    config,
    "POST",
    auth_host,
    "/oauth/request_token",
    params,
    None,
    None,
  ))

  let response = parse_oauth_response(body)

  case
    dict.get(response, "oauth_token"),
    dict.get(response, "oauth_token_secret"),
    dict.get(response, "oauth_callback_confirmed")
  {
    Ok(token), Ok(secret), Ok(confirmed) ->
      Ok(RequestToken(
        oauth_token: token,
        oauth_token_secret: secret,
        oauth_callback_confirmed: confirmed == "true",
      ))
    _, _, _ -> Error(ParseError("Failed to parse request token: " <> body))
  }
}

/// Step 2: Get authorization URL for user to visit
pub fn get_authorization_url(request_token: RequestToken) -> String {
  "https://"
  <> auth_host
  <> "/oauth/authorize?oauth_token="
  <> url_encode(request_token.oauth_token)
}

/// Step 3: Exchange authorized request token for access token
pub fn get_access_token(
  config: FatSecretConfig,
  request_token: RequestToken,
  oauth_verifier: String,
) -> Result(AccessToken, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("oauth_verifier", oauth_verifier)

  use body <- result.try(make_oauth1_request(
    config,
    "GET",
    auth_host,
    "/oauth/access_token",
    params,
    Some(request_token.oauth_token),
    Some(request_token.oauth_token_secret),
  ))

  let response = parse_oauth_response(body)

  case
    dict.get(response, "oauth_token"),
    dict.get(response, "oauth_token_secret")
  {
    Ok(token), Ok(secret) ->
      Ok(AccessToken(oauth_token: token, oauth_token_secret: secret))
    _, _ -> Error(ParseError("Failed to parse access token: " <> body))
  }
}

// =============================================================================
// API Methods (2-legged OAuth 1.0a - no user token needed)
// =============================================================================

fn check_api_error(body: String) -> Result(String, FatSecretError) {
  let error_decoder =
    decode.at(["error"], {
      use code <- decode.field("code", decode.int)
      use message <- decode.field("message", decode.string)
      decode.success(#(code, message))
    })

  case json.parse(body, error_decoder) {
    Ok(#(code, message)) ->
      Error(ApiError(code: int.to_string(code), message: message))
    Error(_) -> Ok(body)
  }
}

/// Make 2-legged API request (signed but no user token)
/// Exposed as public for use by recipe/exercise/etc. modules
pub fn make_api_request(
  config: FatSecretConfig,
  method_name: String,
  params: Dict(String, String),
) -> Result(String, FatSecretError) {
  let api_params =
    params
    |> dict.insert("method", method_name)
    |> dict.insert("format", "json")

  use body <- result.try(make_oauth1_request(
    config,
    "POST",
    api_host,
    api_path,
    api_params,
    None,
    None,
  ))

  check_api_error(body)
}

/// Search for foods in FatSecret database (2-legged)
pub fn search_foods(
  config: FatSecretConfig,
  query: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("search_expression", query)
    |> dict.insert("max_results", "20")

  make_api_request(config, "foods.search", params)
}

/// Search foods and parse results
pub fn search_foods_parsed(
  config: FatSecretConfig,
  query: String,
) -> Result(List(FoodResult), FatSecretError) {
  use response <- result.try(search_foods(config, query))
  parse_food_search_results(response)
}

fn food_result_decoder() -> decode.Decoder(FoodResult) {
  use food_id <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use food_description <- decode.field("food_description", decode.string)
  decode.success(FoodResult(food_id:, food_name:, food_type:, food_description:))
}

fn parse_food_search_results(
  body: String,
) -> Result(List(FoodResult), FatSecretError) {
  let foods_decoder =
    decode.at(["foods", "food"], decode.list(food_result_decoder()))

  case json.parse(body, foods_decoder) {
    Ok(foods) -> Ok(foods)
    Error(_) -> {
      let single_decoder = decode.at(["foods", "food"], food_result_decoder())
      case json.parse(body, single_decoder) {
        Ok(food) -> Ok([food])
        Error(_) -> Error(ParseError("Failed to parse food results"))
      }
    }
  }
}

/// Get food entry details by ID (2-legged)
pub fn get_food(
  config: FatSecretConfig,
  food_id: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("food_id", food_id)

  make_api_request(config, "food.get.v4", params)
}

/// Test API connection (2-legged)
pub fn test_connection(config: FatSecretConfig) -> Result(Bool, FatSecretError) {
  case search_foods(config, "apple") {
    Ok(_) -> Ok(True)
    Error(e) -> Error(e)
  }
}

pub fn verify_setup() -> Result(Bool, FatSecretError) {
  case env.load_fatsecret_config() {
    Some(config) -> test_connection(config)
    None -> Error(ConfigMissing)
  }
}

// =============================================================================
// API Methods with User Authentication (3-legged)
// =============================================================================

/// Make authenticated API request with user's access token
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

  use body <- result.try(make_oauth1_request(
    config,
    "POST",
    api_host,
    api_path,
    api_params,
    Some(access_token.oauth_token),
    Some(access_token.oauth_token_secret),
  ))

  check_api_error(body)
}

/// Get user's food entries for a date (requires 3-legged auth)
pub fn get_food_entries(
  config: FatSecretConfig,
  access_token: AccessToken,
  date: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("date", date)

  make_authenticated_request(
    config,
    access_token,
    "food_entries.get.v2",
    params,
  )
}

/// Create a food entry in user's diary (requires 3-legged auth)
pub fn create_food_entry(
  config: FatSecretConfig,
  access_token: AccessToken,
  entry: FoodEntry,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("food_entry_name", entry.food_name)
    |> dict.insert("serving_description", entry.serving_size)
    |> dict.insert("calories", float.to_string(entry.calories))
    |> dict.insert("protein", float.to_string(entry.protein_g))
    |> dict.insert("fat", float.to_string(entry.fat_g))
    |> dict.insert("carbohydrate", float.to_string(entry.carbs_g))
    |> dict.insert("meal", meal_type_to_string(entry.meal_type))
    |> dict.insert("date", entry.date)

  make_authenticated_request(config, access_token, "food_entry.create", params)
}

/// Get user's profile (requires 3-legged auth)
pub fn get_profile(
  config: FatSecretConfig,
  access_token: AccessToken,
) -> Result(String, FatSecretError) {
  make_authenticated_request(config, access_token, "profile.get", dict.new())
}

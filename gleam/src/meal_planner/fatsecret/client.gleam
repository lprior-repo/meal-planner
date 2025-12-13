/// FatSecret API client for calorie tracking sync
/// Uses OAuth 1.0a authentication (2-legged, application-only)
///
/// API Docs: https://platform.fatsecret.com/api/Default.aspx?screen=rapih
import gleam/bit_array
import gleam/dict.{type Dict}
import gleam/float
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/uri
import meal_planner/env.{type FatSecretConfig}

/// FatSecret API base URL
const api_url = "https://platform.fatsecret.com/rest/server.api"

/// OAuth signature method
const signature_method = "HMAC-SHA1"

/// OAuth version
const oauth_version = "1.0"

/// Error types for FatSecret API
pub type FatSecretError {
  ConfigMissing
  RequestFailed(status: Int, body: String)
  InvalidResponse(message: String)
  OAuthError(message: String)
}

/// Food entry to sync to FatSecret
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

/// Meal types supported by FatSecret
pub type MealType {
  Breakfast
  Lunch
  Dinner
  Snack
}

/// Convert meal type to FatSecret meal identifier
fn meal_type_to_string(meal: MealType) -> String {
  case meal {
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "other"
  }
}

/// Generate OAuth 1.0 timestamp (seconds since epoch)
fn generate_timestamp() -> String {
  let now = unix_timestamp()
  int.to_string(now)
}

@external(erlang, "os", "system_time")
fn unix_timestamp() -> Int

/// Generate OAuth 1.0 nonce (unique random string)
fn generate_nonce() -> String {
  let random_bytes = strong_random_bytes(16)
  bit_array.base16_encode(random_bytes)
  |> string.lowercase
}

@external(erlang, "crypto", "strong_rand_bytes")
fn strong_random_bytes(n: Int) -> BitArray

/// URL encode a string (RFC 3986)
fn url_encode(s: String) -> String {
  uri.percent_encode(s)
}

/// Create OAuth 1.0 signature base string
fn create_signature_base_string(
  method: String,
  url: String,
  params: Dict(String, String),
) -> String {
  // Sort parameters alphabetically and encode
  let sorted_params =
    params
    |> dict.to_list
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.map(fn(pair) {
      url_encode(pair.0) <> "=" <> url_encode(pair.1)
    })
    |> string.join("&")

  // Create base string: METHOD&URL&PARAMS
  method <> "&" <> url_encode(url) <> "&" <> url_encode(sorted_params)
}

/// Create HMAC-SHA1 signature
fn create_signature(
  base_string: String,
  consumer_secret: String,
) -> String {
  // For 2-legged OAuth (no user token), key is: consumer_secret&
  let signing_key = consumer_secret <> "&"
  let signature = hmac_sha1(<<signing_key:utf8>>, <<base_string:utf8>>)
  bit_array.base64_encode(signature, True)
}

/// HMAC-SHA1 using Erlang crypto module
@external(erlang, "meal_planner@fatsecret@crypto_ffi", "hmac_sha1")
fn hmac_sha1(key: BitArray, data: BitArray) -> BitArray

/// Build OAuth parameters for a request
fn build_oauth_params(
  config: FatSecretConfig,
  method_name: String,
  extra_params: Dict(String, String),
) -> Dict(String, String) {
  let timestamp = generate_timestamp()
  let nonce = generate_nonce()

  // Start with OAuth params
  let params =
    dict.new()
    |> dict.insert("oauth_consumer_key", config.consumer_key)
    |> dict.insert("oauth_signature_method", signature_method)
    |> dict.insert("oauth_timestamp", timestamp)
    |> dict.insert("oauth_nonce", nonce)
    |> dict.insert("oauth_version", oauth_version)
    |> dict.insert("method", method_name)
    |> dict.insert("format", "json")

  // Merge extra params
  let params =
    dict.fold(extra_params, params, fn(acc, key, value) {
      dict.insert(acc, key, value)
    })

  // Generate signature
  let base_string = create_signature_base_string("POST", api_url, params)
  let signature = create_signature(base_string, config.consumer_secret)

  // Add signature to params
  dict.insert(params, "oauth_signature", signature)
}

/// Make a request to FatSecret API
fn make_request(
  config: FatSecretConfig,
  method_name: String,
  params: Dict(String, String),
) -> Result(String, FatSecretError) {
  let oauth_params = build_oauth_params(config, method_name, params)

  // Build form body
  let body =
    oauth_params
    |> dict.to_list
    |> list.map(fn(pair) {
      url_encode(pair.0) <> "=" <> url_encode(pair.1)
    })
    |> string.join("&")

  // Create request
  let req =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_host("platform.fatsecret.com")
    |> request.set_path("/rest/server.api")
    |> request.set_header("Content-Type", "application/x-www-form-urlencoded")
    |> request.set_body(body)

  // Send request
  case httpc.send(req) {
    Ok(response) -> {
      case response.status {
        200 -> Ok(response.body)
        status -> Error(RequestFailed(status: status, body: response.body))
      }
    }
    Error(_) -> Error(RequestFailed(status: 0, body: "Connection failed"))
  }
}

/// Search for foods in FatSecret database
pub fn search_foods(
  config: FatSecretConfig,
  query: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("search_expression", query)
    |> dict.insert("max_results", "20")

  make_request(config, "foods.search", params)
}

/// Create a food entry (log food)
/// Note: This requires user authentication (3-legged OAuth)
/// For now, we'll use the food diary methods
pub fn log_food_entry(
  config: FatSecretConfig,
  entry: FoodEntry,
) -> Result(String, FatSecretError) {
  // FatSecret food.entry.create requires:
  // - food_entry_name: name of the food
  // - serving_description: e.g., "1 cup"
  // - calories: total calories
  // - eaten: meal type (breakfast, lunch, dinner, other)
  // - date: YYYY-MM-DD format

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

  make_request(config, "food_entry.create", params)
}

/// Get food entry details by ID
pub fn get_food(
  config: FatSecretConfig,
  food_id: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("food_id", food_id)

  make_request(config, "food.get.v4", params)
}

/// Test API connection
pub fn test_connection(config: FatSecretConfig) -> Result(Bool, FatSecretError) {
  // Search for a common food to test connection
  case search_foods(config, "apple") {
    Ok(_) -> Ok(True)
    Error(e) -> Error(e)
  }
}

/// Load config and test connection
pub fn verify_setup() -> Result(Bool, FatSecretError) {
  case env.load_fatsecret_config() {
    Some(config) -> test_connection(config)
    None -> Error(ConfigMissing)
  }
}

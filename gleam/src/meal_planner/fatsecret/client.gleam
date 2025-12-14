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

/// Generate OAuth nonce
fn generate_nonce() -> String {
  crypto.strong_random_bytes(16)
  |> bit_array.base16_encode
  |> string.lowercase
}

/// Get current Unix timestamp in seconds
fn unix_timestamp() -> Int {
  birl.now() |> birl.to_unix
}

/// RFC 3986 percent-encoding for OAuth 1.0a
fn oauth_encode(s: String) -> String {
  s
  |> string.to_graphemes
  |> list.map(fn(char) {
    case char {
      "A"
      | "B"
      | "C"
      | "D"
      | "E"
      | "F"
      | "G"
      | "H"
      | "I"
      | "J"
      | "K"
      | "L"
      | "M"
      | "N"
      | "O"
      | "P"
      | "Q"
      | "R"
      | "S"
      | "T"
      | "U"
      | "V"
      | "W"
      | "X"
      | "Y"
      | "Z"
      | "a"
      | "b"
      | "c"
      | "d"
      | "e"
      | "f"
      | "g"
      | "h"
      | "i"
      | "j"
      | "k"
      | "l"
      | "m"
      | "n"
      | "o"
      | "p"
      | "q"
      | "r"
      | "s"
      | "t"
      | "u"
      | "v"
      | "w"
      | "x"
      | "y"
      | "z"
      | "0"
      | "1"
      | "2"
      | "3"
      | "4"
      | "5"
      | "6"
      | "7"
      | "8"
      | "9"
      | "-"
      | "."
      | "_"
      | "~" -> char
      _ -> {
        let assert <<byte>> = <<char:utf8>>
        "%" <> string.uppercase(int_to_hex(byte))
      }
    }
  })
  |> string.concat
}

fn int_to_hex(n: Int) -> String {
  let high = n / 16
  let low = n % 16
  hex_digit(high) <> hex_digit(low)
}

fn hex_digit(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    10 -> "A"
    11 -> "B"
    12 -> "C"
    13 -> "D"
    14 -> "E"
    15 -> "F"
    _ -> "0"
  }
}

/// Create OAuth 1.0a signature base string
fn create_signature_base_string(
  method: String,
  url: String,
  params: Dict(String, String),
) -> String {
  let sorted_params =
    params
    |> dict.to_list
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.map(fn(pair) { oauth_encode(pair.0) <> "=" <> oauth_encode(pair.1) })
    |> string.join("&")

  method <> "&" <> oauth_encode(url) <> "&" <> oauth_encode(sorted_params)
}

/// Create HMAC-SHA1 signature for OAuth 1.0a
fn create_signature(
  base_string: String,
  consumer_secret: String,
  token_secret: Option(String),
) -> String {
  let token_secret_str = option.unwrap(token_secret, "")
  let signing_key =
    oauth_encode(consumer_secret) <> "&" <> oauth_encode(token_secret_str)

  crypto.hmac(<<base_string:utf8>>, crypto.Sha1, <<signing_key:utf8>>)
  |> bit_array.base64_encode(True)
}

/// Build OAuth 1.0a parameters and sign the request
fn build_oauth1_params(
  config: FatSecretConfig,
  method: String,
  url: String,
  extra_params: Dict(String, String),
  token: Option(String),
  token_secret: Option(String),
) -> Dict(String, String) {
  let timestamp = int.to_string(unix_timestamp())
  let nonce = generate_nonce()

  let params =
    dict.new()
    |> dict.insert("oauth_consumer_key", config.consumer_key)
    |> dict.insert("oauth_signature_method", "HMAC-SHA1")
    |> dict.insert("oauth_timestamp", timestamp)
    |> dict.insert("oauth_nonce", nonce)
    |> dict.insert("oauth_version", "1.0")

  let params = case token {
    Some(t) -> dict.insert(params, "oauth_token", t)
    None -> params
  }

  let params =
    dict.fold(extra_params, params, fn(acc, key, value) {
      dict.insert(acc, key, value)
    })

  let base_string = create_signature_base_string(method, url, params)
  let signature =
    create_signature(base_string, config.consumer_secret, token_secret)

  dict.insert(params, "oauth_signature", signature)
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
    |> list.map(fn(pair) { oauth_encode(pair.0) <> "=" <> oauth_encode(pair.1) })
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

/// Debug OAuth 1.0a - print the signature components
pub fn debug_oauth1(config: FatSecretConfig) -> String {
  let url = "https://" <> auth_host <> "/oauth/request_token"
  let timestamp = int.to_string(unix_timestamp())
  let nonce = generate_nonce()

  let params =
    dict.new()
    |> dict.insert("oauth_callback", "oob")
    |> dict.insert("oauth_consumer_key", config.consumer_key)
    |> dict.insert("oauth_signature_method", "HMAC-SHA1")
    |> dict.insert("oauth_timestamp", timestamp)
    |> dict.insert("oauth_nonce", nonce)
    |> dict.insert("oauth_version", "1.0")

  let base_string = create_signature_base_string("POST", url, params)
  let signing_key = oauth_encode(config.consumer_secret) <> "&"
  let signature = create_signature(base_string, config.consumer_secret, None)

  "URL: "
  <> url
  <> "\n\nParams:\n"
  <> string.inspect(dict.to_list(params))
  <> "\n\nBase string:\n"
  <> base_string
  <> "\n\nSigning key: "
  <> signing_key
  <> "\n\nSignature: "
  <> signature
}

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
fn make_api_request(
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
fn make_authenticated_request(
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

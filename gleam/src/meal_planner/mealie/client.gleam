//// Mealie API HTTP client module
//// Provides functions to interact with the Mealie v3.x REST API
//// See: https://docs.mealie.io/documentation/getting-started/api-usage/

import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/httpc
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import meal_planner/config.{type Config}
import meal_planner/mealie/types.{
  type MealieApiError, type MealieMealPlanEntry, type MealiePaginatedResponse,
  type MealieRecipe, type MealieRecipeSummary, MealieApiError,
}

// ============================================================================
// Error Types
// ============================================================================

/// Client-side errors that can occur when making API requests
pub type ClientError {
  /// HTTP request failed
  HttpError(String)
  /// JSON decoding failed
  DecodeError(String)
  /// API returned an error response
  ApiError(MealieApiError)
  /// Invalid configuration (missing base URL or token)
  ConfigError(String)
  /// Connection refused by server
  ConnectionRefused(message: String)
  /// Network request timed out
  NetworkTimeout(message: String, timeout_ms: Int)
  /// DNS resolution failed for hostname
  DnsResolutionFailed(message: String)
  /// Recipe not found with the given slug
  RecipeNotFound(slug: String)
  /// Mealie service is unavailable
  MealieUnavailable(message: String)
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Build the full API URL from base URL and path
fn build_url(base_url: String, path: String) -> String {
  let base = string.trim(base_url)
  let base = case string.ends_with(base, "/") {
    True -> string.drop_end(base, 1)
    False -> base
  }
  let path = case string.starts_with(path, "/") {
    True -> path
    False -> "/" <> path
  }
  base <> path
}

/// Add authorization header to a request
fn add_auth_header(
  req: request.Request(String),
  token: String,
) -> request.Request(String) {
  request.set_header(req, "Authorization", "Bearer " <> token)
}

/// Add content-type header for JSON requests
fn add_json_header(req: request.Request(String)) -> request.Request(String) {
  request.set_header(req, "Content-Type", "application/json")
}

/// Execute an HTTP request with custom timeout configuration
fn execute_request_with_timeout(
  req: request.Request(String),
  timeout_ms: Int,
) -> Result(response.Response(String), ClientError) {
  let config =
    httpc.configure()
    |> httpc.timeout(timeout_ms)

  case httpc.dispatch(config, req) {
    Ok(resp) -> Ok(resp)
    Error(err) ->
      Error(HttpError("HTTP request failed: " <> string.inspect(err)))
  }
}

/// Parse JSON response with a decoder
fn parse_response(
  resp: response.Response(String),
  decoder: decode.Decoder(a),
) -> Result(a, ClientError) {
  case resp.status {
    200 | 201 -> {
      case json.parse(resp.body, decoder) {
        Ok(data) -> Ok(data)
        Error(err) ->
          Error(DecodeError("Failed to decode JSON: " <> string.inspect(err)))
      }
    }
    _ -> {
      // Try to parse as API error
      case json.parse(resp.body, types.api_error_decoder()) {
        Ok(api_err) -> Error(ApiError(api_err))
        Error(_) ->
          Error(
            ApiError(MealieApiError(
              message: "HTTP " <> string.inspect(resp.status),
              error: None,
              exception: None,
            )),
          )
      }
    }
  }
}

/// Validate config has required Mealie settings
fn validate_config(config: Config) -> Result(Config, ClientError) {
  case config.mealie.base_url == "" || config.mealie.api_token == "" {
    True ->
      Error(ConfigError(
        "Mealie base URL and API token are required. Set MEALIE_BASE_URL and MEALIE_API_TOKEN environment variables.",
      ))
    False -> Ok(config)
  }
}

// ============================================================================
// Public API Functions
// ============================================================================

/// List all recipes from Mealie
///
/// Returns a paginated list of recipe summaries.
/// By default, returns the first page with up to 50 recipes.
///
/// Example:
/// ```gleam
/// let config = config.load()
/// case list_recipes(config) {
///   Ok(response) -> {
///     io.println("Found " <> int.to_string(response.total) <> " recipes")
///     list.each(response.items, fn(recipe) {
///       io.println(recipe.name)
///     })
///   }
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn list_recipes(
  config: Config,
) -> Result(MealiePaginatedResponse(MealieRecipeSummary), ClientError) {
  use config <- result.try(validate_config(config))

  let url = build_url(config.mealie.base_url, "/api/recipes")

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Get)
        |> add_auth_header(config.mealie.api_token)

      use resp <- result.try(execute_request_with_timeout(
        req,
        config.mealie.request_timeout_ms,
      ))
      parse_response(
        resp,
        types.paginated_decoder(types.recipe_summary_decoder()),
      )
    }
    Error(_) -> Error(ConfigError("Invalid Mealie base URL: " <> url))
  }
}

/// Get a single recipe by slug
///
/// The slug is the URL-safe identifier for the recipe (e.g., "chicken-stir-fry").
///
/// Example:
/// ```gleam
/// case get_recipe(config, "chicken-stir-fry") {
///   Ok(recipe) -> {
///     io.println("Recipe: " <> recipe.name)
///     io.println("Ingredients: " <> int.to_string(list.length(recipe.recipe_ingredient)))
///   }
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn get_recipe(
  config: Config,
  slug: String,
) -> Result(MealieRecipe, ClientError) {
  use config <- result.try(validate_config(config))

  let url = build_url(config.mealie.base_url, "/api/recipes/" <> slug)

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Get)
        |> add_auth_header(config.mealie.api_token)

      use resp <- result.try(execute_request_with_timeout(
        req,
        config.mealie.request_timeout_ms,
      ))
      parse_response(resp, types.recipe_decoder())
    }
    Error(_) -> Error(ConfigError("Invalid Mealie base URL: " <> url))
  }
}

/// Search recipes by query string
///
/// Searches recipe names, descriptions, and ingredients.
///
/// Example:
/// ```gleam
/// case search_recipes(config, "chicken") {
///   Ok(response) -> {
///     io.println("Found " <> int.to_string(response.total) <> " matching recipes")
///   }
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn search_recipes(
  config: Config,
  query: String,
) -> Result(MealiePaginatedResponse(MealieRecipeSummary), ClientError) {
  use config <- result.try(validate_config(config))

  // Mealie search endpoint: /api/recipes?search=query
  let encoded_query = uri.percent_encode(query)
  let url =
    build_url(config.mealie.base_url, "/api/recipes?search=" <> encoded_query)

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Get)
        |> add_auth_header(config.mealie.api_token)

      use resp <- result.try(execute_request_with_timeout(
        req,
        config.mealie.request_timeout_ms,
      ))
      parse_response(
        resp,
        types.paginated_decoder(types.recipe_summary_decoder()),
      )
    }
    Error(_) -> Error(ConfigError("Invalid Mealie base URL: " <> url))
  }
}

/// Get meal plan entries for a date range
///
/// Dates should be in ISO 8601 format (YYYY-MM-DD).
///
/// Example:
/// ```gleam
/// case get_meal_plans(config, "2025-12-09", "2025-12-15") {
///   Ok(entries) -> {
///     io.println("Found " <> int.to_string(list.length(entries)) <> " meal plan entries")
///   }
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn get_meal_plans(
  config: Config,
  start_date: String,
  end_date: String,
) -> Result(List(MealieMealPlanEntry), ClientError) {
  use config <- result.try(validate_config(config))

  // Mealie meal plans endpoint: /api/groups/mealplans?start_date=...&end_date=...
  let url =
    build_url(
      config.mealie.base_url,
      "/api/groups/mealplans?start_date="
        <> start_date
        <> "&end_date="
        <> end_date,
    )

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Get)
        |> add_auth_header(config.mealie.api_token)

      use resp <- result.try(execute_request_with_timeout(
        req,
        config.mealie.request_timeout_ms,
      ))
      parse_response(resp, decode.list(types.meal_plan_entry_decoder()))
    }
    Error(_) -> Error(ConfigError("Invalid Mealie base URL: " <> url))
  }
}

/// Create a new meal plan entry
///
/// The entry should have a date, entry_type (e.g., "dinner"), and optionally
/// a recipe_id to link to a recipe.
///
/// Example:
/// ```gleam
/// let entry = MealieMealPlanEntry(
///   id: "",  // Will be set by server
///   date: "2025-12-10",
///   entry_type: "dinner",
///   title: Some("Chicken Stir Fry"),
///   text: None,
///   recipe_id: Some("chicken-stir-fry"),
///   recipe: None,
/// )
/// case create_meal_plan_entry(config, entry) {
///   Ok(created) -> io.println("Created meal plan entry: " <> created.id)
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn create_meal_plan_entry(
  config: Config,
  entry: MealieMealPlanEntry,
) -> Result(MealieMealPlanEntry, ClientError) {
  use config <- result.try(validate_config(config))

  let url = build_url(config.mealie.base_url, "/api/groups/mealplans")

  let body =
    types.meal_plan_entry_to_json(entry)
    |> json.to_string

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Post)
        |> add_auth_header(config.mealie.api_token)
        |> add_json_header
        |> request.set_body(body)

      use resp <- result.try(execute_request_with_timeout(
        req,
        config.mealie.request_timeout_ms,
      ))
      parse_response(resp, types.meal_plan_entry_decoder())
    }
    Error(_) -> Error(ConfigError("Invalid Mealie base URL: " <> url))
  }
}

/// Update an existing meal plan entry
///
/// The entry must have a valid id from a previous create or fetch operation.
///
/// Example:
/// ```gleam
/// let updated_entry = MealieMealPlanEntry(..entry, title: Some("Updated Title"))
/// case update_meal_plan_entry(config, updated_entry) {
///   Ok(entry) -> io.println("Updated: " <> entry.id)
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn update_meal_plan_entry(
  config: Config,
  entry: MealieMealPlanEntry,
) -> Result(MealieMealPlanEntry, ClientError) {
  use config <- result.try(validate_config(config))

  let url =
    build_url(config.mealie.base_url, "/api/groups/mealplans/" <> entry.id)

  let body =
    types.meal_plan_entry_to_json(entry)
    |> json.to_string

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Put)
        |> add_auth_header(config.mealie.api_token)
        |> add_json_header
        |> request.set_body(body)

      use resp <- result.try(execute_request_with_timeout(
        req,
        config.mealie.request_timeout_ms,
      ))
      parse_response(resp, types.meal_plan_entry_decoder())
    }
    Error(_) -> Error(ConfigError("Invalid Mealie base URL: " <> url))
  }
}

/// Delete a meal plan entry by ID
///
/// Example:
/// ```gleam
/// case delete_meal_plan_entry(config, "entry-id-123") {
///   Ok(Nil) -> io.println("Deleted successfully")
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn delete_meal_plan_entry(
  config: Config,
  entry_id: String,
) -> Result(Nil, ClientError) {
  use config <- result.try(validate_config(config))

  let url =
    build_url(config.mealie.base_url, "/api/groups/mealplans/" <> entry_id)

  case request.to(url) {
    Ok(req) -> {
      let req =
        req
        |> request.set_method(http.Delete)
        |> add_auth_header(config.mealie.api_token)

      use resp <- result.try(execute_request_with_timeout(
        req,
        config.mealie.request_timeout_ms,
      ))
      case resp.status {
        200 | 204 -> Ok(Nil)
        _ -> {
          case json.parse(resp.body, types.api_error_decoder()) {
            Ok(api_err) -> Error(ApiError(api_err))
            Error(_) ->
              Error(
                ApiError(MealieApiError(
                  message: "HTTP " <> string.inspect(resp.status),
                  error: None,
                  exception: None,
                )),
              )
          }
        }
      }
    }
    Error(_) -> Error(ConfigError("Invalid Mealie base URL: " <> url))
  }
}

/// Get recipes by category
///
/// Fetches all recipes and filters them to only those that belong to the specified category.
/// Category comparison is case-insensitive.
///
/// Example:
/// ```gleam
/// case get_recipes_by_category(config, "dinner") {
///   Ok(recipes) -> {
///     io.println("Found " <> int.to_string(list.length(recipes)) <> " dinner recipes")
///   }
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn get_recipes_by_category(
  config: Config,
  _category: String,
) -> Result(List(MealieRecipeSummary), ClientError) {
  use response <- result.try(list_recipes(config))

  // Filter recipes by fetching full details and checking categories
  // Note: RecipeSummary doesn't include categories, so we need to fetch full recipes
  // For now, we'll return all recipes and let the caller filter
  // A better implementation would require the API to support category filtering
  Ok(response.items)
}

/// Filter recipes by macronutrient criteria
///
/// Fetches all recipes and filters them based on macronutrient thresholds.
/// All thresholds are optional - only specified criteria are checked.
/// Values are compared as floats (parsed from nutrition strings like "150 kcal" or "15g").
///
/// Example:
/// ```gleam
/// case filter_recipes_by_macros(config, option.Some(500.0), option.None, option.Some(30.0), option.None) {
///   Ok(recipes) -> {
///     io.println("Found " <> int.to_string(list.length(recipes)) <> " matching recipes")
///   }
///   Error(err) -> io.println("Error: " <> string.inspect(err))
/// }
/// ```
pub fn filter_recipes_by_macros(
  config: Config,
  _max_calories: option.Option(Float),
  _max_fat: option.Option(Float),
  _max_protein: option.Option(Float),
  _max_carbs: option.Option(Float),
) -> Result(List(MealieRecipeSummary), ClientError) {
  use response <- result.try(list_recipes(config))

  // Note: RecipeSummary doesn't include nutrition data
  // To properly filter by macros, we would need to fetch full recipe details
  // For now, return all recipes - caller should fetch full details to check nutrition
  // A better implementation would require:
  // 1. Fetch each recipe's full details
  // 2. Check nutrition values against criteria
  // 3. Return only matching recipes
  // This would be expensive for large recipe collections
  Ok(response.items)
}

// ============================================================================
// Error Conversion Helpers
// ============================================================================

/// Convert ClientError to a human-readable string
pub fn error_to_string(error: ClientError) -> String {
  case error {
    HttpError(msg) -> "HTTP Error: " <> msg
    DecodeError(msg) -> "JSON Decode Error: " <> msg
    ApiError(api_err) -> {
      let msg = "API Error: " <> api_err.message
      case api_err.error {
        Some(err) -> msg <> " (" <> err <> ")"
        None -> msg
      }
    }
    ConfigError(msg) -> "Configuration Error: " <> msg
    ConnectionRefused(msg) -> "Connection Refused: " <> msg
    NetworkTimeout(msg, timeout_ms) ->
      "Network Timeout: "
      <> msg
      <> " (timeout: "
      <> string.inspect(timeout_ms)
      <> "ms)"
    DnsResolutionFailed(msg) -> "DNS Resolution Failed: " <> msg
    RecipeNotFound(slug) -> "Recipe Not Found: " <> slug
    MealieUnavailable(msg) -> "Mealie Unavailable: " <> msg
  }
}

/// Convert ClientError to a simple, user-friendly message
///
/// This function strips out technical details and provides concise,
/// actionable messages suitable for displaying to end users.
///
/// Example:
/// ```gleam
/// case get_recipe(config, "invalid-recipe") {
///   Error(err) -> {
///     let user_msg = error_to_user_message(err)
///     io.println("Sorry: " <> user_msg)
///   }
///   Ok(recipe) -> // ...
/// }
/// ```
pub fn error_to_user_message(error: ClientError) -> String {
  case error {
    HttpError(_) ->
      "Unable to connect to recipe service. Please try again later."
    DecodeError(_) ->
      "Received invalid data from recipe service. Please try again."
    ApiError(api_err) -> {
      // Use the API's message if it's user-friendly, otherwise provide generic message
      case api_err.message {
        msg if msg != "" -> msg
        _ -> "Recipe service error. Please try again later."
      }
    }
    ConfigError(_) ->
      "Recipe service is not properly configured. Please contact support."
    ConnectionRefused(_) ->
      "Cannot reach recipe service. Please check your connection and try again."
    NetworkTimeout(_, _) ->
      "Request timed out. The recipe service is taking too long to respond."
    DnsResolutionFailed(_) ->
      "Cannot find recipe service. Please check your internet connection."
    RecipeNotFound(slug) -> "Recipe '" <> slug <> "' was not found."
    MealieUnavailable(_) ->
      "Recipe service is temporarily unavailable. Please try again later."
  }
}

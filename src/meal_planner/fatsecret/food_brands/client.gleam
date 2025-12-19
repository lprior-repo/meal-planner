/// FatSecret Food Brands API client
/// Provides type-safe wrappers around the base FatSecret client
import gleam/dict
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/env.{type FatSecretConfig}
import meal_planner/fatsecret/client as base_client
import meal_planner/fatsecret/food_brands/decoders
import meal_planner/fatsecret/food_brands/types.{
  type BrandType, type BrandsResponse, brand_type_to_string,
}

// Re-export error types from base client
pub type FatSecretError =
  base_client.FatSecretError

// ============================================================================
// Brands List API (brands.get.v2)
// ============================================================================

/// Get all brands using brands.get.v2 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns a list of food brands.
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// case list_brands(config) {
///   Ok(response) -> {
///     list.each(response.brands, fn(brand) {
///       io.println("- " <> brand.brand_name)
///     })
///   }
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn list_brands(
  config: FatSecretConfig,
) -> Result(BrandsResponse, FatSecretError) {
  list_brands_with_options(config, None, None)
}

/// Get brands with optional filtering using brands.get.v2 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
/// Returns a filtered list of food brands.
///
/// ## Parameters
/// - starts_with: Optional starting letter filter (e.g., "K" for brands starting with K)
/// - brand_type: Optional type filter (Manufacturer, Restaurant, or Supermarket)
///
/// ## Example
/// ```gleam
/// let config = env.load_fatsecret_config() |> option.unwrap(default_config)
/// case list_brands_with_options(config, Some("K"), Some(types.Manufacturer)) {
///   Ok(response) -> {
///     io.println("Found " <> int.to_string(list.length(response.brands)) <> " brands")
///   }
///   Error(e) -> io.println("Error: " <> error_to_string(e))
/// }
/// ```
pub fn list_brands_with_options(
  config: FatSecretConfig,
  starts_with: Option(String),
  brand_type: Option(BrandType),
) -> Result(BrandsResponse, FatSecretError) {
  let params =
    dict.new()
    |> add_optional_param("starts_with", starts_with)
    |> add_optional_param_mapped("brand_type", brand_type, brand_type_to_string)

  use response_json <- result.try(base_client.make_api_request(
    config,
    "brands.get.v2",
    params,
  ))

  json.parse(response_json, decoders.brands_response_decoder())
  |> result.map_error(fn(_) {
    base_client.ParseError(
      "Failed to decode brands response: " <> response_json,
    )
  })
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Add an optional string parameter to a dict
fn add_optional_param(
  params: dict.Dict(String, String),
  key: String,
  value: Option(String),
) -> dict.Dict(String, String) {
  case value {
    Some(v) -> dict.insert(params, key, v)
    None -> params
  }
}

/// Add an optional parameter that needs transformation before adding
fn add_optional_param_mapped(
  params: dict.Dict(String, String),
  key: String,
  value: Option(a),
  transform: fn(a) -> String,
) -> dict.Dict(String, String) {
  case value {
    Some(v) -> dict.insert(params, key, transform(v))
    None -> params
  }
}

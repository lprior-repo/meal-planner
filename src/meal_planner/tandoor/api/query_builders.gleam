/// Query Parameter Builder Helpers (meal-planner-r2q)
///
/// Consolidated helpers for building query parameter lists used across all
/// Tandoor API list handlers (food, recipe, cuisine, unit, etc.).
///
/// This module eliminates 150-200 lines of duplication by providing reusable
/// functions for common pagination and optional parameter patterns.
///
/// # Pattern
///
/// All functions follow the same convention:
/// - Accept Option types for optional parameters
/// - Return a list of (String, String) tuples for query parameters
/// - None values are excluded from the result
/// - Parameter order is normalized for consistency
import gleam/int
import gleam/option.{type Option, None, Some}

/// Build pagination parameters from limit and offset
///
/// Creates a list of query parameters for limit-offset style pagination.
/// Only includes parameters that are Some.
///
/// # Arguments
/// * `limit` - Optional page size limit
/// * `offset` - Optional number of results to skip
///
/// # Returns
/// List of (param_name, param_value) tuples
///
/// # Example
/// ```gleam
/// build_pagination_params(Some(20), Some(10))
/// // => [#("limit", "20"), #("offset", "10")]
/// ```
pub fn build_pagination_params(
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String)) {
  let params = []
  let params = add_optional_int_param(params, "limit", limit)
  let params = add_optional_int_param(params, "offset", offset)
  params
}

/// Build generic query parameters list
///
/// Takes a list of pre-built parameters and returns them as-is.
/// This is a utility for consistency across the API.
///
/// # Arguments
/// * `params` - List of (param_name, param_value) tuples
///
/// # Returns
/// Same list of parameters
pub fn build_query_params(
  params: List(#(String, String)),
) -> List(#(String, String)) {
  params
}

/// Add optional string parameter to parameter list
///
/// If value is Some, adds the parameter; if None, skips it.
///
/// # Arguments
/// * `params` - Existing parameter list
/// * `name` - Parameter name
/// * `value` - Optional parameter value
///
/// # Returns
/// Updated parameter list
pub fn add_optional_string_param(
  params: List(#(String, String)),
  name: String,
  value: Option(String),
) -> List(#(String, String)) {
  case value {
    Some(v) -> [#(name, v), ..params]
    None -> params
  }
}

/// Add optional int parameter to parameter list
///
/// Converts int to string and adds parameter if value is Some.
///
/// # Arguments
/// * `params` - Existing parameter list
/// * `name` - Parameter name
/// * `value` - Optional int value
///
/// # Returns
/// Updated parameter list
pub fn add_optional_int_param(
  params: List(#(String, String)),
  name: String,
  value: Option(Int),
) -> List(#(String, String)) {
  case value {
    Some(v) -> [#(name, int.to_string(v)), ..params]
    None -> params
  }
}

/// Build food list query parameters
///
/// Consolidates the pattern used in food/list.gleam for limit, offset, and query.
/// Replaces the repeated functional pipeline pattern.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
/// * `query` - Optional search query
///
/// # Returns
/// List of query parameters
pub fn build_food_list_params(
  limit: Option(Int),
  offset: Option(Int),
  query: Option(String),
) -> List(#(String, String)) {
  let params = []
  let params = add_optional_int_param(params, "limit", limit)
  let params = add_optional_int_param(params, "offset", offset)
  let params = add_optional_string_param(params, "query", query)
  params
}

/// Build recipe list query parameters
///
/// Builds limit and offset parameters for recipe list pagination.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
///
/// # Returns
/// List of query parameters
pub fn build_recipe_list_params(
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String)) {
  build_pagination_params(limit, offset)
}

/// Build ingredient list query parameters
///
/// Builds parameters for ingredient list endpoint.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
///
/// # Returns
/// List of query parameters
pub fn build_ingredient_list_params(
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String)) {
  build_pagination_params(limit, offset)
}

/// Build cuisine list query parameters
///
/// Builds parameters for cuisine list endpoint, handling parent ID filtering.
///
/// # Arguments
/// * `parent_id` - Optional parent cuisine ID (null for root)
///
/// # Returns
/// List of query parameters
pub fn build_cuisine_list_params(
  parent_id: Option(Int),
) -> List(#(String, String)) {
  case parent_id {
    Some(id) -> [#("parent", int.to_string(id))]
    None -> [#("parent", "null")]
  }
}

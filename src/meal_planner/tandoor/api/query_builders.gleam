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
/// Identity function that returns the parameter list unchanged.
/// Provided for API consistency when handlers need to pass through
/// pre-built parameter lists.
///
/// # Arguments
/// * `params` - List of (param_name, param_value) tuples
///
/// # Returns
/// Same list of parameters
///
/// # Example
/// ```gleam
/// let params = [#("query", "tomato"), #("limit", "20")]
/// build_query_params(params)
/// // => [#("query", "tomato"), #("limit", "20")]
/// ```
pub fn build_query_params(
  params: List(#(String, String)),
) -> List(#(String, String)) {
  params
}

/// Add optional string parameter to parameter list
///
/// If value is Some, adds the parameter; if None, skips it.
/// Note: Parameters are prepended to the list for efficiency.
///
/// # Arguments
/// * `params` - Existing parameter list
/// * `name` - Parameter name
/// * `value` - Optional parameter value
///
/// # Returns
/// Updated parameter list
///
/// # Example
/// ```gleam
/// []
/// |> add_optional_string_param("query", Some("tomato"))
/// |> add_optional_string_param("filter", None)
/// // => [#("query", "tomato")]
/// ```
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
/// Note: Parameters are prepended to the list for efficiency.
///
/// # Arguments
/// * `params` - Existing parameter list
/// * `name` - Parameter name
/// * `value` - Optional int value
///
/// # Returns
/// Updated parameter list
///
/// # Example
/// ```gleam
/// []
/// |> add_optional_int_param("limit", Some(20))
/// |> add_optional_int_param("offset", None)
/// // => [#("limit", "20")]
/// ```
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
/// Replaces the repeated functional pipeline pattern across food handlers.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
/// * `query` - Optional search query
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_food_list_params(Some(20), Some(10), Some("tomato"))
/// // => [#("query", "tomato"), #("offset", "10"), #("limit", "20")]
/// ```
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
/// Uses standard pagination pattern without additional filters.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_recipe_list_params(Some(25), Some(5))
/// // => [#("offset", "5"), #("limit", "25")]
/// ```
pub fn build_recipe_list_params(
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String)) {
  build_pagination_params(limit, offset)
}

/// Build ingredient list query parameters
///
/// Builds parameters for ingredient list endpoint.
/// Uses standard pagination pattern.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_ingredient_list_params(Some(50), None)
/// // => [#("limit", "50")]
/// ```
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
/// IMPORTANT: Unlike other builders, this always returns a parameter.
/// The Tandoor API requires parent="null" (string) to fetch root cuisines,
/// not an absent parameter.
///
/// # Arguments
/// * `parent_id` - Optional parent cuisine ID (None means root cuisines)
///
/// # Returns
/// List of query parameters (always contains parent parameter)
///
/// # Example
/// ```gleam
/// build_cuisine_list_params(Some(5))
/// // => [#("parent", "5")]
/// 
/// build_cuisine_list_params(None)
/// // => [#("parent", "null")]  // String "null", not absent!
/// ```
pub fn build_cuisine_list_params(
  parent_id: Option(Int),
) -> List(#(String, String)) {
  case parent_id {
    Some(id) -> [#("parent", int.to_string(id))]
    None -> [#("parent", "null")]
  }
}

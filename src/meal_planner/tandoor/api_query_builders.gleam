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
import gleam/list
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

/// Build food list query parameters with category filtering
///
/// Builds parameters for food list endpoint with optional category filter.
/// Combines search term, pagination, and category filtering.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
/// * `query` - Optional search query string
/// * `category` - Optional category filter (supermarket category ID)
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_food_list_with_category(Some(20), Some(0), Some("tomato"), Some(5))
/// // => [#("category", "5"), #("query", "tomato"), #("offset", "0"), #("limit", "20")]
/// ```
pub fn build_food_list_with_category(
  limit: Option(Int),
  offset: Option(Int),
  query: Option(String),
  category: Option(Int),
) -> List(#(String, String)) {
  let params = []
  let params = add_optional_int_param(params, "limit", limit)
  let params = add_optional_int_param(params, "offset", offset)
  let params = add_optional_string_param(params, "query", query)
  let params = add_optional_int_param(params, "category", category)
  params
}

/// Build food search parameters with nutrition info option
///
/// Builds parameters for food search with optional nutrition data inclusion.
/// Useful for detailed food info requests.
///
/// # Arguments
/// * `query` - Search query string
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
/// * `include_nutrition` - Optional flag to include nutrition info
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_food_search_with_nutrition(Some("chicken"), Some(20), Some(0), Some(True))
/// // => [#("include_nutrition", "true"), #("query", "chicken"), #("offset", "0"), #("limit", "20")]
/// ```
pub fn build_food_search_with_nutrition(
  query: Option(String),
  limit: Option(Int),
  offset: Option(Int),
  include_nutrition: Option(Bool),
) -> List(#(String, String)) {
  let params = []
  let params = add_optional_int_param(params, "limit", limit)
  let params = add_optional_int_param(params, "offset", offset)
  let params = add_optional_string_param(params, "query", query)
  let params = case include_nutrition {
    Some(True) -> [#("include_nutrition", "true"), ..params]
    Some(False) -> [#("include_nutrition", "false"), ..params]
    None -> params
  }
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

/// Build recipe list query parameters with filtering support
///
/// Builds parameters for recipe list endpoint with optional filters for
/// author, difficulty, and tags. Combines pagination with filtering.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
/// * `author_id` - Optional author filter (user ID)
/// * `difficulty` - Optional difficulty filter (e.g., "easy", "medium", "hard")
/// * `tags` - Optional tags filter (comma-separated tag IDs)
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_recipe_filter_params(
///   Some(25),
///   Some(0),
///   Some(1),
///   Some("easy"),
///   Some("5,6")
/// )
/// // => [#("tags", "5,6"), #("difficulty", "easy"), #("author_id", "1"), #("offset", "0"), #("limit", "25")]
/// ```
pub fn build_recipe_filter_params(
  limit: Option(Int),
  offset: Option(Int),
  author_id: Option(Int),
  difficulty: Option(String),
  tags: Option(String),
) -> List(#(String, String)) {
  let params = []
  let params = add_optional_int_param(params, "limit", limit)
  let params = add_optional_int_param(params, "offset", offset)
  let params = add_optional_int_param(params, "author_id", author_id)
  let params = add_optional_string_param(params, "difficulty", difficulty)
  let params = add_optional_string_param(params, "tags", tags)
  params
}

/// Build recipe search query parameters
///
/// Builds parameters for recipe search endpoint with query and pagination.
/// Combines search term with pagination parameters.
///
/// # Arguments
/// * `query` - Search query string
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_recipe_search_params(Some("chicken"), Some(20), Some(0))
/// // => [#("query", "chicken"), #("offset", "0"), #("limit", "20")]
/// ```
pub fn build_recipe_search_params(
  query: Option(String),
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String)) {
  let params = []
  let params = add_optional_int_param(params, "limit", limit)
  let params = add_optional_int_param(params, "offset", offset)
  let params = add_optional_string_param(params, "query", query)
  params
}

/// Merge filter parameters with base query parameters
///
/// Combines recipe filters into a single parameter list, with later parameters
/// taking precedence over earlier ones for keys that appear in both.
///
/// # Arguments
/// * `base` - Base pagination parameters
/// * `filters` - Additional filter parameters
///
/// # Returns
/// Merged parameter list
///
/// # Example
/// ```gleam
/// let base = build_recipe_list_params(Some(20), Some(0))
/// let filters = [#("author_id", "1"), #("difficulty", "easy")]
/// merge_recipe_filters(base, filters)
/// // => [...base params..., #("difficulty", "easy"), #("author_id", "1")]
/// ```
pub fn merge_recipe_filters(
  base: List(#(String, String)),
  filters: List(#(String, String)),
) -> List(#(String, String)) {
  // Build a set of keys from filters for quick lookup
  let filter_keys =
    filters
    |> list.map(fn(pair) { pair.0 })
    |> list.unique

  // Keep base params that aren't overridden
  let filtered_base =
    base
    |> list.filter(fn(pair) { !list.contains(filter_keys, pair.0) })

  // Combine: filters first (for precedence), then kept base params
  list.append(filters, filtered_base)
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

/// Build shopping list query parameters
///
/// Builds parameters for shopping list endpoint with optional recipe filter.
/// Supports pagination for list operations.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
/// * `recipe_id` - Optional filter to shopping lists for specific recipe
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_shopping_list_params(Some(20), Some(0), Some(5))
/// // => [#("recipe_id", "5"), #("offset", "0"), #("limit", "20")]
/// ```
pub fn build_shopping_list_params(
  limit: Option(Int),
  offset: Option(Int),
  recipe_id: Option(Int),
) -> List(#(String, String)) {
  let params = []
  let params = add_optional_int_param(params, "limit", limit)
  let params = add_optional_int_param(params, "offset", offset)
  let params = add_optional_int_param(params, "recipe_id", recipe_id)
  params
}

/// Build shopping list item filter parameters
///
/// Builds parameters for filtering shopping list items by status (checked/unchecked)
/// and optional category grouping.
///
/// # Arguments
/// * `limit` - Optional page size
/// * `offset` - Optional skip count
/// * `checked` - Optional filter for checked status (Some(True)=checked, Some(False)=unchecked, None=all)
/// * `category_id` - Optional filter by category
///
/// # Returns
/// List of query parameters
///
/// # Example
/// ```gleam
/// build_shopping_list_item_params(Some(50), Some(0), Some(False), None)
/// // => [#("checked", "false"), #("offset", "0"), #("limit", "50")]
/// ```
pub fn build_shopping_list_item_params(
  limit: Option(Int),
  offset: Option(Int),
  checked: Option(Bool),
  category_id: Option(Int),
) -> List(#(String, String)) {
  let params = []
  let params = add_optional_int_param(params, "limit", limit)
  let params = add_optional_int_param(params, "offset", offset)
  let params = case checked {
    Some(True) -> [#("checked", "true"), ..params]
    Some(False) -> [#("checked", "false"), ..params]
    None -> params
  }
  let params = add_optional_int_param(params, "category_id", category_id)
  params
}

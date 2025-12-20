//// Consolidated query builder and parameter parsing module
////
//// This module consolidates common query parameter parsing and pagination
//// logic used across multiple HTTP handlers. Previously duplicated in:
//// - foods/handlers.gleam
//// - exercise/handlers.gleam
//// - recipes/handlers.gleam
//// - favorites/handlers.gleam
////
//// Provides:
//// - Pagination parameter extraction and validation
//// - Filter parameter building
//// - Query parameter merging
//// - Limit clamping and normalization
//// Represents pagination parameters for list queries
//// Represents query result with pagination metadata
//// Build pagination parameters from raw query parameters
//// - limit: clamped to range [1, max_limit]
//// - offset: clamped to >= 0
////
//// ## Example
//// ```gleam
//// let params = build_pagination(query_params, limit: 20, max_limit: 50)
//// // Returns: PaginationParams(limit: 20, offset: 0)
//// ```
//// Specialized pagination builder for page-based queries (page + max_results)
//// Converts page number to offset using formula: offset = page * max_results
////
//// ## Example
//// ```gleam
//// let params = build_page_pagination(Some(2), Some(20), max_limit: 50)
//// // Returns: PaginationParams(limit: 20, offset: 40)
//// ```
//// Clamp an integer value to a specified range [min, max]
//// Parse optional integer from query parameters list
//// Returns None if parameter not found or cannot be parsed as int
//// Get string parameter from query parameters list
//// Returns Option(String) - None if not found
//// Build URL query string from filter pairs
//// Filters out empty values
////
//// ## Example
//// ```gleam
//// let filters = [#("status", "active"), #("type", "")]
//// build_filter_string(filters)
//// // Returns: "status=active"
//// ```
//// Merge base query parameters with additional parameters
//// Later parameters override earlier ones with the same key
////
//// ## Example
//// ```gleam
//// let base = [#("page", "1"), #("limit", "20")]
//// let additional = [#("page", "2")]
//// merge_query_params(base, additional)
//// // Returns: [#("page", "2"), #("limit", "20")]
//// ```
//// Add pagination parameters to existing query string
//// Returns a new query string with pagination params merged in
////
//// ## Example
//// ```gleam
//// let query = "search=banana&type=food"
//// let result = add_pagination_to_query(query, limit: 20, offset: 0)
//// // Returns: "search=banana&type=food&limit=20&offset=0"
//// ```
//// Build next/previous pagination links for API responses
////
//// ## Example
//// ```gleam
//// let links = build_pagination_links(
////   base_url: "/api/foods/search?q=banana",
////   limit: 20,
////   offset: 40,
////   total_count: 100,
//// )
//// // Returns: Some(#(next: "...", prev: "..."))
//// ```

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

// =============================================================================
// Pagination Types
// =============================================================================

pub type PaginationParams {
  PaginationParams(limit: Int, offset: Int)
}

pub type PaginatedResponse(item) {
  PaginatedResponse(
    items: List(item),
    total_count: Int,
    limit: Int,
    offset: Int,
  )
}

// =============================================================================
// Pagination Builders
// =============================================================================

pub fn build_pagination(
  limit: Option(Int),
  offset: Option(Int),
  max_limit: Int,
) -> PaginationParams {
  let clamped_limit =
    limit
    |> option.unwrap(20)
    |> clamp_limit(1, max_limit)

  let clamped_offset =
    offset
    |> option.unwrap(0)
    |> int.max(0)

  PaginationParams(limit: clamped_limit, offset: clamped_offset)
}

pub fn build_page_pagination(
  page: Option(Int),
  max_results: Option(Int),
  max_limit: Int,
) -> PaginationParams {
  let clamped_limit =
    max_results
    |> option.unwrap(20)
    |> clamp_limit(1, max_limit)

  let page_num = page |> option.unwrap(0) |> int.max(0)
  let offset = page_num * clamped_limit

  PaginationParams(limit: clamped_limit, offset: offset)
}

// =============================================================================
// Parameter Parsing Helpers
// =============================================================================

pub fn clamp_limit(value: Int, min: Int, max: Int) -> Int {
  case value {
    _ if value < min -> min
    _ if value > max -> max
    _ -> value
  }
}

pub fn parse_int_parameter(
  params: List(#(String, String)),
  key: String,
) -> Option(Int) {
  params
  |> list.key_find(key)
  |> result.try(int.parse)
  |> option.from_result
}

pub fn get_string_parameter(
  params: List(#(String, String)),
  key: String,
) -> Option(String) {
  params
  |> list.key_find(key)
  |> option.from_result
}

// =============================================================================
// Filter Building (for advanced filtering)
// =============================================================================

pub fn build_filter_string(filters: List(#(String, String))) -> String {
  filters
  |> list.filter(fn(pair) { string.length(pair.1) > 0 })
  |> list.map(fn(pair) { pair.0 <> "=" <> pair.1 })
  |> string.join("&")
}

pub fn merge_query_params(
  base: List(#(String, String)),
  additional: List(#(String, String)),
) -> List(#(String, String)) {
  // Build a map of keys from additional params for quick lookup
  let additional_keys =
    additional
    |> list.map(fn(pair) { pair.0 })
    |> list.unique

  // Start with additional params
  let merged = additional

  // Add base params that aren't overridden
  let result =
    base
    |> list.filter(fn(pair) { !list.contains(additional_keys, pair.0) })
    |> list.append(merged, _)

  result
}

pub fn add_pagination_to_query(
  query: String,
  pagination: PaginationParams,
) -> String {
  let pagination_suffix =
    "&limit="
    <> int.to_string(pagination.limit)
    <> "&offset="
    <> int.to_string(pagination.offset)

  case string.is_empty(query) {
    True -> string.drop_start(pagination_suffix, 1)
    False -> query <> pagination_suffix
  }
}

// =============================================================================
// Response Building Helpers
// =============================================================================

pub fn build_pagination_links(
  base_url: String,
  limit: Int,
  offset: Int,
  total_count: Int,
) -> Option(#(Option(String), Option(String))) {
  let has_next = offset + limit < total_count
  let has_prev = offset > 0

  let next_url = case has_next {
    True ->
      Some(
        base_url
        <> "&offset="
        <> int.to_string(offset + limit)
        <> "&limit="
        <> int.to_string(limit),
      )
    False -> None
  }

  let prev_url = case has_prev {
    True ->
      Some(
        base_url
        <> "&offset="
        <> int.to_string(int.max(0, offset - limit))
        <> "&limit="
        <> int.to_string(limit),
      )
    False -> None
  }

  Some(#(next_url, prev_url))
}

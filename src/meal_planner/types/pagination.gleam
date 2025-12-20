/// Pagination types and operations
///
/// Cursor-based pagination support for large result sets.
/// Pagination cursor - opaque string representing position in result set
pub opaque type Cursor {
  Cursor(value: String)
}

/// Pagination parameters for a request
/// Opaque type ensures limit is validated
pub opaque type PaginationParams {
  PaginationParams(
    limit: Int,
    // Number of items to return (capped at max_limit)
    cursor: option.Option(Cursor),
    // Optional cursor for continuing pagination
  )
}

/// Create PaginationParams with validation
/// Limit must be between 1 and max_limit
pub fn new_pagination_params(
  limit: Int,
  cursor: option.Option(Cursor),
) -> Result(PaginationParams, String) {
  let max_limit = 100
  case limit < 1 || limit > max_limit {
    True ->
      Error(
        "Pagination limit must be between 1 and "
        <> int.to_string(max_limit)
        <> ", got: "
        <> int.to_string(limit),
      )
    False -> Ok(PaginationParams(limit: limit, cursor: cursor))
  }
}

/// Get the limit from pagination parameters
pub fn pagination_limit(params: PaginationParams) -> Int {
  params.limit
}

/// Get the cursor from pagination parameters
pub fn pagination_cursor(params: PaginationParams) -> option.Option(Cursor) {
  params.cursor
}

/// Create a cursor from a string value
pub fn new_cursor(value: String) -> Result(Cursor, String) {
  case string.length(value) {
    0 -> Error("Cursor cannot be empty")
    _ -> Ok(Cursor(value: value))
  }
}

/// Get the string value from a cursor
pub fn cursor_value(c: Cursor) -> String {
  c.value
}

/// Metadata for pagination response
pub opaque type PageInfo {
  PageInfo(
    has_next: Bool,
    // Whether more results exist
    has_previous: Bool,
    // Whether there are previous results
    next_cursor: option.Option(Cursor),
    // Cursor for next page
    previous_cursor: option.Option(Cursor),
    // Cursor for previous page
    total_items: Int,
    // Total count of items available
  )
}

/// Create PageInfo with validation
/// total_items must be non-negative
pub fn new_page_info(
  has_next: Bool,
  has_previous: Bool,
  next_cursor: option.Option(Cursor),
  previous_cursor: option.Option(Cursor),
  total_items: Int,
) -> Result(PageInfo, String) {
  case total_items < 0 {
    True ->
      Error(
        "Total items cannot be negative, got: " <> int.to_string(total_items),
      )
    False ->
      Ok(PageInfo(
        has_next: has_next,
        has_previous: has_previous,
        next_cursor: next_cursor,
        previous_cursor: previous_cursor,
        total_items: total_items,
      ))
  }
}

/// Get has_next flag from page info
pub fn page_info_has_next(info: PageInfo) -> Bool {
  info.has_next
}

/// Get has_previous flag from page info
pub fn page_info_has_previous(info: PageInfo) -> Bool {
  info.has_previous
}

/// Get next cursor from page info
pub fn page_info_next_cursor(info: PageInfo) -> option.Option(Cursor) {
  info.next_cursor
}

/// Get previous cursor from page info
pub fn page_info_previous_cursor(info: PageInfo) -> option.Option(Cursor) {
  info.previous_cursor
}

/// Get total items count from page info
pub fn page_info_total_items(info: PageInfo) -> Int {
  info.total_items
}

/// Paginated response wrapper for generic items
pub type PaginatedResponse(item_type) {
  PaginatedResponse(items: List(item_type), page_info: PageInfo)
}

import gleam/int
import gleam/option
import gleam/string

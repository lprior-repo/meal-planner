/// Pagination types and operations
///
/// Cursor-based pagination support for large result sets.

/// Pagination cursor - opaque string representing position in result set
pub type Cursor =
  String

/// Pagination parameters for a request
pub type PaginationParams {
  PaginationParams(
    limit: Int,
    // Number of items to return (capped at max_limit)
    cursor: option.Option(Cursor),
    // Optional cursor for continuing pagination
  )
}

/// Metadata for pagination response
pub type PageInfo {
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

/// Paginated response wrapper for generic items
pub type PaginatedResponse(item_type) {
  PaginatedResponse(items: List(item_type), page_info: PageInfo)
}

import gleam/option

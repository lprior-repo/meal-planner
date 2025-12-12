/// Cursor-based pagination module
/// Provides reusable types and functions for implementing cursor-based pagination
/// across API endpoints.

import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

// ============================================================================
// Pagination Types
// ============================================================================

/// Pagination cursor - opaque string representing position in result set
pub type Cursor =
  String

/// Pagination parameters for a request
pub type PaginationParams {
  PaginationParams(
    limit: Int,
    // Number of items to return (capped at max_limit)
    cursor: Option(Cursor),
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
    next_cursor: Option(Cursor),
    // Cursor for next page
    previous_cursor: Option(Cursor),
    // Cursor for previous page
    total_items: Int,
    // Total count of items available
  )
}

/// Paginated response wrapper
pub type PaginatedResponse(item_type) {
  PaginatedResponse(items: List(item_type), page_info: PageInfo)
}

// ============================================================================
// Cursor Encoding/Decoding
// ============================================================================

/// Default maximum limit per page
pub const default_max_limit = 100

/// Minimum limit per page
pub const min_limit = 1

/// Create a cursor from an integer offset
/// This uses a simple base64-like encoding that's URL-safe
pub fn encode_cursor(offset: Int) -> Cursor {
  let offset_str = int.to_string(offset)
  "offset:" <> offset_str
}

/// Decode a cursor to get the integer offset
/// Returns error if cursor is malformed
pub fn decode_cursor(cursor: Cursor) -> Result(Int, String) {
  case string.split(cursor, ":") {
    ["offset", offset_str] -> {
      case int.parse(offset_str) {
        Ok(offset) if offset >= 0 -> Ok(offset)
        Ok(_) -> Error("Offset must be non-negative")
        Error(_) -> Error("Invalid offset format")
      }
    }
    _ -> Error("Invalid cursor format")
  }
}

// ============================================================================
// Pagination Logic
// ============================================================================

/// Validate and normalize pagination parameters
pub fn validate_params(
  limit: Int,
  cursor: Option(Cursor),
) -> Result(#(Int, Int), String) {
  // Validate limit is within acceptable range
  let validated_limit = case limit {
    l if l < min_limit -> min_limit
    l if l > default_max_limit -> default_max_limit
    l -> l
  }

  // Decode cursor to get offset
  let offset = case cursor {
    None -> Ok(0)
    Some(c) -> decode_cursor(c)
  }

  result.map(offset, fn(offset) { #(validated_limit, offset) })
}

/// Calculate next cursor if results continue beyond current page
pub fn next_cursor(
  current_offset: Int,
  limit: Int,
  result_count: Int,
) -> Option(Cursor) {
  case result_count >= limit {
    True -> Some(encode_cursor(current_offset + limit))
    False -> None
  }
}

/// Calculate previous cursor if not at start
pub fn previous_cursor(
  current_offset: Int,
  limit: Int,
) -> Option(Cursor) {
  case current_offset >= limit {
    True -> Some(encode_cursor(int.max(0, current_offset - limit)))
    False -> None
  }
}

/// Create PageInfo from pagination metadata
pub fn create_page_info(
  current_offset: Int,
  limit: Int,
  result_count: Int,
  total_count: Int,
) -> PageInfo {
  let has_next = result_count >= limit
  let has_prev = current_offset > 0
  let next = next_cursor(current_offset, limit, result_count)
  let prev = previous_cursor(current_offset, limit)

  PageInfo(
    has_next:,
    has_previous: has_prev,
    next_cursor: next,
    previous_cursor: prev,
    total_items: total_count,
  )
}

// ============================================================================
// JSON Encoding
// ============================================================================

/// Encode PageInfo to JSON
pub fn page_info_to_json(page_info: PageInfo) -> Json {
  json.object([
    #("has_next", json.bool(page_info.has_next)),
    #("has_previous", json.bool(page_info.has_previous)),
    #(
      "next_cursor",
      case page_info.next_cursor {
        Some(cursor) -> json.string(cursor)
        None -> json.null()
      },
    ),
    #(
      "previous_cursor",
      case page_info.previous_cursor {
        Some(cursor) -> json.string(cursor)
        None -> json.null()
      },
    ),
    #("total_items", json.int(page_info.total_items)),
  ])
}

/// Encode a paginated response to JSON with custom item encoder
pub fn paginated_response_to_json(
  response: PaginatedResponse(a),
  item_encoder: fn(a) -> Json,
) -> Json {
  json.object([
    #("items", json.array(response.items, item_encoder)),
    #("pagination", page_info_to_json(response.page_info)),
  ])
}

// ============================================================================
// Query String Parsing
// ============================================================================

/// Parse pagination parameters from query string
pub fn parse_query_params(
  limit_str: Option(String),
  cursor_str: Option(String),
) -> Result(PaginationParams, String) {
  // Parse limit
  let limit = case limit_str {
    None -> Ok(default_max_limit)
    Some(l_str) -> {
      case int.parse(l_str) {
        Ok(l) -> Ok(l)
        Error(_) -> Error("Invalid limit parameter")
      }
    }
  }

  // Validate cursor format if provided
  let cursor = case cursor_str {
    None -> Ok(None)
    Some(c) -> {
      case decode_cursor(c) {
        Ok(_) -> Ok(Some(c))
        Error(e) -> Error("Invalid cursor: " <> e)
      }
    }
  }

  use limit_val <- result.try(limit)
  use cursor_val <- result.try(cursor)
  Ok(PaginationParams(limit: limit_val, cursor: cursor_val))
}

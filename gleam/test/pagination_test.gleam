/// Tests for cursor-based pagination module
///
/// Verifies:
/// 1. Cursor encoding and decoding
/// 2. Pagination parameter validation
/// 3. PageInfo creation
/// 4. Query parameter parsing
/// 5. Edge cases (boundaries, invalid inputs)

import gleeunit
import gleeunit/should
import gleam/list
import gleam/option.{None, Some}
import meal_planner/pagination

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Cursor Encoding/Decoding Tests
// ============================================================================

pub fn test_encode_cursor_zero() {
  let cursor = pagination.encode_cursor(0)
  cursor |> should.equal("offset:0")
}

pub fn test_encode_cursor_positive() {
  let cursor = pagination.encode_cursor(100)
  cursor |> should.equal("offset:100")
}

pub fn test_encode_cursor_large_number() {
  let cursor = pagination.encode_cursor(999_999)
  cursor |> should.equal("offset:999999")
}

pub fn test_decode_cursor_success() {
  let result = pagination.decode_cursor("offset:42")
  result |> should.equal(Ok(42))
}

pub fn test_decode_cursor_zero() {
  let result = pagination.decode_cursor("offset:0")
  result |> should.equal(Ok(0))
}

pub fn test_decode_cursor_large_number() {
  let result = pagination.decode_cursor("offset:999999")
  result |> should.equal(Ok(999_999))
}

pub fn test_decode_cursor_invalid_format() {
  let result = pagination.decode_cursor("invalid:cursor")
  result |> should.be_error()
}

pub fn test_decode_cursor_negative() {
  let result = pagination.decode_cursor("offset:-5")
  result |> should.be_error()
}

pub fn test_decode_cursor_non_numeric() {
  let result = pagination.decode_cursor("offset:abc")
  result |> should.be_error()
}

pub fn test_decode_cursor_malformed() {
  let result = pagination.decode_cursor("random-string")
  result |> should.be_error()
}

pub fn test_encode_decode_roundtrip() {
  let original = 42
  let cursor = pagination.encode_cursor(original)
  let decoded = pagination.decode_cursor(cursor)
  decoded |> should.equal(Ok(original))
}

// ============================================================================
// Pagination Parameters Validation
// ============================================================================

pub fn test_validate_params_default_limit() {
  let result = pagination.validate_params(20, None)
  result |> should.equal(Ok(#(20, 0)))
}

pub fn test_validate_params_with_cursor() {
  let result = pagination.validate_params(20, Some("offset:100"))
  result |> should.equal(Ok(#(20, 100)))
}

pub fn test_validate_params_limit_too_high() {
  let result = pagination.validate_params(500, None)
  result |> should.equal(Ok(#(pagination.default_max_limit, 0)))
}

pub fn test_validate_params_limit_too_low() {
  let result = pagination.validate_params(0, None)
  result |> should.equal(Ok(#(pagination.min_limit, 0)))
}

pub fn test_validate_params_negative_limit() {
  let result = pagination.validate_params(-10, None)
  result |> should.equal(Ok(#(pagination.min_limit, 0)))
}

pub fn test_validate_params_invalid_cursor() {
  let result = pagination.validate_params(20, Some("invalid"))
  result |> should.be_error()
}

pub fn test_validate_params_at_max_limit() {
  let result = pagination.validate_params(pagination.default_max_limit, None)
  result |> should.equal(Ok(#(pagination.default_max_limit, 0)))
}

pub fn test_validate_params_at_min_limit() {
  let result = pagination.validate_params(pagination.min_limit, None)
  result |> should.equal(Ok(#(pagination.min_limit, 0)))
}

// ============================================================================
// Cursor Calculation Tests
// ============================================================================

pub fn test_next_cursor_with_full_page() {
  let cursor = pagination.next_cursor(0, 20, 20)
  cursor |> should.equal(Some("offset:20"))
}

pub fn test_next_cursor_with_partial_page() {
  let cursor = pagination.next_cursor(20, 20, 15)
  cursor |> should.equal(None)
}

pub fn test_next_cursor_middle_page() {
  let cursor = pagination.next_cursor(40, 20, 20)
  cursor |> should.equal(Some("offset:60"))
}

pub fn test_next_cursor_empty_results() {
  let cursor = pagination.next_cursor(0, 20, 0)
  cursor |> should.equal(None)
}

pub fn test_previous_cursor_at_start() {
  let cursor = pagination.previous_cursor(0, 20)
  cursor |> should.equal(None)
}

pub fn test_previous_cursor_first_page() {
  let cursor = pagination.previous_cursor(19, 20)
  cursor |> should.equal(None)
}

pub fn test_previous_cursor_second_page() {
  let cursor = pagination.previous_cursor(20, 20)
  cursor |> should.equal(Some("offset:0"))
}

pub fn test_previous_cursor_middle() {
  let cursor = pagination.previous_cursor(50, 20)
  cursor |> should.equal(Some("offset:30"))
}

pub fn test_previous_cursor_exact_boundary() {
  let cursor = pagination.previous_cursor(40, 20)
  cursor |> should.equal(Some("offset:20"))
}

// ============================================================================
// PageInfo Creation Tests
// ============================================================================

pub fn test_create_page_info_first_page() {
  let page_info = pagination.create_page_info(0, 20, 20, 100)
  page_info.has_next |> should.be_true()
  page_info.has_previous |> should.be_false()
  page_info.next_cursor |> should.equal(Some("offset:20"))
  page_info.previous_cursor |> should.equal(None)
  page_info.total_items |> should.equal(100)
}

pub fn test_create_page_info_middle_page() {
  let page_info = pagination.create_page_info(20, 20, 20, 100)
  page_info.has_next |> should.be_true()
  page_info.has_previous |> should.be_true()
  page_info.next_cursor |> should.equal(Some("offset:40"))
  page_info.previous_cursor |> should.equal(Some("offset:0"))
  page_info.total_items |> should.equal(100)
}

pub fn test_create_page_info_last_page() {
  let page_info = pagination.create_page_info(80, 20, 20, 100)
  page_info.has_next |> should.be_false()
  page_info.has_previous |> should.be_true()
  page_info.next_cursor |> should.equal(None)
  page_info.previous_cursor |> should.equal(Some("offset:60"))
  page_info.total_items |> should.equal(100)
}

pub fn test_create_page_info_single_item() {
  let page_info = pagination.create_page_info(0, 20, 1, 1)
  page_info.has_next |> should.be_false()
  page_info.has_previous |> should.be_false()
  page_info.next_cursor |> should.equal(None)
  page_info.previous_cursor |> should.equal(None)
  page_info.total_items |> should.equal(1)
}

pub fn test_create_page_info_empty_results() {
  let page_info = pagination.create_page_info(0, 20, 0, 0)
  page_info.has_next |> should.be_false()
  page_info.has_previous |> should.be_false()
  page_info.next_cursor |> should.equal(None)
  page_info.previous_cursor |> should.equal(None)
  page_info.total_items |> should.equal(0)
}

pub fn test_create_page_info_partial_last_page() {
  let page_info = pagination.create_page_info(80, 20, 5, 85)
  page_info.has_next |> should.be_false()
  page_info.has_previous |> should.be_true()
  page_info.next_cursor |> should.equal(None)
  page_info.previous_cursor |> should.equal(Some("offset:60"))
  page_info.total_items |> should.equal(85)
}

// ============================================================================
// Query Parameter Parsing Tests
// ============================================================================

pub fn test_parse_query_params_no_params() {
  let result = pagination.parse_query_params(None, None)
  case result {
    Ok(params) -> {
      params.limit |> should.equal(pagination.default_max_limit)
      params.cursor |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_parse_query_params_with_limit() {
  let result = pagination.parse_query_params(Some("50"), None)
  case result {
    Ok(params) -> {
      params.limit |> should.equal(50)
      params.cursor |> should.equal(None)
    }
    Error(_) -> should.fail()
  }
}

pub fn test_parse_query_params_with_cursor() {
  let result = pagination.parse_query_params(None, Some("offset:100"))
  case result {
    Ok(params) -> {
      params.limit |> should.equal(pagination.default_max_limit)
      params.cursor |> should.equal(Some("offset:100"))
    }
    Error(_) -> should.fail()
  }
}

pub fn test_parse_query_params_both() {
  let result = pagination.parse_query_params(Some("30"), Some("offset:60"))
  case result {
    Ok(params) -> {
      params.limit |> should.equal(30)
      params.cursor |> should.equal(Some("offset:60"))
    }
    Error(_) -> should.fail()
  }
}

pub fn test_parse_query_params_invalid_limit() {
  let result = pagination.parse_query_params(Some("invalid"), None)
  result |> should.be_error()
}

pub fn test_parse_query_params_invalid_cursor() {
  let result = pagination.parse_query_params(None, Some("bad-cursor"))
  result |> should.be_error()
}

pub fn test_parse_query_params_limit_validation() {
  let result = pagination.parse_query_params(Some("500"), None)
  case result {
    Ok(params) -> {
      params.limit |> should.equal(pagination.default_max_limit)
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Edge Cases and Boundary Tests
// ============================================================================

pub fn test_cursor_encode_decode_consistency() {
  let offsets = [0, 1, 10, 100, 1000, 10_000, 100_000]
  let results = offsets
    |> list.map(fn(offset) {
      let cursor = pagination.encode_cursor(offset)
      let decoded = pagination.decode_cursor(cursor)
      case decoded {
        Ok(d) -> d == offset
        Error(_) -> False
      }
    })
  results |> should.all(fn(b) { b })
}

pub fn test_page_info_consistency() {
  let offset = 20
  let limit = 10
  let result_count = 10
  let total = 100

  let page_info = pagination.create_page_info(offset, limit, result_count, total)
  page_info.has_next
    |> should.equal(result_count >= limit)
}

pub fn test_validate_preserves_values_in_range() {
  let result = pagination.validate_params(50, Some("offset:25"))
  result |> should.equal(Ok(#(50, 25)))
}

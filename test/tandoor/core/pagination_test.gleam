/// Tests for Tandoor Pagination Utilities
///
/// Tests pagination response parsing, page navigation helpers,
/// and query parameter extraction from paginated URLs.
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/core/pagination

// ============================================================================
// PaginatedResponse Tests
// ============================================================================

pub fn test_has_next_page_when_next_is_some() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://example.com/api/recipe/?limit=10&offset=10"),
      previous: None,
      results: [],
    )

  pagination.has_next_page(response)
  |> should.be_true
}

pub fn test_has_next_page_when_next_is_none() {
  let response =
    pagination.PaginatedResponse(
      count: 10,
      next: None,
      previous: None,
      results: [],
    )

  pagination.has_next_page(response)
  |> should.be_false
}

pub fn test_has_previous_page_when_previous_is_some() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: None,
      previous: Some("http://example.com/api/recipe/?limit=10&offset=0"),
      results: [],
    )

  pagination.has_previous_page(response)
  |> should.be_true
}

pub fn test_has_previous_page_when_previous_is_none() {
  let response =
    pagination.PaginatedResponse(
      count: 10,
      next: None,
      previous: None,
      results: [],
    )

  pagination.has_previous_page(response)
  |> should.be_false
}

// ============================================================================
// URL Parameter Parsing Tests
// ============================================================================

pub fn test_next_page_params_extracts_limit_and_offset() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://example.com/api/recipe/?limit=20&offset=40"),
      previous: None,
      results: [],
    )

  pagination.next_page_params(response)
  |> should.equal(Some(#(20, 40)))
}

pub fn test_next_page_params_returns_none_when_no_next() {
  let response =
    pagination.PaginatedResponse(
      count: 10,
      next: None,
      previous: None,
      results: [],
    )

  pagination.next_page_params(response)
  |> should.equal(None)
}

pub fn test_previous_page_params_extracts_limit_and_offset() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: None,
      previous: Some("http://example.com/api/recipe/?limit=10&offset=0"),
      results: [],
    )

  pagination.previous_page_params(response)
  |> should.equal(Some(#(10, 0)))
}

pub fn test_previous_page_params_returns_none_when_no_previous() {
  let response =
    pagination.PaginatedResponse(
      count: 10,
      next: None,
      previous: None,
      results: [],
    )

  pagination.previous_page_params(response)
  |> should.equal(None)
}

pub fn test_next_page_params_handles_query_with_trailing_slash() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://example.com/api/recipe/?limit=25&offset=50&"),
      previous: None,
      results: [],
    )

  pagination.next_page_params(response)
  |> should.equal(Some(#(25, 50)))
}

pub fn test_next_page_params_handles_query_with_extra_params() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some(
        "http://example.com/api/recipe/?limit=15&offset=30&difficulty=easy&author_id=5",
      ),
      previous: None,
      results: [],
    )

  pagination.next_page_params(response)
  |> should.equal(Some(#(15, 30)))
}

// ============================================================================
// Query String Building Tests
// ============================================================================

pub fn test_build_query_string_with_all_some_values() {
  let params = [
    #("limit", Some("10")),
    #("offset", Some("0")),
    #("filter", Some("active")),
  ]

  pagination.build_query_string(params)
  |> should.equal("limit=10&offset=0&filter=active")
}

pub fn test_build_query_string_with_mixed_values() {
  let params = [
    #("limit", Some("20")),
    #("offset", None),
    #("search", Some("recipe")),
  ]

  pagination.build_query_string(params)
  |> should.equal("limit=20&search=recipe")
}

pub fn test_build_query_string_with_all_none_values() {
  let params = [#("limit", None), #("offset", None), #("filter", None)]

  pagination.build_query_string(params)
  |> should.equal("")
}

pub fn test_build_query_string_with_empty_list() {
  let params = []

  pagination.build_query_string(params)
  |> should.equal("")
}

// ============================================================================
// PaginationParams to Query String Tests
// ============================================================================

pub fn test_pagination_params_to_query_with_both_values() {
  let params = pagination.PaginationParams(limit: Some(10), offset: Some(0))

  pagination.pagination_params_to_query(params)
  |> should.equal("limit=10&offset=0")
}

pub fn test_pagination_params_to_query_with_limit_only() {
  let params = pagination.PaginationParams(limit: Some(25), offset: None)

  pagination.pagination_params_to_query(params)
  |> should.equal("limit=25")
}

pub fn test_pagination_params_to_query_with_offset_only() {
  let params = pagination.PaginationParams(limit: None, offset: Some(50))

  pagination.pagination_params_to_query(params)
  |> should.equal("offset=50")
}

pub fn test_pagination_params_to_query_with_neither_value() {
  let params = pagination.PaginationParams(limit: None, offset: None)

  pagination.pagination_params_to_query(params)
  |> should.equal("")
}

pub fn test_pagination_params_to_query_with_large_numbers() {
  let params =
    pagination.PaginationParams(limit: Some(1000), offset: Some(50_000))

  pagination.pagination_params_to_query(params)
  |> should.equal("limit=1000&offset=50000")
}

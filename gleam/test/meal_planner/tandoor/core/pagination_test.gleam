import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/pagination

pub fn has_next_page_with_next_url_test() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=10&offset=10"),
      previous: None,
      results: [],
    )

  response
  |> pagination.has_next_page
  |> should.be_true
}

pub fn has_next_page_without_next_url_test() {
  let response =
    pagination.PaginatedResponse(
      count: 5,
      next: None,
      previous: Some("http://api.example.com/foods?limit=10&offset=0"),
      results: [],
    )

  response
  |> pagination.has_next_page
  |> should.be_false
}

pub fn has_previous_page_with_previous_url_test() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=10&offset=20"),
      previous: Some("http://api.example.com/foods?limit=10&offset=0"),
      results: [],
    )

  response
  |> pagination.has_previous_page
  |> should.be_true
}

pub fn has_previous_page_without_previous_url_test() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=10&offset=10"),
      previous: None,
      results: [],
    )

  response
  |> pagination.has_previous_page
  |> should.be_false
}

pub fn next_page_params_with_valid_url_test() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=10&offset=20"),
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(Some(#(10, 20)))
}

pub fn next_page_params_without_next_url_test() {
  let response =
    pagination.PaginatedResponse(
      count: 5,
      next: None,
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(None)
}

pub fn next_page_params_with_different_values_test() {
  let response =
    pagination.PaginatedResponse(
      count: 200,
      next: Some("http://api.example.com/foods?limit=50&offset=100"),
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(Some(#(50, 100)))
}

pub fn previous_page_params_with_valid_url_test() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=10&offset=30"),
      previous: Some("http://api.example.com/foods?limit=10&offset=10"),
      results: [],
    )

  response
  |> pagination.previous_page_params
  |> should.equal(Some(#(10, 10)))
}

pub fn previous_page_params_without_previous_url_test() {
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=10&offset=10"),
      previous: None,
      results: [],
    )

  response
  |> pagination.previous_page_params
  |> should.equal(None)
}

pub fn build_query_string_with_all_params_test() {
  let params = [#("limit", Some("10")), #("offset", Some("20"))]

  params
  |> pagination.build_query_string
  |> should.equal("limit=10&offset=20")
}

pub fn build_query_string_with_none_values_test() {
  let params = [
    #("limit", Some("10")),
    #("offset", None),
    #("filter", Some("vegetable")),
  ]

  params
  |> pagination.build_query_string
  |> should.equal("limit=10&filter=vegetable")
}

pub fn build_query_string_with_all_none_test() {
  let params = [#("limit", None), #("offset", None)]

  params
  |> pagination.build_query_string
  |> should.equal("")
}

pub fn build_query_string_empty_list_test() {
  let params = []

  params
  |> pagination.build_query_string
  |> should.equal("")
}

pub fn pagination_params_to_query_with_both_params_test() {
  let params = pagination.PaginationParams(limit: Some(25), offset: Some(50))

  params
  |> pagination.pagination_params_to_query
  |> should.equal("limit=25&offset=50")
}

pub fn pagination_params_to_query_with_limit_only_test() {
  let params = pagination.PaginationParams(limit: Some(25), offset: None)

  params
  |> pagination.pagination_params_to_query
  |> should.equal("limit=25")
}

pub fn pagination_params_to_query_with_offset_only_test() {
  let params = pagination.PaginationParams(limit: None, offset: Some(50))

  params
  |> pagination.pagination_params_to_query
  |> should.equal("offset=50")
}

pub fn pagination_params_to_query_with_neither_test() {
  let params = pagination.PaginationParams(limit: None, offset: None)

  params
  |> pagination.pagination_params_to_query
  |> should.equal("")
}

pub fn next_page_params_with_reordered_query_params_test() {
  // Test that parameter order doesn't matter
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?offset=20&limit=10"),
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(Some(#(10, 20)))
}

pub fn next_page_params_with_extra_query_params_test() {
  // Test that extra params are ignored
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some(
        "http://api.example.com/foods?limit=10&offset=20&search=chicken",
      ),
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(Some(#(10, 20)))
}

pub fn next_page_params_with_missing_limit_test() {
  // Should return None if limit is missing
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?offset=20"),
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(None)
}

pub fn next_page_params_with_missing_offset_test() {
  // Should return None if offset is missing
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=10"),
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(None)
}

pub fn next_page_params_with_invalid_url_test() {
  // Should return None for malformed URL
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("not a valid url"),
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(None)
}

pub fn next_page_params_with_non_numeric_values_test() {
  // Should return None if values aren't numbers
  let response =
    pagination.PaginatedResponse(
      count: 100,
      next: Some("http://api.example.com/foods?limit=abc&offset=xyz"),
      previous: None,
      results: [],
    )

  response
  |> pagination.next_page_params
  |> should.equal(None)
}

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/core/pagination.{
  type PageParams, type PaginatedResponse, PageParams, PaginatedResponse,
  paginated_decoder,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// PaginatedResponse Type Tests
// ============================================================================

pub fn paginated_response_creates_with_all_fields_test() {
  let response =
    PaginatedResponse(
      count: 42,
      next: Some("https://api.example.com/items?page=2"),
      previous: Some("https://api.example.com/items?page=1"),
      results: [1, 2, 3],
    )

  response.count
  |> should.equal(42)

  response.next
  |> should.equal(Some("https://api.example.com/items?page=2"))

  response.previous
  |> should.equal(Some("https://api.example.com/items?page=1"))

  response.results
  |> should.equal([1, 2, 3])
}

pub fn paginated_response_handles_none_pagination_test() {
  let response =
    PaginatedResponse(count: 10, next: None, previous: None, results: [
      "item1", "item2",
    ])

  response.count
  |> should.equal(10)

  response.next
  |> should.equal(None)

  response.previous
  |> should.equal(None)

  response.results
  |> list.length()
  |> should.equal(2)
}

pub fn paginated_response_handles_empty_results_test() {
  let response =
    PaginatedResponse(count: 0, next: None, previous: None, results: [])

  response.count
  |> should.equal(0)

  response.results
  |> should.equal([])
}

pub fn page_params_creates_with_page_and_size_test() {
  let params = PageParams(page: 1, page_size: 20)

  params.page
  |> should.equal(1)

  params.page_size
  |> should.equal(20)
}

// ============================================================================
// paginated_decoder Function Tests
// ============================================================================

pub fn paginated_decoder_decodes_complete_json_test() {
  let json_string =
    "{
    \"count\": 150,
    \"next\": \"https://api.example.com/items?page=2\",
    \"previous\": \"https://api.example.com/items?page=1\",
    \"results\": [1, 2, 3, 4, 5]
  }"

  let decoder = paginated_decoder(decode.int)

  case json.decode(json_string, decoder) {
    Ok(response) -> {
      response.count
      |> should.equal(150)

      response.next
      |> should.equal(Some("https://api.example.com/items?page=2"))

      response.previous
      |> should.equal(Some("https://api.example.com/items?page=1"))

      response.results
      |> should.equal([1, 2, 3, 4, 5])
    }
    Error(_) -> panic as "Expected successful decode"
  }
}

pub fn paginated_decoder_handles_null_pagination_test() {
  let json_string =
    "{
    \"count\": 25,
    \"next\": null,
    \"previous\": null,
    \"results\": [\"a\", \"b\", \"c\"]
  }"

  let decoder = paginated_decoder(decode.string)

  case json.decode(json_string, decoder) {
    Ok(response) -> {
      response.count
      |> should.equal(25)

      response.next
      |> should.equal(None)

      response.previous
      |> should.equal(None)

      response.results
      |> should.equal(["a", "b", "c"])
    }
    Error(_) -> panic as "Expected successful decode"
  }
}

pub fn paginated_decoder_handles_empty_results_test() {
  let json_string =
    "{
    \"count\": 0,
    \"next\": null,
    \"previous\": null,
    \"results\": []
  }"

  let decoder = paginated_decoder(decode.int)

  case json.decode(json_string, decoder) {
    Ok(response) -> {
      response.count
      |> should.equal(0)

      response.results
      |> should.equal([])
    }
    Error(_) -> panic as "Expected successful decode"
  }
}

pub fn paginated_decoder_fails_on_invalid_json_test() {
  let invalid_json = "{ invalid json }"

  let decoder = paginated_decoder(decode.int)

  case json.decode(invalid_json, decoder) {
    Ok(_) -> panic as "Expected decode to fail on invalid JSON"
    Error(_) -> Nil
  }
}

pub fn paginated_decoder_fails_on_missing_count_test() {
  let json_string =
    "{
    \"next\": null,
    \"previous\": null,
    \"results\": [1, 2, 3]
  }"

  let decoder = paginated_decoder(decode.int)

  case json.decode(json_string, decoder) {
    Ok(_) -> panic as "Expected decode to fail without count"
    Error(_) -> Nil
  }
}

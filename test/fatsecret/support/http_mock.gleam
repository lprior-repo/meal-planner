/// Mock HTTP client for testing FatSecret SDK
///
/// Provides a flexible mock system for simulating HTTP responses
/// without making actual network requests. Useful for:
/// - Unit testing API clients
/// - Testing error handling
/// - Simulating various API responses
/// - Verifying request parameters
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// HTTP response mock
pub type MockResponse {
  MockResponse(status: Int, headers: Dict(String, String), body: String)
}

/// Mock HTTP client that records calls and returns predefined responses
pub type MockHttpClient {
  MockHttpClient(
    // URL pattern -> response mapping
    responses: Dict(String, MockResponse),
    // List of all calls made (for verification)
    calls: List(MockCall),
    // Default response when no pattern matches
    default_response: Option(MockResponse),
  )
}

/// Record of an HTTP call
pub type MockCall {
  MockCall(
    method: String,
    url: String,
    headers: Dict(String, String),
    body: String,
  )
}

/// Create a new empty mock client
///
/// Example:
/// ```gleam
/// let client = http_mock.new()
/// ```
pub fn new() -> MockHttpClient {
  MockHttpClient(responses: dict.new(), calls: [], default_response: None)
}

/// Add an expected request/response pair
///
/// The url_pattern can be a partial match - any URL containing
/// this string will match.
///
/// Example:
/// ```gleam
/// client
/// |> expect("foods.search", json_response(200, "{...}"))
/// |> expect("food.get", json_response(200, "{...}"))
/// ```
pub fn expect(
  client: MockHttpClient,
  url_pattern: String,
  response: MockResponse,
) -> MockHttpClient {
  MockHttpClient(
    ..client,
    responses: dict.insert(client.responses, url_pattern, response),
  )
}

/// Set a default response for unmatched requests
///
/// Example:
/// ```gleam
/// client
/// |> set_default(error_response(404, "Not Found"))
/// ```
pub fn set_default(
  client: MockHttpClient,
  response: MockResponse,
) -> MockHttpClient {
  MockHttpClient(..client, default_response: Some(response))
}

/// Create a JSON response mock
///
/// Sets Content-Type header automatically.
///
/// Example:
/// ```gleam
/// json_response(200, "{\"food_id\": \"12345\"}")
/// ```
pub fn json_response(status: Int, body: String) -> MockResponse {
  MockResponse(
    status: status,
    headers: dict.from_list([
      #("Content-Type", "application/json"),
    ]),
    body: body,
  )
}

/// Create an error response mock
///
/// Returns FatSecret API error format.
///
/// Example:
/// ```gleam
/// error_response(101, "Missing required parameter: search_expression")
/// ```
pub fn error_response(code: Int, message: String) -> MockResponse {
  let body =
    "{\"error\": {\"code\": "
    <> string.inspect(code)
    <> ", \"message\": \""
    <> message
    <> "\"}}"

  json_response(200, body)
}

/// Create a network error response (non-200 status)
///
/// Example:
/// ```gleam
/// network_error(500, "Internal Server Error")
/// ```
pub fn network_error(status: Int, message: String) -> MockResponse {
  MockResponse(status: status, headers: dict.new(), body: message)
}

/// Record a call and return the matching response
///
/// This is called by the mock HTTP implementation to simulate
/// making a request.
///
/// Returns Ok(MockResponse) if a pattern matches, Error otherwise.
pub fn make_request(
  client: MockHttpClient,
  method: String,
  url: String,
  headers: Dict(String, String),
  body: String,
) -> Result(#(MockHttpClient, MockResponse), String) {
  // Record the call
  let call = MockCall(method: method, url: url, headers: headers, body: body)
  let updated_client = MockHttpClient(..client, calls: [call, ..client.calls])

  // Find matching response
  case find_response(client, url) {
    Some(response) -> Ok(#(updated_client, response))
    None -> Error("No mock response configured for URL: " <> url)
  }
}

/// Find a response matching the URL
fn find_response(client: MockHttpClient, url: String) -> Option(MockResponse) {
  // Try to find a pattern that matches
  let matching_response =
    client.responses
    |> dict.to_list
    |> list.find(fn(pair) {
      let #(pattern, _response) = pair
      string.contains(url, pattern)
    })

  case matching_response {
    Ok(#(_pattern, response)) -> Some(response)
    Error(_) -> client.default_response
  }
}

/// Get all recorded calls
///
/// Useful for verifying that expected requests were made.
///
/// Example:
/// ```gleam
/// let calls = get_calls(client)
/// calls
/// |> list.length
/// |> should.equal(3)
/// ```
pub fn get_calls(client: MockHttpClient) -> List(MockCall) {
  // Reverse to get chronological order
  list.reverse(client.calls)
}

/// Assert that a call was made matching the criteria
///
/// Returns True if a matching call was found, False otherwise.
///
/// Example:
/// ```gleam
/// client
/// |> assert_called("POST", "foods.search")
/// |> should.be_true
/// ```
pub fn assert_called(
  client: MockHttpClient,
  method: String,
  url_contains: String,
) -> Bool {
  client.calls
  |> list.any(fn(call) {
    call.method == method && string.contains(call.url, url_contains)
  })
}

/// Assert that a call was made with specific body content
///
/// Example:
/// ```gleam
/// client
/// |> assert_called_with_body("method=foods.search")
/// |> should.be_true
/// ```
pub fn assert_called_with_body(
  client: MockHttpClient,
  body_contains: String,
) -> Bool {
  client.calls
  |> list.any(fn(call) { string.contains(call.body, body_contains) })
}

/// Get the most recent call
///
/// Returns None if no calls have been made.
///
/// Example:
/// ```gleam
/// case get_last_call(client) {
///   Some(call) -> {
///     call.method |> should.equal("POST")
///     call.body |> should.contain("search_expression=apple")
///   }
///   None -> should.fail()
/// }
/// ```
pub fn get_last_call(client: MockHttpClient) -> Option(MockCall) {
  case client.calls {
    [last, ..] -> Some(last)
    [] -> None
  }
}

/// Clear all recorded calls
///
/// Useful for resetting between test cases.
///
/// Example:
/// ```gleam
/// let client = clear_calls(client)
/// ```
pub fn clear_calls(client: MockHttpClient) -> MockHttpClient {
  MockHttpClient(..client, calls: [])
}

/// Count how many calls were made
///
/// Example:
/// ```gleam
/// call_count(client) |> should.equal(5)
/// ```
pub fn call_count(client: MockHttpClient) -> Int {
  list.length(client.calls)
}

/// Mock HTTP Transport for Testing
///
/// This module provides a mock implementation of HttpTransport that can be
/// configured with expected requests and responses for unit testing.
import gleam/http as gleam_http
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/core/http.{
  type HttpRequest, type HttpResponse, type HttpTransport, HttpRequest,
  HttpResponse,
}

/// Request matcher function type
pub type RequestMatcher =
  fn(HttpRequest) -> Bool

/// Conditional response function type
pub type ConditionalResponse =
  fn(HttpRequest) -> Result(HttpResponse, String)

/// Mock transport configuration
pub type MockTransport {
  MockTransport(
    /// Expected request matcher (optional)
    request_matcher: Option(RequestMatcher),
    /// Static response to return
    response: Option(Result(HttpResponse, String)),
    /// Queue of responses for multiple calls
    response_queue: List(Result(HttpResponse, String)),
    /// Conditional response based on request
    conditional_response: Option(ConditionalResponse),
    /// Call history for verification
    call_history: List(HttpRequest),
  )
}

/// Create a new mock transport
pub fn new() -> MockTransport {
  MockTransport(
    request_matcher: None,
    response: None,
    response_queue: [],
    conditional_response: None,
    call_history: [],
  )
}

/// Set a static response
pub fn with_response(
  mock: MockTransport,
  response: HttpResponse,
) -> MockTransport {
  MockTransport(..mock, response: Some(Ok(response)))
}

/// Set an error response
pub fn with_error(mock: MockTransport, error: String) -> MockTransport {
  MockTransport(..mock, response: Some(Error(error)))
}

/// Add a request matcher
pub fn expect_request(
  mock: MockTransport,
  matcher: RequestMatcher,
) -> MockTransport {
  MockTransport(..mock, request_matcher: Some(matcher))
}

/// Queue a response (for multiple sequential calls)
pub fn queue_response(
  mock: MockTransport,
  response: HttpResponse,
) -> MockTransport {
  MockTransport(
    ..mock,
    response_queue: list.append(mock.response_queue, [Ok(response)]),
  )
}

/// Set a conditional response function
pub fn with_conditional_response(
  mock: MockTransport,
  responder: ConditionalResponse,
) -> MockTransport {
  MockTransport(..mock, conditional_response: Some(responder))
}

/// Execute a request using the mock transport
pub fn execute(
  mock: MockTransport,
  request: HttpRequest,
) -> Result(HttpResponse, String) {
  // Verify request matcher if present
  let matcher_ok = case mock.request_matcher {
    Some(matcher) -> matcher(request)
    None -> True
  }

  case matcher_ok {
    False -> Error("Request did not match expected pattern")
    True -> {
      // Determine which response to use
      case mock.conditional_response {
        // Conditional response takes precedence
        Some(responder) -> responder(request)
        None ->
          case mock.response_queue {
            // Use queued response if available
            [first, ..] -> first
            [] ->
              // Fall back to static response
              case mock.response {
                Some(resp) -> resp
                None -> Error("No response configured for mock transport")
              }
          }
      }
    }
  }
}

/// Convert mock transport to HttpTransport function type
pub fn as_transport(mock: MockTransport) -> HttpTransport {
  fn(request: HttpRequest) { execute(mock, request) }
}

/// Verify that the mock was called N times
pub fn verify_called(mock: MockTransport, expected_calls: Int) -> Bool {
  list.length(mock.call_history) == expected_calls
}

/// Verify that the mock was called with a specific method
pub fn verify_called_with_method(
  mock: MockTransport,
  method: gleam_http.Method,
) -> Bool {
  list.any(mock.call_history, fn(req) { req.method == method })
}

/// Verify that the mock was called with a specific URL
pub fn verify_called_with_url(mock: MockTransport, url: String) -> Bool {
  list.any(mock.call_history, fn(req) { req.url == url })
}

/// Get the call history
pub fn get_call_history(mock: MockTransport) -> List(HttpRequest) {
  mock.call_history
}

/// Record a request in call history (for internal use)
fn record_call(mock: MockTransport, request: HttpRequest) -> MockTransport {
  MockTransport(..mock, call_history: list.append(mock.call_history, [request]))
}

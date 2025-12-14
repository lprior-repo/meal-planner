import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/option.{type Option}
import gleam/result

/// HTTP request type containing method, URL, headers, and body
pub type HttpRequest {
  HttpRequest(
    method: http.Method,
    url: String,
    headers: List(#(String, String)),
    body: String,
  )
}

/// HTTP response type containing status, headers, and body
pub type HttpResponse {
  HttpResponse(status: Int, headers: List(#(String, String)), body: String)
}

/// HttpTransport is a function type that executes HTTP requests
/// This is designed to be injectable for testing purposes
pub type HttpTransport =
  fn(HttpRequest) -> Result(HttpResponse, String)

/// Creates the default HTTP transport using httpc
/// This is the production implementation that makes real HTTP calls
pub fn default_transport() -> HttpTransport {
  fn(http_request: HttpRequest) -> Result(HttpResponse, String) {
    // Build the request using gleam/http
    let req_result =
      request.to(http_request.url)
      |> result.map(fn(req) {
        req
        |> request.set_method(http_request.method)
        |> request.set_body(http_request.body)
        |> set_headers(http_request.headers)
      })

    // Handle request building errors
    use req <- result.try(
      req_result
      |> result.map_error(fn(_) { "Failed to build HTTP request" }),
    )

    // Execute the request
    use response <- result.try(
      httpc.send(req)
      |> result.map_error(fn(_) { "HTTP request failed" }),
    )

    // Convert response to our HttpResponse type
    Ok(HttpResponse(
      status: response.status,
      headers: response.headers,
      body: response.body,
    ))
  }
}

/// Helper function to set multiple headers on a request
fn set_headers(
  req: Request(String),
  headers: List(#(String, String)),
) -> Request(String) {
  list_fold_headers(headers, req)
}

/// Fold over headers and set each one
fn list_fold_headers(
  headers: List(#(String, String)),
  req: Request(String),
) -> Request(String) {
  case headers {
    [] -> req
    [#(key, value), ..rest] -> {
      let new_req = request.set_header(req, key, value)
      list_fold_headers(rest, new_req)
    }
  }
}

/// Execute an HTTP request using the provided transport
/// This function is the main entry point for executing requests
pub fn execute_request(
  transport: HttpTransport,
  http_request: HttpRequest,
) -> Result(HttpResponse, String) {
  transport(http_request)
}

// ============================================================================
// Pagination Types
// ============================================================================

/// Paginated response from Tandoor API
/// Generic type allows for different result types (recipes, foods, etc.)
pub type PaginatedResponse(a) {
  PaginatedResponse(
    /// Total count of items
    count: Int,
    /// URL to next page (if any)
    next: Option(String),
    /// URL to previous page (if any)
    previous: Option(String),
    /// List of results for this page
    results: List(a),
  )
}

/// Create a decoder for paginated responses
/// Takes a decoder for the result type and returns a decoder for PaginatedResponse
pub fn paginated_decoder(
  result_decoder: decode.Decoder(a),
) -> decode.Decoder(PaginatedResponse(a)) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field("results", decode.list(result_decoder))

  decode.success(PaginatedResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}

import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/option.{type Option}
import gleam/result

/// HTTP request body type - supports both text and binary data
pub type HttpBody {
  TextBody(String)
  BinaryBody(BitArray)
}

/// HTTP request type containing method, URL, headers, and body
pub type HttpRequest {
  HttpRequest(
    method: http.Method,
    url: String,
    headers: List(#(String, String)),
    body: HttpBody,
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
    // Convert body to string for httpc (it expects String bodies)
    let body_string = case http_request.body {
      TextBody(text) -> text
      BinaryBody(bytes) -> bit_array.base64_encode(bytes, False)
    }

    // Build the request using gleam/http
    let req_result =
      request.to(http_request.url)
      |> result.map(fn(req) {
        req
        |> request.set_method(http_request.method)
        |> request.set_body(body_string)
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
// Multipart/Form-Data Support
// ============================================================================

/// Execute HTTP request with binary body (for multipart/form-data uploads)
///
/// This function handles requests with binary data payloads, which are
/// necessary for file uploads via multipart/form-data encoding.
///
/// # Arguments
/// * `url` - Full URL for the request
/// * `method` - HTTP method (typically Post for uploads)
/// * `headers` - Request headers (must include Content-Type with boundary)
/// * `body` - Binary body data (encoded multipart form)
///
/// # Returns
/// Result with HttpResponse or error message
pub fn execute_binary_request(
  url: String,
  method: http.Method,
  headers: List(#(String, String)),
  body: BitArray,
) -> Result(HttpResponse, String) {
  // Build the request using gleam/http with BitArray body
  let req_result =
    request.to(url)
    |> result.map(fn(req) {
      req
      |> request.set_method(method)
      |> request.set_body(body)
      |> set_binary_headers(headers)
    })

  // Handle request building errors
  use req <- result.try(
    req_result
    |> result.map_error(fn(_) { "Failed to build HTTP request" }),
  )

  // Execute the request with binary body
  use response <- result.try(
    httpc.send_bits(req)
    |> result.map_error(fn(_) { "HTTP request failed" }),
  )

  // Convert binary response to string (assuming UTF-8)
  let body_string = case bit_array.to_string(response.body) {
    Ok(str) -> str
    Error(_) -> ""
  }

  // Convert response to our HttpResponse type
  Ok(HttpResponse(
    status: response.status,
    headers: response.headers,
    body: body_string,
  ))
}

/// Helper function to set multiple headers on a binary request
fn set_binary_headers(
  req: Request(BitArray),
  headers: List(#(String, String)),
) -> Request(BitArray) {
  list_fold_binary_headers(headers, req)
}

/// Fold over headers and set each one (binary body)
fn list_fold_binary_headers(
  headers: List(#(String, String)),
  req: Request(BitArray),
) -> Request(BitArray) {
  case headers {
    [] -> req
    [#(key, value), ..rest] -> {
      let new_req = request.set_header(req, key, value)
      list_fold_binary_headers(rest, new_req)
    }
  }
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

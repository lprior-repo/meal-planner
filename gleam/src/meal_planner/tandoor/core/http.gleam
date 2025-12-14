import gleam/http
import gleam/http/request.{type Request}
import gleam/httpc
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

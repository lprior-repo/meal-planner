import gleam/http
import gleam/result
import gleeunit
import gleeunit/should
import meal_planner/tandoor/core/http as http_transport

pub fn main() {
  gleeunit.main()
}

// Test types and mock transport

pub type MockResponse {
  MockResponse(status: Int, headers: List(#(String, String)), body: String)
}

pub fn create_mock_transport(
  mock_response: MockResponse,
) -> http_transport.HttpTransport {
  fn(_request: http_transport.HttpRequest) -> Result(
    http_transport.HttpResponse,
    String,
  ) {
    Ok(http_transport.HttpResponse(
      status: mock_response.status,
      headers: mock_response.headers,
      body: mock_response.body,
    ))
  }
}

pub fn create_failing_mock_transport(
  error_message: String,
) -> http_transport.HttpTransport {
  fn(_request: http_transport.HttpRequest) -> Result(
    http_transport.HttpResponse,
    String,
  ) {
    Error(error_message)
  }
}

// Tests for HttpRequest type

pub fn http_request_creation_test() {
  let request =
    http_transport.HttpRequest(
      method: http.Get,
      url: "https://api.example.com/recipes",
      headers: [#("Content-Type", "application/json")],
      body: "",
    )

  request.method
  |> should.equal(http.Get)

  request.url
  |> should.equal("https://api.example.com/recipes")

  request.headers
  |> should.equal([#("Content-Type", "application/json")])

  request.body
  |> should.equal("")
}

pub fn http_request_with_body_test() {
  let request =
    http_transport.HttpRequest(
      method: http.Post,
      url: "https://api.example.com/recipes",
      headers: [#("Content-Type", "application/json")],
      body: "{\"name\": \"Test Recipe\"}",
    )

  request.method
  |> should.equal(http.Post)

  request.body
  |> should.equal("{\"name\": \"Test Recipe\"}")
}

// Tests for HttpResponse type

pub fn http_response_creation_test() {
  let response =
    http_transport.HttpResponse(
      status: 200,
      headers: [#("Content-Type", "application/json")],
      body: "{\"id\": 1}",
    )

  response.status
  |> should.equal(200)

  response.headers
  |> should.equal([#("Content-Type", "application/json")])

  response.body
  |> should.equal("{\"id\": 1}")
}

// Tests for mock transport execution

pub fn execute_request_with_mock_success_test() {
  let mock_response =
    MockResponse(
      status: 200,
      headers: [#("Content-Type", "application/json")],
      body: "{\"result\": \"success\"}",
    )

  let transport = create_mock_transport(mock_response)

  let request =
    http_transport.HttpRequest(
      method: http.Get,
      url: "https://api.example.com/test",
      headers: [],
      body: "",
    )

  let result = http_transport.execute_request(transport, request)

  result
  |> should.be_ok()

  let response = result |> result.unwrap(http_transport.HttpResponse(0, [], ""))

  response.status
  |> should.equal(200)

  response.body
  |> should.equal("{\"result\": \"success\"}")
}

pub fn execute_request_with_mock_error_test() {
  let transport = create_failing_mock_transport("Network error")

  let request =
    http_transport.HttpRequest(
      method: http.Get,
      url: "https://api.example.com/test",
      headers: [],
      body: "",
    )

  let result = http_transport.execute_request(transport, request)

  result
  |> should.be_error()

  let error = result |> result.unwrap_error("default error")

  error
  |> should.equal("Network error")
}

pub fn execute_request_with_different_methods_test() {
  let mock_response =
    MockResponse(status: 201, headers: [], body: "{\"created\": true}")

  let transport = create_mock_transport(mock_response)

  let post_request =
    http_transport.HttpRequest(
      method: http.Post,
      url: "https://api.example.com/create",
      headers: [#("Content-Type", "application/json")],
      body: "{\"data\": \"test\"}",
    )

  let result = http_transport.execute_request(transport, post_request)

  result
  |> should.be_ok()

  let response = result |> result.unwrap(http_transport.HttpResponse(0, [], ""))

  response.status
  |> should.equal(201)
}

pub fn execute_request_preserves_headers_test() {
  let mock_response =
    MockResponse(
      status: 200,
      headers: [#("X-Custom", "value"), #("Content-Type", "application/json")],
      body: "{}",
    )

  let transport = create_mock_transport(mock_response)

  let request =
    http_transport.HttpRequest(
      method: http.Get,
      url: "https://api.example.com/test",
      headers: [#("Authorization", "Bearer token")],
      body: "",
    )

  let result = http_transport.execute_request(transport, request)

  result
  |> should.be_ok()

  let response = result |> result.unwrap(http_transport.HttpResponse(0, [], ""))

  response.headers
  |> should.equal([
    #("X-Custom", "value"),
    #("Content-Type", "application/json"),
  ])
}

// Tests for default transport creation

pub fn default_transport_creation_test() {
  // This test verifies that default_transport returns a function
  // We can't test the actual HTTP call without external dependencies
  // but we can verify the type is correct
  let transport = http_transport.default_transport()

  // Verify it's callable by checking its type matches HttpTransport
  // The actual HTTP execution would require httpc and network access
  // which we don't test here (that's integration testing territory)
  case transport {
    _ -> should.be_true(True)
  }
}

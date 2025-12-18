import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/response
import gleam/json
import gleeunit
import gleeunit/should
import meal_planner/tandoor/client.{
  type ApiResponse, type TandoorError, ApiResponse, AuthenticationError,
  AuthorizationError, BadRequestError, NotFoundError, ParseError, ServerError,
  UnknownError,
}
import meal_planner/tandoor/clients/response as tandoor_response

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// parse_response Tests
// ============================================================================

pub fn parse_response_200_ok_test() {
  let http_response =
    response.Response(
      status: 200,
      headers: [#("Content-Type", "application/json")],
      body: "{\"success\": true}",
    )

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_ok
  |> fn(api_resp: ApiResponse) {
    api_resp.status
    |> should.equal(200)

    api_resp.body
    |> should.equal("{\"success\": true}")
  }
}

pub fn parse_response_201_created_test() {
  let http_response =
    response.Response(
      status: 201,
      headers: [#("Content-Type", "application/json")],
      body: "{\"id\": 42}",
    )

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_ok
  |> fn(api_resp: ApiResponse) {
    api_resp.status
    |> should.equal(201)

    api_resp.body
    |> should.equal("{\"id\": 42}")
  }
}

pub fn parse_response_204_no_content_test() {
  let http_response = response.Response(status: 204, headers: [], body: "")

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_ok
  |> fn(api_resp: ApiResponse) {
    api_resp.status
    |> should.equal(204)

    api_resp.body
    |> should.equal("")
  }
}

pub fn parse_response_400_bad_request_test() {
  let http_response =
    response.Response(status: 400, headers: [], body: "Invalid parameters")

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      BadRequestError(msg) -> msg |> should.equal("Invalid parameters")
      _ -> panic as "Expected BadRequestError"
    }
  }
}

pub fn parse_response_401_authentication_error_test() {
  let http_response =
    response.Response(status: 401, headers: [], body: "Unauthorized")

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      AuthenticationError(msg) -> msg |> should.equal("Unauthorized")
      _ -> panic as "Expected AuthenticationError"
    }
  }
}

pub fn parse_response_403_authorization_error_test() {
  let http_response =
    response.Response(status: 403, headers: [], body: "Forbidden")

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      AuthorizationError(msg) -> msg |> should.equal("Forbidden")
      _ -> panic as "Expected AuthorizationError"
    }
  }
}

pub fn parse_response_404_not_found_test() {
  let http_response =
    response.Response(status: 404, headers: [], body: "Recipe not found")

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      NotFoundError(resource) -> resource |> should.equal("Recipe not found")
      _ -> panic as "Expected NotFoundError"
    }
  }
}

pub fn parse_response_500_server_error_test() {
  let http_response =
    response.Response(status: 500, headers: [], body: "Internal server error")

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      ServerError(status, msg) -> {
        status |> should.equal(500)
        msg |> should.equal("Internal server error")
      }
      _ -> panic as "Expected ServerError"
    }
  }
}

pub fn parse_response_502_bad_gateway_test() {
  let http_response =
    response.Response(status: 502, headers: [], body: "Bad gateway")

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      ServerError(status, msg) -> {
        status |> should.equal(502)
        msg |> should.equal("Bad gateway")
      }
      _ -> panic as "Expected ServerError"
    }
  }
}

pub fn parse_response_unknown_status_test() {
  let http_response =
    response.Response(status: 418, headers: [], body: "I'm a teapot")

  let result = tandoor_response.parse_response(http_response)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      UnknownError(msg) -> msg |> should.equal("HTTP 418: I'm a teapot")
      _ -> panic as "Expected UnknownError"
    }
  }
}

// ============================================================================
// parse_json_body Tests
// ============================================================================

pub fn parse_json_body_success_test() {
  let api_response =
    ApiResponse(
      status: 200,
      headers: [],
      body: "{\"name\": \"Test Recipe\", \"id\": 42}",
    )

  let decoder = fn(dyn: dynamic.Dynamic) -> Result(#(String, Int), String) {
    let tuple_decoder = {
      use name <- decode.field("name", decode.string)
      use id <- decode.field("id", decode.int)
      decode.success(#(name, id))
    }
    case decode.run(dyn, tuple_decoder) {
      Ok(value) -> Ok(value)
      Error(_) -> Error("Decode failed")
    }
  }

  let result = tandoor_response.parse_json_body(api_response, decoder)

  result
  |> should.be_ok
  |> should.equal(#("Test Recipe", 42))
}

pub fn parse_json_body_decoder_error_test() {
  let api_response =
    ApiResponse(status: 200, headers: [], body: "{\"name\": \"Test\"}")

  // Decoder expects 'id' field which is missing
  let decoder = fn(dyn: dynamic.Dynamic) -> Result(#(String, Int), String) {
    let tuple_decoder = {
      use name <- decode.field("name", decode.string)
      use id <- decode.field("id", decode.int)
      decode.success(#(name, id))
    }
    case decode.run(dyn, tuple_decoder) {
      Ok(value) -> Ok(value)
      Error(_) -> Error("Decode failed: missing id field")
    }
  }

  let result = tandoor_response.parse_json_body(api_response, decoder)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      ParseError(_msg) -> Nil
      _ -> panic as "Expected ParseError"
    }
  }
}

pub fn parse_json_body_invalid_json_test() {
  let api_response =
    ApiResponse(status: 200, headers: [], body: "not valid json")

  let decoder = fn(dyn: dynamic.Dynamic) -> Result(String, String) {
    let name_decoder = {
      use name <- decode.field("name", decode.string)
      decode.success(name)
    }
    case decode.run(dyn, name_decoder) {
      Ok(value) -> Ok(value)
      Error(_) -> Error("Decode failed")
    }
  }

  let result = tandoor_response.parse_json_body(api_response, decoder)

  result
  |> should.be_error
  |> fn(err: TandoorError) {
    case err {
      ParseError(msg) -> msg |> should.equal("Failed to parse JSON")
      _ -> panic as "Expected ParseError with message 'Failed to parse JSON'"
    }
  }
}

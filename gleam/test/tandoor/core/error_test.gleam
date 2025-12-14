import gleeunit
import gleeunit/should
import meal_planner/tandoor/core/error.{
  type TandoorError, AuthenticationError, AuthorizationError, BadRequestError,
  NetworkError, NotFoundError, ParseError, ServerError, TimeoutError,
  UnknownError, error_to_string,
}

pub fn main() {
  gleeunit.main()
}

// Test: AuthenticationError constructor
pub fn authentication_error_creates_variant_test() {
  let error = AuthenticationError

  case error {
    AuthenticationError -> True
    _ -> False
  }
  |> should.be_true()
}

// Test: AuthorizationError constructor
pub fn authorization_error_creates_variant_test() {
  let error = AuthorizationError

  case error {
    AuthorizationError -> True
    _ -> False
  }
  |> should.be_true()
}

// Test: NotFoundError with message
pub fn not_found_error_stores_message_test() {
  let error = NotFoundError("Recipe with ID 123 not found")

  case error {
    NotFoundError(msg) -> {
      msg
      |> should.equal("Recipe with ID 123 not found")
    }
    _ -> panic as "Expected NotFoundError variant"
  }
}

// Test: BadRequestError with message
pub fn bad_request_error_stores_message_test() {
  let error = BadRequestError("Invalid recipe data: missing name field")

  case error {
    BadRequestError(msg) -> {
      msg
      |> should.equal("Invalid recipe data: missing name field")
    }
    _ -> panic as "Expected BadRequestError variant"
  }
}

// Test: ServerError with status code and message
pub fn server_error_stores_code_and_message_test() {
  let error = ServerError(500, "Internal server error occurred")

  case error {
    ServerError(code, msg) -> {
      code
      |> should.equal(500)
      msg
      |> should.equal("Internal server error occurred")
    }
    _ -> panic as "Expected ServerError variant"
  }
}

// Test: ServerError with different status codes
pub fn server_error_handles_various_status_codes_test() {
  let error_502 = ServerError(502, "Bad Gateway")
  let error_503 = ServerError(503, "Service Unavailable")

  case error_502 {
    ServerError(code, _) -> {
      code
      |> should.equal(502)
    }
    _ -> panic as "Expected ServerError variant"
  }

  case error_503 {
    ServerError(code, _) -> {
      code
      |> should.equal(503)
    }
    _ -> panic as "Expected ServerError variant"
  }
}

// Test: NetworkError with message
pub fn network_error_stores_message_test() {
  let error = NetworkError("Connection refused: could not reach server")

  case error {
    NetworkError(msg) -> {
      msg
      |> should.equal("Connection refused: could not reach server")
    }
    _ -> panic as "Expected NetworkError variant"
  }
}

// Test: TimeoutError constructor
pub fn timeout_error_creates_variant_test() {
  let error = TimeoutError

  case error {
    TimeoutError -> True
    _ -> False
  }
  |> should.be_true()
}

// Test: ParseError with message
pub fn parse_error_stores_message_test() {
  let error = ParseError("Invalid JSON: unexpected token at line 5")

  case error {
    ParseError(msg) -> {
      msg
      |> should.equal("Invalid JSON: unexpected token at line 5")
    }
    _ -> panic as "Expected ParseError variant"
  }
}

// Test: UnknownError with message
pub fn unknown_error_stores_message_test() {
  let error = UnknownError("Unexpected error occurred during API call")

  case error {
    UnknownError(msg) -> {
      msg
      |> should.equal("Unexpected error occurred during API call")
    }
    _ -> panic as "Expected UnknownError variant"
  }
}

// Test: error_to_string for AuthenticationError
pub fn error_to_string_authentication_test() {
  let error = AuthenticationError
  let result = error_to_string(error)

  result
  |> should.equal("Authentication failed")
}

// Test: error_to_string for AuthorizationError
pub fn error_to_string_authorization_test() {
  let error = AuthorizationError
  let result = error_to_string(error)

  result
  |> should.equal("Authorization failed")
}

// Test: error_to_string for NotFoundError
pub fn error_to_string_not_found_test() {
  let error = NotFoundError("User with ID 42 not found")
  let result = error_to_string(error)

  result
  |> should.equal("Not found: User with ID 42 not found")
}

// Test: error_to_string for BadRequestError
pub fn error_to_string_bad_request_test() {
  let error = BadRequestError("Missing required field: email")
  let result = error_to_string(error)

  result
  |> should.equal("Bad request: Missing required field: email")
}

// Test: error_to_string for ServerError
pub fn error_to_string_server_error_test() {
  let error = ServerError(500, "Database connection failed")
  let result = error_to_string(error)

  result
  |> should.equal("Server error (500): Database connection failed")
}

// Test: error_to_string for ServerError with different code
pub fn error_to_string_server_error_503_test() {
  let error = ServerError(503, "Service temporarily unavailable")
  let result = error_to_string(error)

  result
  |> should.equal("Server error (503): Service temporarily unavailable")
}

// Test: error_to_string for NetworkError
pub fn error_to_string_network_error_test() {
  let error = NetworkError("DNS resolution failed")
  let result = error_to_string(error)

  result
  |> should.equal("Network error: DNS resolution failed")
}

// Test: error_to_string for TimeoutError
pub fn error_to_string_timeout_test() {
  let error = TimeoutError
  let result = error_to_string(error)

  result
  |> should.equal("Request timeout")
}

// Test: error_to_string for ParseError
pub fn error_to_string_parse_error_test() {
  let error = ParseError("Expected object, got array")
  let result = error_to_string(error)

  result
  |> should.equal("Parse error: Expected object, got array")
}

// Test: error_to_string for UnknownError
pub fn error_to_string_unknown_error_test() {
  let error = UnknownError("Something went wrong")
  let result = error_to_string(error)

  result
  |> should.equal("Unknown error: Something went wrong")
}

// Test: Pattern matching works correctly
pub fn pattern_matching_all_variants_test() {
  let match_variant = fn(error: TandoorError) -> String {
    case error {
      AuthenticationError -> "auth"
      AuthorizationError -> "authz"
      NotFoundError(_) -> "not_found"
      BadRequestError(_) -> "bad_request"
      ServerError(_, _) -> "server"
      NetworkError(_) -> "network"
      TimeoutError -> "timeout"
      ParseError(_) -> "parse"
      UnknownError(_) -> "unknown"
    }
  }

  // Verify each variant matches correctly
  match_variant(AuthenticationError)
  |> should.equal("auth")

  match_variant(AuthorizationError)
  |> should.equal("authz")

  match_variant(NotFoundError("test"))
  |> should.equal("not_found")

  match_variant(BadRequestError("test"))
  |> should.equal("bad_request")

  match_variant(ServerError(500, "test"))
  |> should.equal("server")

  match_variant(NetworkError("test"))
  |> should.equal("network")

  match_variant(TimeoutError)
  |> should.equal("timeout")

  match_variant(ParseError("test"))
  |> should.equal("parse")

  match_variant(UnknownError("test"))
  |> should.equal("unknown")
}

// Test: Empty string messages are handled
pub fn error_handles_empty_messages_test() {
  let not_found = NotFoundError("")
  let bad_request = BadRequestError("")
  let network = NetworkError("")
  let parse = ParseError("")
  let unknown = UnknownError("")

  error_to_string(not_found)
  |> should.equal("Not found: ")

  error_to_string(bad_request)
  |> should.equal("Bad request: ")

  error_to_string(network)
  |> should.equal("Network error: ")

  error_to_string(parse)
  |> should.equal("Parse error: ")

  error_to_string(unknown)
  |> should.equal("Unknown error: ")
}

// Test: ServerError with zero status code
pub fn server_error_handles_zero_status_code_test() {
  let error = ServerError(0, "Unknown status")

  case error {
    ServerError(code, msg) -> {
      code
      |> should.equal(0)
      msg
      |> should.equal("Unknown status")
    }
    _ -> panic as "Expected ServerError variant"
  }

  error_to_string(error)
  |> should.equal("Server error (0): Unknown status")
}

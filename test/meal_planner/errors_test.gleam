//// Comprehensive tests for centralized error handling framework
////
//// Tests cover:
//// - Error type hierarchy and conversions
//// - Error context preservation
//// - Structured error codes
//// - User-friendly error messages
//// - HTTP response serialization
//// - Error recovery strategies
//// - Railway-Oriented Programming patterns

import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/errors

// ============================================================================
// Error Type Hierarchy Tests
// ============================================================================

pub fn error_hierarchy_validation_error_test() {
  let error =
    errors.ValidationError(field: "email", reason: "Invalid email format")

  errors.is_validation_error(error)
  |> should.be_true()

  errors.is_recoverable(error)
  |> should.be_false()

  errors.error_severity(error)
  |> should.equal(errors.Warning)
}

pub fn error_hierarchy_not_found_error_test() {
  let error = errors.NotFoundError(resource: "recipe", id: "123")

  errors.is_client_error(error)
  |> should.be_true()

  errors.is_recoverable(error)
  |> should.be_false()

  errors.http_status_code(error)
  |> should.equal(404)
}

pub fn error_hierarchy_database_error_test() {
  let error =
    errors.DatabaseError(
      operation: "insert",
      message: "Unique constraint violated",
    )

  errors.is_server_error(error)
  |> should.be_true()

  errors.is_recoverable(error)
  |> should.be_false()

  errors.error_severity(error)
  |> should.equal(errors.Critical)
}

pub fn error_hierarchy_network_error_test() {
  let error = errors.NetworkError(message: "Connection timeout")

  errors.is_recoverable(error)
  |> should.be_true()

  errors.error_severity(error)
  |> should.equal(errors.Warning)

  errors.http_status_code(error)
  |> should.equal(502)
}

// ============================================================================
// Error Context Preservation Tests
// ============================================================================

pub fn error_context_add_context_test() {
  let base_error =
    errors.ValidationError(field: "age", reason: "Must be positive")

  let with_context =
    base_error
    |> errors.add_context("user_id", "user-123")
    |> errors.add_context("operation", "create_profile")

  errors.get_context(with_context, "user_id")
  |> should.equal(Some("user-123"))

  errors.get_context(with_context, "operation")
  |> should.equal(Some("create_profile"))

  errors.get_context(with_context, "nonexistent")
  |> should.equal(None)
}

pub fn error_context_wrap_error_test() {
  let cause = errors.NetworkError(message: "Connection refused")
  let wrapped =
    errors.wrap_error(
      cause,
      errors.ServiceError(service: "tandoor", message: "Failed to fetch recipe"),
    )

  errors.get_root_cause(wrapped)
  |> should.equal(cause)

  errors.error_chain_length(wrapped)
  |> should.equal(2)
}

pub fn error_context_multiple_wrapping_test() {
  let root = errors.AuthenticationError(message: "Invalid token")
  let level1 =
    errors.wrap_error(root, errors.AuthorizationError(message: "Access denied"))
  let level2 =
    errors.wrap_error(
      level1,
      errors.ServiceError(service: "api", message: "Request failed"),
    )

  errors.error_chain_length(level2)
  |> should.equal(3)

  errors.get_root_cause(level2)
  |> should.equal(root)
}

// ============================================================================
// Structured Error Code Tests
// ============================================================================

pub fn error_code_validation_error_test() {
  let error = errors.ValidationError(field: "email", reason: "Invalid format")

  errors.error_code(error)
  |> should.equal("VALIDATION_ERROR")

  errors.error_code_numeric(error)
  |> should.equal(4001)
}

pub fn error_code_not_found_error_test() {
  let error = errors.NotFoundError(resource: "recipe", id: "456")

  errors.error_code(error)
  |> should.equal("NOT_FOUND")

  errors.error_code_numeric(error)
  |> should.equal(4004)
}

pub fn error_code_authentication_error_test() {
  let error = errors.AuthenticationError(message: "Invalid credentials")

  errors.error_code(error)
  |> should.equal("AUTHENTICATION_ERROR")

  errors.error_code_numeric(error)
  |> should.equal(4011)
}

pub fn error_code_authorization_error_test() {
  let error = errors.AuthorizationError(message: "Insufficient permissions")

  errors.error_code(error)
  |> should.equal("AUTHORIZATION_ERROR")

  errors.error_code_numeric(error)
  |> should.equal(4031)
}

// ============================================================================
// User-Friendly Error Message Tests
// ============================================================================

pub fn error_message_validation_error_test() {
  let error =
    errors.ValidationError(field: "email", reason: "Invalid email format")

  errors.user_friendly_message(error)
  |> should.equal("The field 'email' is invalid: Invalid email format")

  errors.developer_message(error)
  |> should.equal("Validation failed for field 'email': Invalid email format")
}

pub fn error_message_not_found_error_test() {
  let error = errors.NotFoundError(resource: "recipe", id: "123")

  errors.user_friendly_message(error)
  |> should.equal("The recipe you're looking for was not found.")

  errors.developer_message(error)
  |> should.equal("Resource 'recipe' with ID '123' not found")
}

pub fn error_message_database_error_test() {
  let error =
    errors.DatabaseError(operation: "insert", message: "Duplicate key")

  errors.user_friendly_message(error)
  |> should.equal("A database error occurred. Please try again later.")

  errors.developer_message(error)
  |> should.equal("Database operation 'insert' failed: Duplicate key")
}

// ============================================================================
// HTTP Response Serialization Tests
// ============================================================================

pub fn http_serialization_validation_error_test() {
  let error = errors.ValidationError(field: "email", reason: "Invalid format")

  let response = errors.to_http_response(error)

  response.status
  |> should.equal(400)

  response.body
  |> json.decode(errors.error_response_decoder())
  |> should.be_ok()
}

pub fn http_serialization_error_response_json_test() {
  let error =
    errors.ValidationError(field: "age", reason: "Must be positive")
    |> errors.add_context("user_id", "user-456")

  let json_body = errors.to_json(error)

  json_body
  |> should.equal(
    json.object([
      #(
        "error",
        json.object([
          #("code", json.string("VALIDATION_ERROR")),
          #("code_numeric", json.int(4001)),
          #(
            "message",
            json.string("The field 'age' is invalid: Must be positive"),
          ),
          #(
            "details",
            json.object([
              #("field", json.string("age")),
              #("reason", json.string("Must be positive")),
            ]),
          ),
          #(
            "context",
            json.object([
              #("user_id", json.string("user-456")),
            ]),
          ),
        ]),
      ),
    ]),
  )
}

pub fn http_serialization_with_request_id_test() {
  let error = errors.NotFoundError(resource: "recipe", id: "789")

  let response = errors.to_http_response_with_request_id(error, "req-abc-123")

  response.headers
  |> should.contain(#("X-Request-ID", "req-abc-123"))
}

// ============================================================================
// Error Recovery Strategy Tests
// ============================================================================

pub fn recovery_strategy_validation_error_test() {
  let error = errors.ValidationError(field: "email", reason: "Invalid format")

  errors.recovery_strategy(error)
  |> should.equal(errors.NoRetry)
}

pub fn recovery_strategy_network_error_test() {
  let error = errors.NetworkError(message: "Connection timeout")

  errors.recovery_strategy(error)
  |> should.equal(errors.RetryWithBackoff(max_attempts: 3, backoff_ms: 1000))
}

pub fn recovery_strategy_rate_limit_error_test() {
  let error = errors.RateLimitError(retry_after_seconds: 60)

  errors.recovery_strategy(error)
  |> should.equal(errors.RetryAfter(seconds: 60))
}

pub fn recovery_strategy_database_error_test() {
  let error =
    errors.DatabaseError(operation: "select", message: "Connection lost")

  errors.recovery_strategy(error)
  |> should.equal(errors.RetryWithBackoff(max_attempts: 5, backoff_ms: 2000))
}

// ============================================================================
// Railway-Oriented Programming Tests
// ============================================================================

pub fn railway_result_chain_success_test() {
  let result =
    Ok(10)
    |> errors.and_then(fn(x) { Ok(x + 5) })
    |> errors.and_then(fn(x) { Ok(x * 2) })

  result
  |> should.equal(Ok(30))
}

pub fn railway_result_chain_failure_test() {
  let result =
    Ok(10)
    |> errors.and_then(fn(x) { Ok(x + 5) })
    |> errors.and_then(fn(_) {
      Error(errors.ValidationError(field: "value", reason: "Too large"))
    })
    |> errors.and_then(fn(x) { Ok(x * 2) })

  case result {
    Error(error) -> {
      errors.is_validation_error(error)
      |> should.be_true()
    }
    Ok(_) -> should.fail()
  }
}

pub fn railway_map_error_test() {
  let result: Result(Int, String) = Error("network failure")

  let mapped =
    result
    |> errors.map_error(fn(msg) { errors.NetworkError(message: msg) })

  case mapped {
    Error(error) -> {
      errors.is_recoverable(error)
      |> should.be_true()
    }
    Ok(_) -> should.fail()
  }
}

// ============================================================================
// Error Conversion Tests
// ============================================================================

pub fn error_conversion_from_tandoor_error_test() {
  let tandoor_error = meal_planner.tandoor.core.error.AuthenticationError

  let converted = errors.from_tandoor_error(tandoor_error)

  errors.is_authentication_error(converted)
  |> should.be_true()
}

pub fn error_conversion_from_fatsecret_error_test() {
  let fs_error =
    meal_planner.fatsecret.core.errors.ApiError(
      code: meal_planner.fatsecret.core.errors.InvalidAccessToken,
      message: "Access token expired",
    )

  let converted = errors.from_fatsecret_error(fs_error)

  errors.is_authentication_error(converted)
  |> should.be_true()

  errors.user_friendly_message(converted)
  |> should.equal("Your session has expired. Please log in again.")
}

pub fn error_conversion_from_database_error_test() {
  let db_error = "Unique constraint violation: duplicate email"

  let converted = errors.from_database_error("insert", db_error)

  errors.is_server_error(converted)
  |> should.be_true()

  errors.error_code(converted)
  |> should.equal("DATABASE_ERROR")
}

// ============================================================================
// Internationalization Hook Tests
// ============================================================================

pub fn i18n_get_message_template_test() {
  let error = errors.ValidationError(field: "email", reason: "Invalid format")

  errors.get_message_template(error)
  |> should.equal("validation.field_invalid")

  errors.get_template_params(error)
  |> should.equal([
    #("field", "email"),
    #("reason", "Invalid format"),
  ])
}

pub fn i18n_localized_message_test() {
  let error = errors.NotFoundError(resource: "recipe", id: "123")

  errors.localized_message(error, locale: "en")
  |> should.equal("The recipe you're looking for was not found.")

  errors.localized_message(error, locale: "es")
  |> should.equal("La receta que buscas no fue encontrada.")

  errors.localized_message(error, locale: "fr")
  |> should.equal("La recette que vous recherchez n'a pas été trouvée.")
}

// ============================================================================
// Error Logging Hook Tests
// ============================================================================

pub fn logging_log_error_test() {
  let error =
    errors.DatabaseError(operation: "update", message: "Deadlock detected")
    |> errors.add_context("table", "recipes")
    |> errors.add_context("transaction_id", "tx-789")

  let log_entry = errors.to_log_entry(error)

  log_entry.level
  |> should.equal(errors.Critical)

  log_entry.error_code
  |> should.equal("DATABASE_ERROR")

  log_entry.context
  |> should.equal([
    #("table", "recipes"),
    #("transaction_id", "tx-789"),
    #("operation", "update"),
  ])
}

pub fn logging_should_alert_test() {
  let critical_error =
    errors.DatabaseError(operation: "connect", message: "Connection refused")

  errors.should_alert(critical_error)
  |> should.be_true()

  let warning_error = errors.ValidationError(field: "name", reason: "Too long")

  errors.should_alert(warning_error)
  |> should.be_false()
}

/// Consolidated Error-to-Response Handler for Meal Planner
///
/// This module centralizes all error-to-HTTP-response conversions across the
/// application, eliminating duplicate error handling logic in handlers.
///
/// Supported error patterns:
/// - AppError from meal_planner/errors module
/// - Tandoor client errors
/// - FatSecret service errors
/// - Validation errors with field details
/// - Database errors
///
/// All responses are JSON-formatted with consistent structure and appropriate
/// HTTP status codes.
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import meal_planner/errors.{type AppError}
import meal_planner/fatsecret/core/errors as fatsecret_errors
import meal_planner/tandoor/core/error as tandoor_error
import wisp

// ============================================================================
// Primary Error-to-Response Conversion
// ============================================================================

/// Convert an AppError to a Wisp HTTP response with JSON body
///
/// Maps AppError types to appropriate HTTP status codes and JSON response format.
/// Uses the centralized errors module for consistency.
///
/// # Arguments
/// * `error` - The AppError to convert
///
/// # Returns
/// wisp.Response with proper status code and JSON error format
///
/// # Example
/// ```gleam
/// app_error_to_response(errors.ValidationError("email", "Invalid format"))
/// // -> 400 Bad Request JSON response
/// ```
pub fn app_error_to_response(error: AppError) -> wisp.Response {
  let status = errors.http_status_code(error)
  let body = errors.to_json(error) |> json.to_string

  wisp.json_response(body, status)
}

/// Convert an AppError to an HTTP Response (lower-level API)
///
/// Alternative to app_error_to_response() for use with gleam/http/response module.
/// Provides the same error handling with Response type instead of wisp.Response.
///
/// # Arguments
/// * `error` - The AppError to convert
///
/// # Returns
/// Response(String) with proper status code and JSON body
pub fn app_error_to_http_response(error: AppError) -> Response(String) {
  errors.to_http_response(error)
}

// ============================================================================
// Tandoor Error Conversion
// ============================================================================

/// Convert a Tandoor TandoorError to a Wisp HTTP response
///
/// Maps all Tandoor error types to appropriate HTTP status codes.
///
/// Error mapping:
/// - AuthenticationError (401)
/// - AuthorizationError (403)
/// - NotFoundError (404)
/// - BadRequestError (400)
/// - ServerError (5xx)
/// - NetworkError/TimeoutError (502)
/// - ParseError/UnknownError (500)
///
/// # Arguments
/// * `error` - The TandoorError to convert
///
/// # Returns
/// wisp.Response with proper status code and JSON error format
///
/// # Example
/// ```gleam
/// tandoor_error_to_response(tandoor_error.NotFoundError("Recipe not found"))
/// // -> 404 Not Found JSON response
/// ```
pub fn tandoor_error_to_response(
  error: tandoor_error.TandoorError,
) -> wisp.Response {
  error
  |> errors.from_tandoor_error
  |> app_error_to_response
}

// ============================================================================
// FatSecret Error Conversion
// ============================================================================

/// Convert a FatSecret API error to a Wisp HTTP response
///
/// Maps FatSecret API error codes to appropriate HTTP responses.
///
/// Error mapping:
/// - InvalidAccessToken/InvalidOrExpiredToken (401)
/// - MissingRequiredParameter (400)
/// - InvalidDate (400)
/// - ApiUnavailable (502)
/// - Other errors (500)
///
/// # Arguments
/// * `error` - The FatSecretError to convert
///
/// # Returns
/// wisp.Response with proper status code and JSON error format
pub fn fatsecret_api_error_to_response(
  error: fatsecret_errors.FatSecretError,
) -> wisp.Response {
  error
  |> errors.from_fatsecret_error
  |> app_error_to_response
}

// ============================================================================
// Database Error Conversion
// ============================================================================

/// Convert a database error to a Wisp HTTP response
///
/// All database errors return 500 Internal Server Error with appropriate
/// error details in the JSON response.
///
/// # Arguments
/// * `operation` - The database operation that failed (e.g., "insert", "select")
/// * `message` - The database error message
///
/// # Returns
/// wisp.Response with 500 status code and JSON error format
pub fn database_error_to_response(
  operation: String,
  message: String,
) -> wisp.Response {
  errors.from_database_error(operation, message)
  |> app_error_to_response
}

// ============================================================================
// Validation Error Conversion
// ============================================================================

/// Convert a validation error to a Wisp HTTP response
///
/// Validation errors return 400 Bad Request with field-specific error details.
///
/// # Arguments
/// * `field` - The field that failed validation
/// * `reason` - The reason validation failed
///
/// # Returns
/// wisp.Response with 400 status code and JSON error format
///
/// # Example
/// ```gleam
/// validation_error_to_response("email", "Must be a valid email address")
/// // -> 400 Bad Request with field and reason in JSON
/// ```
pub fn validation_error_to_response(
  field: String,
  reason: String,
) -> wisp.Response {
  errors.ValidationError(field, reason)
  |> app_error_to_response
}

/// Convert multiple validation errors to a Wisp HTTP response
///
/// Allows returning multiple field validation errors in a single response.
///
/// # Arguments
/// * `errors_list` - List of (field, reason) tuples
///
/// # Returns
/// wisp.Response with 400 status code and JSON error format with all errors
pub fn validation_errors_to_response(
  errors_list: List(#(String, String)),
) -> wisp.Response {
  let error_objects =
    list.map(errors_list, fn(error) {
      let #(field, reason) = error
      json.object([
        #("field", json.string(field)),
        #("reason", json.string(reason)),
      ])
    })

  let body =
    json.object([
      #(
        "error",
        json.object([
          #("code", json.string("VALIDATION_ERROR")),
          #("code_numeric", json.int(4001)),
          #("message", json.string("One or more validation errors occurred")),
          #("errors", json.array(error_objects, fn(e) { e })),
        ]),
      ),
    ])
    |> json.to_string

  wisp.json_response(body, 400)
}

// ============================================================================
// Not Found Error Conversion
// ============================================================================

/// Convert a not found error to a Wisp HTTP response
///
/// Not found errors return 404 with resource and ID details.
///
/// # Arguments
/// * `resource` - The type of resource not found (e.g., "recipe", "meal_plan")
/// * `id` - The ID of the resource that was not found
///
/// # Returns
/// wisp.Response with 404 status code and JSON error format
pub fn not_found_error_to_response(
  resource: String,
  id: String,
) -> wisp.Response {
  errors.NotFoundError(resource, id)
  |> app_error_to_response
}

// ============================================================================
// Generic JSON Error Response Builder
// ============================================================================

/// Build a custom JSON error response
///
/// Low-level helper for creating JSON error responses with custom status code,
/// error code, and message. Use higher-level functions when possible.
///
/// # Arguments
/// * `status` - HTTP status code
/// * `error_code` - Error code string (e.g., "NOT_FOUND", "VALIDATION_ERROR")
/// * `message` - User-friendly error message
///
/// # Returns
/// wisp.Response with specified status code and JSON body
pub fn json_error_response(
  status: Int,
  error_code: String,
  message: String,
) -> wisp.Response {
  let body =
    json.object([
      #("error", json.string(error_code)),
      #("message", json.string(message)),
    ])
    |> json.to_string

  wisp.json_response(body, status)
}

// ============================================================================
// Result Pipeline Helpers
// ============================================================================

/// Convert a Result to either success response or error response
///
/// Useful for flattening Result handling in handlers.
/// Maps Ok(data) to success response and Error to error response.
///
/// # Arguments
/// * `result` - The Result to convert
/// * `encode_success` - Function to encode success data to JSON
/// * `success_status` - HTTP status code for success (typically 200 or 201)
///
/// # Returns
/// wisp.Response with appropriate status code and body
pub fn result_to_response(
  result: Result(a, AppError),
  encode_success: fn(a) -> json.Json,
  success_status: Int,
) -> wisp.Response {
  case result {
    Ok(data) -> {
      encode_success(data)
      |> json.to_string
      |> wisp.json_response(success_status)
    }
    Error(error) -> app_error_to_response(error)
  }
}

# Tandoor HTTP Client

**Module:** `meal_planner/tandoor/client/http`

**Purpose:** Low-level HTTP request building, response parsing, and error handling for Tandoor API.

## Overview

This module provides the HTTP infrastructure for all Tandoor API operations:
- Request building for all HTTP methods (GET, POST, PUT, PATCH, DELETE)
- Response parsing and error classification
- Authentication header management (Session, Bearer)
- URL encoding and query string building
- Retry logic for transient failures

Used by all resource-specific modules (recipes, mealplan, foods, etc).

## Public API

### Request Building

```gleam
pub fn build_get_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
  query_params: List(#(String, String)),
) -> Result(request.Request(String), TandoorError)

pub fn build_post_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
  body: Json,
) -> Result(request.Request(String), TandoorError)

pub fn build_put_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
  body: Json,
) -> Result(request.Request(String), TandoorError)

pub fn build_patch_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
  body: Json,
) -> Result(request.Request(String), TandoorError)

pub fn build_delete_request(
  base_url: String,
  auth: AuthMethod,
  path: String,
) -> Result(request.Request(String), TandoorError)
```

### Request Execution

```gleam
pub fn send_request(
  req: request.Request(String),
) -> Result(ApiResponse, TandoorError)

pub fn send_request_with_retry(
  req: request.Request(String),
  max_retries: Int,
) -> Result(ApiResponse, TandoorError)
```

### Response Parsing

```gleam
pub fn parse_json_response(
  response: ApiResponse,
  decoder: Decoder(t),
) -> Result(t, TandoorError)

pub fn parse_list_response(
  response: ApiResponse,
  decoder: Decoder(t),
) -> Result(List(t), TandoorError)
```

### Error Handling

```gleam
pub fn classify_error(
  status: Int,
  body: String,
) -> TandoorError

pub fn is_retryable(error: TandoorError) -> Bool
```

### URL Utilities

```gleam
pub fn encode_query_params(
  params: List(#(String, String)),
) -> String

pub fn build_url(
  base_url: String,
  path: String,
  query_params: List(#(String, String)),
) -> Result(String, String)
```

## Usage Examples

### GET Request

```gleam
import meal_planner/tandoor/client/http
import meal_planner/tandoor/client/mod

let config = mod.session_config(
  base_url: "http://localhost:8000",
  username: "user",
  password: "pass",
)

// Build request
let request_result = http.build_get_request(
  base_url: config.base_url,
  auth: config.auth,
  path: "/api/recipe/",
  query_params: [#("page", "1"), #("page_size", "20")],
)

case request_result {
  Ok(req) -> {
    // Send request
    case http.send_request(req) {
      Ok(response) -> {
        // Parse response
        case http.parse_list_response(response, recipe_decoder()) {
          Ok(recipes) -> // Process recipes
          Error(error) -> // Handle parse error
        }
      }
      Error(error) -> // Handle request error
    }
  }
  Error(error) -> // Handle build error
}
```

### POST Request with Retry

```gleam
import gleam/json

let recipe_json = json.object([
  #("name", json.string("Grilled Chicken")),
  #("servings", json.int(2)),
  // ... more fields
])

// Build POST request
let request_result = http.build_post_request(
  base_url: config.base_url,
  auth: config.auth,
  path: "/api/recipe/",
  body: recipe_json,
)

case request_result {
  Ok(req) -> {
    // Send with retry (up to 3 attempts)
    case http.send_request_with_retry(req, max_retries: 3) {
      Ok(response) -> {
        case http.parse_json_response(response, recipe_decoder()) {
          Ok(created_recipe) -> // Success
          Error(error) -> // Parse error
        }
      }
      Error(error) -> // Request failed after retries
    }
  }
  Error(error) -> // Build error
}
```

### Error Classification

```gleam
case http.send_request(req) {
  Error(error) -> {
    // Check if retryable
    case http.is_retryable(error) {
      True -> {
        // NetworkError, TimeoutError, or 5xx
        io.println("Retrying...")
        // Implement retry logic
      }
      False -> {
        // AuthError, NotFound, BadRequest, etc
        io.println("Non-retryable error: " <> mod.error_to_string(error))
      }
    }
  }
  Ok(_) -> // Success
}
```

### Custom Query Params

```gleam
let params = [
  #("search", "chicken"),
  #("category", "protein"),
  #("verified_only", "true"),
]

let query_string = http.encode_query_params(params)
// "search=chicken&category=protein&verified_only=true"

let url = http.build_url(
  base_url: "http://localhost:8000",
  path: "/api/recipe/",
  query_params: params,
)
// Ok("http://localhost:8000/api/recipe/?search=chicken&category=protein&verified_only=true")
```

## Authentication

### Session Auth Headers

When `auth` is `SessionAuth` with `session_id` and `csrf_token`:
- Adds `Cookie: sessionid=<session_id>` header
- Adds `X-CSRFToken: <csrf_token>` header (for mutating requests)
- CSRF token only added for POST, PUT, PATCH, DELETE

### Bearer Auth Headers

When `auth` is `BearerAuth`:
- Adds `Authorization: Bearer <token>` header
- Applied to all requests

### Common Headers

All requests include:
- `Content-Type: application/json`
- `Accept: application/json`

## Error Classification

HTTP status codes map to TandoorError:

| Status Code | Error Type | Retryable |
|-------------|------------|-----------|
| 400 | BadRequestError | No |
| 401 | AuthenticationError | No |
| 403 | AuthorizationError | No |
| 404 | NotFoundError | No |
| 500-599 | ServerError | Yes |
| Network failure | NetworkError | Yes |
| Timeout | TimeoutError | Yes |
| JSON parse failure | ParseError | No |

Use `is_retryable()` to check if an error should be retried.

## Retry Logic

`send_request_with_retry()` retries on transient errors:
- **NetworkError** - Connection issues
- **TimeoutError** - Request timeout
- **ServerError (5xx)** - Server errors

Non-retryable errors immediately return without retry.

**Retry strategy:**
- Attempts: 1 initial + `max_retries` retries
- No exponential backoff (immediate retry)
- Stops on first success or first non-retryable error

## Response Parsing

### parse_json_response

Parses single JSON object:
```gleam
// Response body: {"id": 123, "name": "Chicken"}
parse_json_response(response, recipe_decoder())
// Ok(Recipe { id: 123, name: "Chicken", ... })
```

### parse_list_response

Parses JSON array:
```gleam
// Response body: [{"id": 1, ...}, {"id": 2, ...}]
parse_list_response(response, recipe_decoder())
// Ok([Recipe {...}, Recipe {...}])
```

Both functions:
- Return `ParseError` if JSON is malformed
- Return `ParseError` if decoder fails
- Include error details in message

## URL Building

### Query Parameter Encoding

`encode_query_params()` handles:
- URL encoding of keys and values
- Joining with `&`
- Empty list returns empty string

Example:
```gleam
encode_query_params([
  #("search", "chicken breast"),
  #("verified", "true"),
])
// "search=chicken%20breast&verified=true"
```

### URL Construction

`build_url()` combines:
- Base URL
- Path (must start with `/`)
- Query params (optional)

Handles edge cases:
- Trailing slash in base_url
- Query params starting with `?`
- Empty query params

## Design Notes

### Low-Level Abstraction

This module provides low-level HTTP primitives. Resource-specific modules (recipes, mealplan) use these to build higher-level APIs.

### Composable Functions

All functions are pure and composable:
```gleam
build_get_request(...)
|> result.try(send_request_with_retry(_, 3))
|> result.try(parse_list_response(_, decoder))
```

### Error Propagation

All functions return `Result(T, TandoorError)` for consistent error handling. Errors propagate up through `result.try` chains.

### Gleam HTTP Integration

Uses `gleam/http` and `gleam/httpc` for HTTP operations:
- `request.Request` for request building
- `httpc.send` for execution
- Standard HTTP types throughout

## Dependencies

- `gleam/http` - HTTP types and methods
- `gleam/httpc` - HTTP client for request execution
- `gleam/json` - JSON encoding
- `gleam/dynamic/decode` - JSON decoding
- `gleam/uri` - URL encoding
- `meal_planner/logger` - Request/response logging

## Related Modules

- **tandoor/client/mod** - Core types (ClientConfig, TandoorError, AuthMethod)
- **tandoor/client/recipes** - Uses HTTP for recipe operations
- **tandoor/client/mealplan** - Uses HTTP for meal plan operations
- **tandoor/client/foods** - Uses HTTP for food operations

## File Size

~450 lines (under 500-line target)

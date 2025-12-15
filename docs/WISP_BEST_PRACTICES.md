# Wisp Best Practices for Meal Planner

This document describes the idiomatic Wisp patterns used throughout the Meal Planner API. All endpoints should follow these conventions for consistency and maintainability.

## Table of Contents

1. [Response Builders](#response-builders)
2. [Handler Patterns](#handler-patterns)
3. [HTTP Method Handling](#http-method-handling)
4. [Error Handling](#error-handling)
5. [Request Body Parsing](#request-body-parsing)
6. [Middleware Usage](#middleware-usage)
7. [Route Organization](#route-organization)
8. [Common Patterns](#common-patterns)

## Response Builders

All responses should use the centralized response builders from `meal_planner/web/responses`. This ensures consistent JSON formatting and HTTP status codes across all endpoints.

### Success Responses

```gleam
import meal_planner/web/responses
import gleam/json

// 200 OK with data
let response = responses.json_ok(json.object([
  #("id", json.int(123)),
  #("name", json.string("Recipe Name")),
]))

// 201 Created with new resource
let response = responses.json_created(json.object([
  #("id", json.int(123)),
]))

// 204 No Content (empty response)
let response = responses.no_content()
```

All success responses use `wisp.json_response()` internally, which properly sets the `Content-Type: application/json` header.

### Error Responses

```gleam
// 400 Bad Request
responses.bad_request("Invalid input: expected integer for 'quantity'")

// 401 Unauthorized
responses.unauthorized("Missing or invalid authentication token")

// 403 Forbidden
responses.forbidden("You do not have permission to delete this recipe")

// 404 Not Found
responses.not_found("Recipe with ID 123 not found")

// 409 Conflict
responses.conflict("Recipe with this slug already exists")

// 415 Unsupported Media Type
responses.unsupported_media_type("Content-Type must be application/json")

// 500 Internal Server Error
responses.internal_error("Unexpected database error occurred")

// 501 Not Implemented
responses.not_implemented("Exercise tracking coming soon")

// 502 Bad Gateway (external service failure)
responses.bad_gateway("FatSecret API returned HTTP 500: Internal Server Error")

// 503 Service Unavailable
responses.service_unavailable("Database connection pool exhausted")
```

All error responses follow this JSON format:

```json
{
  "error": "Error Type",
  "message": "Detailed error message"
}
```

## Handler Patterns

### Minimal Handler

A minimal handler validates the HTTP method and returns a response:

```gleam
import gleam/http
import meal_planner/web/responses
import wisp

// GET /health
pub fn handle_health(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let health =
    json.object([
      #("status", json.string("healthy")),
      #("service", json.string("meal-planner")),
    ])

  responses.json_ok(health)
}
```

### Standard Handler with Request Logging

Most handlers should include logging and error recovery:

```gleam
import gleam/http
import meal_planner/web/responses
import wisp

// POST /api/recipes
pub fn handle_create_recipe(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_string_body(req)

  case parse_recipe_request(body) {
    Error(msg) -> responses.bad_request(msg)
    Ok(recipe_data) -> {
      // Process and create recipe
      let created_recipe = create_recipe(recipe_data)
      responses.json_created(encode_recipe(created_recipe))
    }
  }
}
```

### Handler with Multiple HTTP Methods

When a route handles multiple HTTP methods, use pattern matching within the router:

```gleam
// In web.gleam route handler
case req.method {
  http.Get -> handle_list_recipes(req)
  http.Post -> handle_create_recipe(req)
  _ -> wisp.method_not_allowed([http.Get, http.Post])
}
```

This approach is preferred over checking methods inside the handler function.

## HTTP Method Handling

### Required Method Check

Use `wisp.require_method()` to enforce a specific HTTP method:

```gleam
pub fn handle_get_recipe(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  // Handler continues only if method is GET
}
```

The `wisp.require_method()` utility automatically returns a 405 Method Not Allowed response if the request method doesn't match.

### Multiple Methods

For endpoints that handle multiple methods, use Wisp's `wisp.method_not_allowed()`:

```gleam
case req.method {
  http.Get -> handle_list(req)
  http.Post -> handle_create(req)
  http.Delete -> handle_delete(req)
  _ -> wisp.method_not_allowed([http.Get, http.Post, http.Delete])
}
```

The `wisp.method_not_allowed()` function returns a 405 response with proper `Allow` headers.

### HEAD Request Support

Always use `wisp.handle_head()` to automatically convert HEAD requests to GET with no body:

```gleam
pub fn handle_get_recipe(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use req <- wisp.handle_head(req)  // Converts HEAD to GET
  use <- wisp.require_method(req, http.Get)
  // ...
}
```

This ensures HEAD requests work correctly without special handling.

## Error Handling

### Use `wisp.rescue_crashes`

Wrap handler bodies with `wisp.rescue_crashes` to recover from panics:

```gleam
pub fn handle_calculate(req: wisp.Request) -> wisp.Response {
  use <- wisp.rescue_crashes
  use <- wisp.require_method(req, http.Post)
  // ... calculation logic ...
}
```

This prevents unhandled exceptions from crashing the server.

### Result Types

Always use `Result` types for operations that might fail. Don't use exceptions:

```gleam
// ✓ Good: Use Result type
fn get_recipe(id: Int) -> Result(Recipe, String) {
  case database.query(...) {
    Ok(recipe) -> Ok(recipe)
    Error(db_error) -> Error("Database error: " <> db_error)
  }
}

// ✗ Bad: Don't use exceptions
fn get_recipe_unsafe(id: Int) -> Recipe {
  assert recipe = database.query(...)  // Can panic
  recipe
}
```

### Error Response Selection

Choose appropriate HTTP status codes:

- **400 Bad Request**: Invalid input, validation failures
- **401 Unauthorized**: Missing or invalid authentication
- **403 Forbidden**: Authenticated but not permitted
- **404 Not Found**: Resource doesn't exist
- **409 Conflict**: Resource already exists
- **415 Unsupported Media Type**: Wrong Content-Type header
- **500 Internal Error**: Unexpected server error
- **501 Not Implemented**: Feature not implemented
- **502 Bad Gateway**: External service failure
- **503 Service Unavailable**: Server overloaded or maintenance

## Request Body Parsing

### String Body Parsing

Use `wisp.require_string_body()` to get the request body:

```gleam
pub fn handle_create(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_string_body(req)

  case json.parse(body, decoder()) {
    Ok(data) -> {
      // Process data
      responses.json_created(encode_response(data))
    }
    Error(_) -> responses.bad_request("Invalid JSON in request body")
  }
}
```

### JSON Parsing with Decoder

Use `gleam/dynamic/decode` for type-safe JSON parsing:

```gleam
import gleam/dynamic/decode

fn parse_recipe_request(body: String) -> Result(RecipeInput, String) {
  let decoder =
    decode.into(RecipeInput)
    |> decode.field("name", decode.string)
    |> decode.field("servings", decode.int)
    |> decode.optional_field("description", "", decode.string)

  case json.parse(body, decoder) {
    Ok(recipe) -> Ok(recipe)
    Error(_) -> Error("Invalid recipe request format")
  }
}
```

### Query Parameters

Parse query parameters using `wisp.get_query()`:

```gleam
pub fn handle_search(req: wisp.Request) -> wisp.Response {
  let query_params = wisp.get_query(req)

  let query = query_params
    |> list.find(fn(p) { p.0 == "q" })
    |> result.map(fn(p) { p.1 })

  case query {
    Ok(q) -> {
      let results = search_recipes(q)
      responses.json_ok(json.array(results, encode_recipe))
    }
    Error(_) -> responses.bad_request("Missing required 'q' parameter")
  }
}
```

## Middleware Usage

### Middleware Stack Composition

Create middleware stacks for different endpoint groups:

```gleam
// Health check - minimal middleware
pub fn health_stack() -> Middleware {
  compose([request_id()])
}

// Public API - standard middleware
pub fn api_stack() -> Middleware {
  compose([
    request_id(),
    request_logger(),
    error_recovery(),
    error_handler(),
    security_headers(),
    cors(["*"]),
  ])
}

// Protected API - with authentication
pub fn protected_api_stack(db: pog.Connection) -> Middleware {
  compose([
    request_id(),
    request_logger(),
    error_recovery(),
    error_handler(),
    security_headers(),
    cors(["*"]),
    require_auth(db),
  ])
}
```

### Apply Middleware to Handler

```gleam
let handler = fn(req: wisp.Request) -> wisp.Response {
  handle_request(req, ctx)
}

// Wrap with middleware stack
let protected_handler =
  apply(handler, protected_api_stack(db))
```

## Route Organization

### Route Grouping

Organize routes by domain/feature in `web.gleam`:

```gleam
case wisp.path_segments(req) {
  // =========================================================================
  // Health & Status
  // =========================================================================
  [] | ["health"] -> handlers.handle_health(req)

  // =========================================================================
  // FatSecret OAuth (3-legged, requires user auth)
  // =========================================================================
  ["fatsecret", "connect"] ->
    handlers.handle_fatsecret_connect(req, ctx.db, base_url)
  ["fatsecret", "callback"] ->
    handlers.handle_fatsecret_callback(req, ctx.db)

  // =========================================================================
  // FatSecret Foods API (2-legged, no auth required)
  // =========================================================================
  ["api", "fatsecret", "foods", "search"] ->
    handlers.handle_fatsecret_search_foods(req)
  ["api", "fatsecret", "foods", food_id] ->
    handlers.handle_fatsecret_get_food(req, food_id)

  // =========================================================================
  // 404 Not Found
  // =========================================================================
  _ -> wisp.not_found()
}
```

## Common Patterns

### Pagination Response

Use the `paginated_response()` helper for paginated results:

```gleam
import meal_planner/web/responses

let items = json.array(recipes, encode_recipe)
responses.paginated_response(items, total_count, offset, limit)
```

This returns:

```json
{
  "count": 100,
  "offset": 0,
  "limit": 20,
  "results": [...]
}
```

### Validation Errors

Use `validation_error()` for field validation responses:

```gleam
import meal_planner/web/responses

responses.validation_error([
  #("name", "Name is required"),
  #("servings", "Must be a positive integer"),
])
```

This returns:

```json
{
  "error": "Validation Error",
  "errors": [
    {"field": "name", "message": "Name is required"},
    {"field": "servings", "message": "Must be a positive integer"}
  ]
}
```

### Response with Metadata

Include additional metadata in responses:

```gleam
import meal_planner/web/responses

responses.success_with_meta(
  data: json.object([#("recipes", recipes_json)]),
  meta: [
    #("created_at", json.string(timestamp)),
    #("version", json.string("1.0.0")),
  ],
)
```

## Examples

### Complete GET Endpoint

```gleam
pub fn handle_get_recipe(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  case int.parse(recipe_id) {
    Error(_) -> responses.bad_request("Invalid recipe ID")
    Ok(id) -> {
      case get_recipe_from_db(id) {
        Ok(recipe) -> responses.json_ok(encode_recipe(recipe))
        Error(_) -> responses.not_found("Recipe not found")
      }
    }
  }
}
```

### Complete POST Endpoint

```gleam
pub fn handle_create_recipe(req: wisp.Request) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Post)
  use body <- wisp.require_string_body(req)

  case parse_recipe_request(body) {
    Error(msg) -> responses.bad_request(msg)
    Ok(recipe_data) -> {
      case validate_recipe_data(recipe_data) {
        Error(validation_errors) ->
          responses.validation_error(validation_errors)
        Ok(valid_data) -> {
          case create_recipe_in_db(valid_data) {
            Ok(created) ->
              responses.json_created(encode_recipe(created))
            Error(e) ->
              responses.internal_error("Failed to create recipe: " <> e)
          }
        }
      }
    }
  }
}
```

### Complete DELETE Endpoint

```gleam
pub fn handle_delete_recipe(
  req: wisp.Request,
  recipe_id: String,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Delete)

  case int.parse(recipe_id) {
    Error(_) -> responses.bad_request("Invalid recipe ID")
    Ok(id) -> {
      case delete_recipe_from_db(id) {
        Ok(_) -> responses.no_content()
        Error(_) -> responses.not_found("Recipe not found")
      }
    }
  }
}
```

## Checklist for New Endpoints

When adding a new endpoint, ensure:

- [ ] Uses `wisp.log_request()` for request logging
- [ ] Uses `wisp.rescue_crashes` for error recovery
- [ ] Uses `wisp.handle_head()` for HEAD support
- [ ] Uses `wisp.require_method()` for HTTP method validation
- [ ] Uses centralized response builders from `web/responses`
- [ ] Has appropriate HTTP status codes (400, 401, 403, 404, 500, etc.)
- [ ] Returns JSON responses with `Content-Type: application/json`
- [ ] Has clear error messages in response bodies
- [ ] Handles all error cases (not found, validation, etc.)
- [ ] Is organized in `web.gleam` with proper grouping comments
- [ ] Handler functions are in appropriate `web/handlers/*` modules
- [ ] Query/body parsing is type-safe using `decode`
- [ ] No hardcoded status codes - use response builders instead
# Tandoor API Client

**Module:** `meal_planner/tandoor/client/mod`

**Purpose:** Core types and configuration for the Tandoor Recipe Manager API client.

## Overview

This module provides the foundational types for all Tandoor API operations:
- **ClientConfig** - HTTP client configuration with auth
- **TandoorError** - Comprehensive error types
- **AuthMethod** - Session-based or Bearer token auth
- **HTTP types** - Method, Response, etc.

All other `tandoor/client/*` modules build upon these core types.

## Public API

### Core Types

```gleam
pub type HttpMethod {
  Get
  Post
  Put
  Patch
  Delete
}

pub type TandoorError {
  AuthenticationError(message: String)     // 401
  AuthorizationError(message: String)      // 403
  NotFoundError(resource: String)          // 404
  BadRequestError(message: String)         // 400
  ServerError(status_code: Int, message: String)  // 5xx
  NetworkError(message: String)
  TimeoutError
  ParseError(message: String)
  UnknownError(message: String)
}

pub type AuthMethod {
  SessionAuth(
    username: String,
    password: String,
    session_id: Option(String),
    csrf_token: Option(String),
  )
  BearerAuth(token: String)
}

pub type ClientConfig {
  ClientConfig(
    base_url: String,
    auth: AuthMethod,
    timeout_ms: Int,
    retry_on_transient: Bool,
    max_retries: Int,
  )
}

pub type ApiResponse {
  ApiResponse(
    status: Int,
    headers: List(#(String, String)),
    body: String,
  )
}
```

### Configuration Builders

```gleam
// Recommended: Session-based auth
pub fn session_config(
  base_url: String,
  username: String,
  password: String,
) -> ClientConfig

// Bearer token auth
pub fn bearer_config(
  base_url: String,
  token: String,
) -> ClientConfig

// Deprecated: use session_config or bearer_config
pub fn default_config(
  base_url: String,
  api_token: String,
) -> ClientConfig

// Customize timeout
pub fn with_timeout(
  config: ClientConfig,
  timeout_ms: Int,
) -> ClientConfig

// Customize retry settings
pub fn with_retry_config(
  config: ClientConfig,
  retry_on_transient: Bool,
  max_retries: Int,
) -> ClientConfig
```

### Authentication Utilities

```gleam
pub fn is_authenticated(config: ClientConfig) -> Bool

pub fn with_session(
  config: ClientConfig,
  session_id: String,
  csrf_token: String,
) -> ClientConfig
```

### Error Utilities

```gleam
pub fn is_transient_error(error: TandoorError) -> Bool
pub fn error_to_string(error: TandoorError) -> String
```

## Usage Examples

### Session-Based Authentication (Recommended)

```gleam
import meal_planner/tandoor/client/mod

// Create config with username/password
let config = mod.session_config(
  base_url: "http://localhost:8000",
  username: "user@example.com",
  password: "password123",
)

// Login to get session (handled by http module)
// After login, update config with session tokens
let authenticated_config = mod.with_session(
  config,
  session_id: "abc123...",
  csrf_token: "xyz789...",
)

// Check if authenticated
case mod.is_authenticated(authenticated_config) {
  True -> // Has session_id
  False -> // Need to login
}
```

### Bearer Token Authentication

```gleam
let config = mod.bearer_config(
  base_url: "https://tandoor.example.com",
  token: "your-api-token-here",
)

// Always authenticated with token
mod.is_authenticated(config)  // True
```

### Custom Configuration

```gleam
let config = mod.session_config(
  base_url: "http://localhost:8000",
  username: "user",
  password: "pass",
)
|> mod.with_timeout(30_000)  // 30 second timeout
|> mod.with_retry_config(
  retry_on_transient: True,
  max_retries: 5,
)
```

### Error Handling

```gleam
import meal_planner/tandoor/client/recipes

case recipes.get_recipe(config, recipe_id) {
  Ok(recipe) -> // Success
  Error(error) -> {
    // Check if retryable
    case mod.is_transient_error(error) {
      True -> // Retry (NetworkError, TimeoutError, or 5xx)
      False -> // Don't retry (AuthError, NotFound, etc)
    }

    // Get error message
    let msg = mod.error_to_string(error)
    io.println("Error: " <> msg)
  }
}
```

## Configuration Defaults

When using `session_config()` or `bearer_config()`:
- **timeout_ms:** 10,000 (10 seconds)
- **retry_on_transient:** True
- **max_retries:** 3

## Transient Errors

Errors that qualify as transient (retryable):
- `NetworkError(_)` - Network/connection issues
- `TimeoutError` - Request timeout
- `ServerError(status, _)` where 500 <= status < 600

All other errors are non-transient and should not be retried.

## Authentication Methods

### SessionAuth (Recommended)

- Establishes proper space scope in Tandoor
- Uses username/password to login
- Receives `session_id` and `csrf_token`
- Updates config with `with_session()`

**Why recommended:** Tandoor's permission system requires proper space scope, which is only established through session login.

### BearerAuth

- Uses static API token
- Simpler but may have permission issues
- Good for service accounts or CI/CD

## Design Notes

### Opaque ClientConfig

ClientConfig is a public type (not opaque) to allow pattern matching in HTTP module. However, use builder functions to construct.

### Error Type Coverage

TandoorError covers all HTTP and network failure modes:
- 400 series - BadRequestError, NotFoundError, AuthenticationError, AuthorizationError
- 500 series - ServerError
- Network/timeout - NetworkError, TimeoutError
- Parsing - ParseError
- Unknown - UnknownError (catch-all)

### Immutable Config

All config updates return new ClientConfig instances:
```gleam
let new_config = config
  |> with_timeout(20_000)
  |> with_session(session_id, csrf_token)
```

Original `config` is unchanged.

## Dependencies

- `gleam/option` - Optional session_id and csrf_token
- `gleam/int` - Status code handling

## Related Modules

- **tandoor/client/http** - HTTP request execution
- **tandoor/client/recipes** - Recipe operations using ClientConfig
- **tandoor/client/mealplan** - Meal plan operations
- **tandoor/client/foods** - Food operations

## Module Structure

The tandoor/client package is split by resource:
- **mod.gleam** - Core types and config (this module)
- **http.gleam** - HTTP request/response handling
- **recipes.gleam** - Recipe CRUD operations
- **mealplan.gleam** - Meal planning operations
- **foods.gleam** - Food/ingredient operations

All modules use ClientConfig from this module.

## File Size

208 lines (well under 500-line target)

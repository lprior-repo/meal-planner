# API Middleware Documentation

## Overview

The meal planner API implements a comprehensive middleware system for request/response processing. Middleware functions are composable and can be applied selectively to different routes.

## Middleware Stack

### Default API Stack (`default_api_stack`)

Applied to all `/api/*` endpoints:

1. **Request ID** - Generates or preserves unique request identifiers
2. **Request Logger** - Logs incoming requests and responses
3. **Error Recovery** - Provides JSON error responses for common HTTP errors
4. **Error Handler** - Catches and handles runtime errors
5. **Security Headers** - Adds security headers (XSS, CSP, HSTS, etc.)
6. **CORS** - Enables cross-origin requests
7. **Optional Auth** - Attempts authentication but doesn't require it

### Protected API Stack (`protected_api_stack`)

Applied to protected endpoints (when needed):

Same as default stack but with **Required Auth** instead of Optional Auth.

### Health Check Stack (`health_stack`)

Applied to `/health` endpoints:

1. **Request ID** - Minimal overhead for health checks

## Middleware Components

### Authentication

Two authentication modes are available:

#### Optional Authentication
```gleam
middleware.optional_auth(db)
```
- Attempts to authenticate but allows unauthenticated requests
- Used for endpoints that work with or without auth

#### Required Authentication
```gleam
middleware.require_auth(db)
```
- Returns 401 if authentication fails
- Used for protected endpoints

**Supported Auth Methods:**
- Bearer tokens: `Authorization: Bearer <token>`
- API keys: `X-API-Key: <key>`

### Logging

#### Basic Request Logger
```gleam
middleware.request_logger()
```
Logs:
- Request method and path
- Response status code

#### Detailed Logger
```gleam
middleware.detailed_logger()
```
Logs:
- Request method and path
- Request headers
- Response status code
- Response headers

### Error Handling

#### Error Handler
```gleam
middleware.error_handler()
```
- Validates response status codes
- Returns 500 for invalid responses
- Ensures proper error handling

#### Error Recovery
```gleam
middleware.error_recovery()
```
Provides JSON error responses for:
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 500 Internal Server Error

Example response:
```json
{
  "error": "Not Found",
  "message": "Resource not found"
}
```

### CORS

```gleam
middleware.cors(["*"])  // Allow all origins
middleware.cors(["https://example.com"])  // Specific origin
```

Headers added:
- `Access-Control-Allow-Origin`
- `Access-Control-Allow-Methods`
- `Access-Control-Allow-Headers`
- `Access-Control-Max-Age`

Handles OPTIONS preflight requests automatically.

### Security Headers

```gleam
middleware.security_headers()
```

Headers added:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Content-Security-Policy: default-src 'self'; ...`

### Content Type Validation

```gleam
middleware.require_json()
```

For POST/PUT/PATCH requests:
- Validates `Content-Type: application/json`
- Returns 415 for non-JSON content
- Returns 400 if header is missing

### Request ID

```gleam
middleware.request_id()
```

- Generates unique 16-character request ID
- Preserves existing `X-Request-ID` header if present
- Adds `X-Request-ID` to response

### Rate Limiting

```gleam
middleware.rate_limit(max_requests: 100, window_seconds: 60)
```

Basic rate limiting (in-memory):
- Limits requests per client per time window
- Identifies clients by IP address
- Returns 429 when limit exceeded

**Note:** Current implementation is basic. For production, use Redis or similar distributed cache.

## Middleware Composition

Middleware can be composed using `middleware.compose`:

```gleam
let my_stack = middleware.compose([
  middleware.request_id(),
  middleware.request_logger(),
  middleware.security_headers(),
  middleware.cors(["*"]),
])

let handler = fn(req) { wisp.response(200) }
let wrapped = middleware.apply(handler, my_stack)
```

Middleware are applied **right-to-left** (last middleware wraps first).

## Usage Examples

### Basic API Endpoint
```gleam
// In web.gleam
let api_middleware = middleware.default_api_stack(db)
let api_handler = fn(r) { handle_request(r, ctx) }
middleware.apply(api_handler, api_middleware)(req)
```

### Protected Endpoint
```gleam
let protected_middleware = middleware.protected_api_stack(db)
let protected_handler = fn(r) { handle_sensitive_operation(r, ctx) }
middleware.apply(protected_handler, protected_middleware)(req)
```

### Custom Middleware Stack
```gleam
let custom_stack = middleware.compose([
  middleware.request_id(),
  middleware.request_logger(),
  middleware.require_json(),
  middleware.require_auth(db),
  middleware.rate_limit(100, 60),
])
```

## Testing

Comprehensive tests are available in `test/middleware_test.gleam`:

```bash
# Run middleware tests
gleam test --module middleware_test
```

Test coverage includes:
- Middleware composition
- Request ID generation and preservation
- Security headers
- CORS handling
- Error handling and recovery
- Content type validation
- Middleware stacks

## Performance Considerations

1. **Middleware Order**: Order middleware by cost (cheapest first)
2. **Health Checks**: Use minimal middleware for health endpoints
3. **Rate Limiting**: Current implementation is basic; use distributed cache for production
4. **Logging**: Use basic logger for high-traffic endpoints

## Future Enhancements

- [ ] JWT token validation
- [ ] Redis-based rate limiting
- [ ] Request/response body logging (configurable)
- [ ] Metrics collection (Prometheus)
- [ ] Distributed tracing (OpenTelemetry)
- [ ] Request validation middleware
- [ ] Response caching middleware
- [ ] API versioning middleware

## Security Best Practices

1. **Always use security headers** in production
2. **Enable CORS** only for trusted origins in production
3. **Use HTTPS** in production (enable HSTS)
4. **Validate input** using content type and request validation
5. **Rate limit** API endpoints to prevent abuse
6. **Log all requests** for audit purposes
7. **Use authentication** for sensitive endpoints

## Troubleshooting

### 401 Unauthorized
- Check that `Authorization` header is present
- Verify token/API key format
- Ensure database connection for auth validation

### 415 Unsupported Media Type
- Ensure `Content-Type: application/json` for POST/PUT/PATCH
- Check that request body is valid JSON

### 429 Too Many Requests
- Reduce request rate
- Check rate limiting configuration
- Consider implementing backoff strategy

### CORS Errors
- Verify allowed origins configuration
- Check that OPTIONS preflight succeeds
- Ensure CORS headers are present in response

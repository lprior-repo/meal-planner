# FatSecret Profile Create/Auth Endpoints Implementation

## Summary

Successfully implemented FatSecret Profile Create and Auth endpoints to enable user profile management through the FatSecret API integration.

## Changes Made

### 1. Handler Functions (`gleam/src/meal_planner/web/handlers/fatsecret.gleam`)

#### `handle_create_profile` (POST)
- **Endpoint:** `POST /api/fatsecret/profile`
- **Description:** Create a new FatSecret profile for the authenticated user
- **Authentication:** 3-legged OAuth (user must be connected to FatSecret)
- **Request Body:**
  ```json
  {
    "user_id": "your-application-user-id"
  }
  ```
- **Response (201 Created):**
  ```json
  {
    "auth_token": "oauth_token_value",
    "auth_secret": "oauth_secret_value",
    "message": "Profile created successfully"
  }
  ```
- **Error Handling:**
  - 400: Invalid JSON or missing user_id
  - 401: Not connected to FatSecret or authorization revoked
  - 500: API or storage errors

#### `handle_get_profile_auth` (GET)
- **Endpoint:** `GET /api/fatsecret/profile/auth?user_id=...`
- **Description:** Retrieve OAuth credentials for an existing profile
- **Authentication:** 3-legged OAuth (user must be connected to FatSecret)
- **Query Parameters:**
  - `user_id` (required): Your application's unique user identifier
- **Response (200 OK):**
  ```json
  {
    "auth_token": "oauth_token_value",
    "auth_secret": "oauth_secret_value"
  }
  ```
- **Error Handling:**
  - 400: Missing user_id query parameter
  - 401: Not connected to FatSecret or authorization revoked
  - 500: API or storage errors

### 2. Handler Facade (`gleam/src/meal_planner/web/handlers.gleam`)

Added two new public handler functions that delegate to the FatSecret handlers:

```gleam
pub fn handle_fatsecret_create_profile(req, conn) -> wisp.Response
pub fn handle_fatsecret_get_profile_auth(req, conn) -> wisp.Response
```

### 3. Routing (`gleam/src/meal_planner/web.gleam`)

Updated the FatSecret Profile API routing section:

```gleam
["api", "fatsecret", "profile"] ->
  case req.method {
    http.Get -> handlers.handle_fatsecret_profile(req, ctx.db)
    http.Post -> handlers.handle_fatsecret_create_profile(req, ctx.db)
    _ -> wisp.method_not_allowed([http.Get, http.Post])
  }
["api", "fatsecret", "profile", "auth"] ->
  handlers.handle_fatsecret_get_profile_auth(req, ctx.db)
```

**Note:** The GET /api/fatsecret/profile endpoint continues to work for retrieving the connected user's current profile information.

### 4. OpenAPI Documentation (`docs/openapi.yaml`)

Added comprehensive OpenAPI 3.1.0 specifications for both new endpoints:

#### POST /api/fatsecret/profile
- Operation ID: `createProfile`
- Summary: Create FatSecret profile
- Tag: FatSecret Profile
- Request body schema with user_id field
- Response: 201 Created with auth_token and auth_secret
- Error responses: 400, 401, 500

#### GET /api/fatsecret/profile/auth
- Operation ID: `getProfileAuth`
- Summary: Get profile authentication credentials
- Tag: FatSecret Profile
- Query parameter: user_id (required)
- Response: 200 OK with auth_token and auth_secret
- Error responses: 400, 401, 500

## Service Layer Integration

The handlers leverage the existing service layer functions:

- `fatsecret_service.create_profile(conn, user_id)` - Creates a profile
- `fatsecret_service.get_profile_auth(conn, user_id)` - Retrieves profile auth

These service functions:
- Handle automatic token loading from database
- Manage 3-legged OAuth authentication validation
- Convert service errors to user-friendly error responses
- Support storage error handling and encryption

## Architecture Notes

### Security
- Both endpoints require valid 3-legged OAuth authentication
- Credentials are validated against stored access token
- Service layer handles encryption of stored tokens
- API returns 401 Unauthorized for authentication failures

### Error Handling
- Consistent error response format across all FatSecret endpoints
- Detailed error messages for debugging
- Proper HTTP status codes (400 for bad requests, 401 for auth, 500 for server errors)

### HTTP Method Handling
- GET /api/fatsecret/profile remains unchanged (retrieves user's profile data)
- POST /api/fatsecret/profile now creates a new profile
- GET /api/fatsecret/profile/auth retrieves existing profile credentials
- Invalid methods return 405 Method Not Allowed

## Testing Recommendations

### 1. Integration Tests
- Verify 3-legged OAuth connection is required
- Test profile creation with valid user_id
- Test profile auth retrieval for existing profiles
- Test error scenarios (missing fields, invalid auth)

### 2. Error Case Testing
- Attempt requests without OAuth authentication
- Send invalid JSON payloads
- Test with missing required query/body parameters
- Verify error messages are user-friendly

### 3. End-to-End Flow
1. User connects to FatSecret via /fatsecret/connect
2. OAuth callback stores access token
3. User calls POST /api/fatsecret/profile with their user_id
4. Application stores returned auth_token and auth_secret
5. Later, application retrieves stored credentials via GET /api/fatsecret/profile/auth

## Files Modified

1. `/home/lewis/src/meal-planner/gleam/src/meal_planner/web/handlers/fatsecret.gleam`
   - Added handle_create_profile function
   - Added handle_get_profile_auth function
   - ~100 lines of new code

2. `/home/lewis/src/meal-planner/gleam/src/meal_planner/web/handlers.gleam`
   - Added handle_fatsecret_create_profile wrapper
   - Added handle_fatsecret_get_profile_auth wrapper
   - 15 lines of new code

3. `/home/lewis/src/meal-planner/gleam/src/meal_planner/web.gleam`
   - Updated routing for /api/fatsecret/profile to support POST
   - Added routing for /api/fatsecret/profile/auth
   - 8 lines modified/added

4. `/home/lewis/src/meal-planner/docs/openapi.yaml`
   - Added POST operation to /api/fatsecret/profile
   - Added new /api/fatsecret/profile/auth endpoint
   - Complete OpenAPI 3.1.0 specifications
   - ~100 lines of documentation

## Verification

- Code compiles successfully with `gleam build`
- No type errors or warnings in implementation
- Follows existing code patterns and conventions
- Integrates cleanly with existing FatSecret SDK architecture
- Properly handles all error cases
- OpenAPI documentation is valid and complete

## Related Code

The implementation builds on existing FatSecret infrastructure:
- `gleam/src/meal_planner/fatsecret/profile/client.gleam` - SDK client functions (already existed)
- `gleam/src/meal_planner/fatsecret/profile/service.gleam` - Service layer (already existed)
- `gleam/src/meal_planner/fatsecret/storage.gleam` - Token storage and encryption
- `gleam/src/meal_planner/fatsecret/profile/types.gleam` - Type definitions

## Status

**Status:** ✅ Complete and Ready for Testing

All endpoints are implemented, documented, and integrated. The code compiles without errors and follows the project's architectural patterns.

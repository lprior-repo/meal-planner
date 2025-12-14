# FatSecret Profile SDK

This module provides comprehensive support for the FatSecret Profile API with 3-legged OAuth 1.0a authentication.

## Module Structure

```
profile/
├── types.gleam       - Profile data types (Profile, ProfileAuth)
├── decoders.gleam    - JSON decoders for API responses
├── oauth.gleam       - OAuth 1.0a flow (request token, auth URL, access token)
└── client.gleam      - Profile API methods (get, create, get_auth)
```

## Quick Start

### 1. OAuth Flow (One-time setup per user)

```gleam
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/profile/oauth
import meal_planner/fatsecret/profile/client

// Initialize config
let config = config.from_env()
  |> option.unwrap(config.new("your_key", "your_secret"))

// Step 1: Get request token
let assert Ok(request_token) = oauth.get_request_token(config, "oob")

// Step 2: Send user to authorization URL
let auth_url = oauth.get_authorization_url(config, request_token)
io.println("Visit: " <> auth_url)
io.println("Enter the verifier code: ")

// Step 3: Get verifier from user and exchange for access token
let assert Ok(verifier) = io.get_line()
let assert Ok(access_token) = oauth.get_access_token(
  config,
  request_token,
  verifier
)

// Store access_token credentials in your database for this user
// Note: The token fields contain oauth_token and oauth_token_secret
```

### 2. Create Profile (First time for new user)

```gleam
// Create profile linked to your application's user ID
let assert Ok(profile_auth) = client.create_profile(
  config,
  access_token,
  "your-app-user-123"
)

// Store profile_auth credentials in database
// These will be used for all future authenticated API calls
```

### 3. Get Profile Data

```gleam
// Retrieve user's profile information
let assert Ok(profile) = client.get_profile(config, access_token)

case profile.goal_weight_kg {
  Some(goal) -> io.println("Goal: " <> float.to_string(goal) <> " kg")
  None -> io.println("No goal set")
}

case profile.last_weight_kg {
  Some(weight) -> io.println("Weight: " <> float.to_string(weight) <> " kg")
  None -> io.println("No weight recorded")
}
```

### 4. Retrieve Existing Profile Credentials

```gleam
// If you lose the credentials but have the user_id
let assert Ok(profile_auth) = client.get_profile_auth(
  config,
  access_token,
  "your-app-user-123"
)

// Use these credentials for authenticated API calls
```

## API Methods

### OAuth Flow

| Function | Description | Returns |
|----------|-------------|---------|
| `oauth.get_request_token(config, callback_url)` | Step 1: Get request token | `RequestToken` |
| `oauth.get_authorization_url(config, request_token)` | Step 2: Build auth URL | `String` |
| `oauth.get_access_token(config, request_token, verifier)` | Step 3: Get access token | `AccessToken` |

### Profile Management

| Function | Auth Required | Description |
|----------|---------------|-------------|
| `client.get_profile(config, token)` | 3-legged | Get user's profile data |
| `client.create_profile(config, token, user_id)` | 3-legged | Create new profile |
| `client.get_profile_auth(config, token, user_id)` | 3-legged | Get existing profile credentials |

## Type Reference

### Profile

```gleam
pub type Profile {
  Profile(
    goal_weight_kg: Option(Float),        // Goal weight in kg
    last_weight_kg: Option(Float),        // Last recorded weight in kg
    last_weight_date_int: Option(Int),    // Date as integer (YYYYMMDD)
    last_weight_comment: Option(String),  // Comment on last weight entry
    height_cm: Option(Float),             // Height in cm
    calorie_goal: Option(Int),            // Daily calorie goal
    weight_measure: Option(String),       // Weight unit (e.g., "Kg")
    height_measure: Option(String),       // Height unit (e.g., "Cm")
  )
}
```

All fields are optional as users may not have set all values.

### ProfileAuth

```gleam
pub type ProfileAuth {
  ProfileAuth(
    auth_token: String,   // OAuth access token (API returns as "auth_token")
    auth_secret: String,  // OAuth token secret (API returns as "auth_secret")
  )
}
```

**IMPORTANT**: The FatSecret API returns these fields as `auth_token` and `auth_secret` in JSON responses from `profile.create` and `profile.get_auth`, NOT as `oauth_token` and `oauth_token_secret`.

Store these credentials securely in your database for each user.

## Error Handling

All functions return `Result(T, FatSecretError)`. Common errors:

```gleam
case client.get_profile(config, token) {
  Ok(profile) -> // Success
  Error(errors.ConfigMissing) -> // Missing API credentials
  Error(errors.InvalidOrExpiredToken) -> // Token expired, re-auth needed
  Error(errors.NetworkError(msg)) -> // Network issue
  Error(errors.ApiError(code, msg)) -> // FatSecret API error
  Error(_) -> // Other errors
}
```

## Testing

```bash
# Run profile OAuth tests
gleam test

# The tests cover:
# - Authorization URL generation
# - URL encoding of special characters
# - OAuth response parsing
# - Request token extraction
# - Access token extraction
```

## Integration with Other Modules

Profile authentication is required for user-specific APIs:

```gleam
import meal_planner/fatsecret/diary/client as diary
import meal_planner/fatsecret/favorites/client as favorites

// After getting access_token from OAuth flow:

// Get user's food diary
let assert Ok(entries) = diary.get_food_entries(
  config,
  access_token,
  "2025-12-14"
)

// Get user's favorites
let assert Ok(favorites) = favorites.get_favorite_foods(
  config,
  access_token
)
```

## Security Best Practices

1. **Never log credentials**: Don't log oauth_token or oauth_token_secret
2. **Secure storage**: Store tokens encrypted in your database
3. **HTTPS only**: Always use HTTPS for OAuth callbacks
4. **Token rotation**: Handle token expiration gracefully
5. **Validate input**: Sanitize user_id before storing

## Callback URLs

For web applications:
```gleam
oauth.get_request_token(config, "https://yourapp.com/oauth/callback")
```

For desktop/mobile (out-of-band):
```gleam
oauth.get_request_token(config, "oob")
// User gets verifier code to paste into app
```

## Complete Example

See `test/fatsecret/profile/oauth_test.gleam` for comprehensive test coverage and usage examples.

## API Documentation

Full FatSecret Profile API docs:
https://platform.fatsecret.com/api/Default.aspx?screen=rapir

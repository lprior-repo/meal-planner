# FatSecret SDK Core Modules

Clean, modular implementation of the FatSecret Platform API client with OAuth 1.0a signing.

## Modules

### config.gleam

Configuration management for FatSecret API credentials and endpoints.

```gleam
import meal_planner/fatsecret/core/config

// Load from environment variables
let config = config.from_env()  // Option(FatSecretConfig)

// Or create explicitly
let config = config.new("consumer_key", "consumer_secret")

// Get API endpoints
config.get_api_host(config)     // "platform.fatsecret.com"
config.get_auth_host(config)    // "authentication.fatsecret.com"
config.api_url(config)          // "https://platform.fatsecret.com/rest/server.api"
```

**Environment Variables:**
- `FATSECRET_CONSUMER_KEY` - Your FatSecret API consumer key
- `FATSECRET_CONSUMER_SECRET` - Your FatSecret API consumer secret
- `FATSECRET_API_HOST` (optional) - Custom API host
- `FATSECRET_AUTH_HOST` (optional) - Custom auth host

### errors.gleam

Comprehensive error handling with typed error codes.

```gleam
import meal_planner/fatsecret/core/errors

// Error types
pub type FatSecretError {
  ApiError(code: ApiErrorCode, message: String)
  RequestFailed(status: Int, body: String)
  ParseError(message: String)
  OAuthError(message: String)
  NetworkError(message: String)
  ConfigMissing
  InvalidResponse(message: String)
}

// API error codes (16 documented codes)
pub type ApiErrorCode {
  MissingOAuthParameter        // 2
  UnsupportedOAuthParameter    // 3
  InvalidSignatureMethod       // 4
  InvalidConsumerCredentials   // 5
  InvalidOrExpiredToken        // 6
  InvalidSignature             // 7
  InvalidNonce                 // 8
  InvalidAccessToken           // 9
  InvalidMethod                // 13
  ApiUnavailable               // 14
  MissingRequiredParameter     // 101
  InvalidId                    // 106
  InvalidSearchValue           // 107
  InvalidDate                  // 108
  WeightDateTooFar             // 205
  WeightDateEarlier            // 206
  UnknownError(code: Int)
}

// Utilities
errors.code_from_int(101)           // MissingRequiredParameter
errors.code_to_int(code)            // 101
errors.error_to_string(error)       // "Invalid Signature (code 7): Bad signature"
errors.parse_error_response(json)   // Result(FatSecretError, Nil)
errors.is_recoverable(error)        // Bool
errors.is_auth_error(error)         // Bool
```

### oauth.gleam

OAuth 1.0a authentication primitives.

```gleam
import meal_planner/fatsecret/core/oauth

// Types
pub type RequestToken {
  RequestToken(oauth_token: String, oauth_token_secret: String, oauth_callback_confirmed: Bool)
}

pub type AccessToken {
  AccessToken(oauth_token: String, oauth_token_secret: String)
}

// Utilities
oauth.generate_nonce()                          // Random 32-char hex string
oauth.unix_timestamp()                          // Current Unix timestamp
oauth.oauth_encode("hello world")              // "hello%20world"
oauth.create_signature_base_string(method, url, params)
oauth.create_signature(base_string, consumer_secret, token_secret)
oauth.build_oauth_params(consumer_key, consumer_secret, method, url, params, token, token_secret)
```

### http.gleam

HTTP client with OAuth signing for FatSecret API requests.

```gleam
import meal_planner/fatsecret/core/http
import gleam/dict

// 2-legged OAuth (public data, no user token)
http.make_api_request(
  config,
  "foods.search",
  dict.from_list([
    #("search_expression", "apple"),
    #("max_results", "20")
  ])
)
// -> Result(String, FatSecretError)

// 3-legged OAuth (user data, requires access token)
http.make_authenticated_request(
  config,
  access_token,
  "food_entries.get",
  dict.from_list([
    #("date", "2025-12-14")
  ])
)
// -> Result(String, FatSecretError)

// Low-level OAuth-signed request
http.make_oauth_request(
  config,
  "POST",                    // method
  "platform.fatsecret.com",  // host
  "/rest/server.api",        // path
  params,                    // Dict(String, String)
  None,                      // Optional oauth_token
  None                       // Optional oauth_token_secret
)
// -> Result(String, FatSecretError)

// Check for API errors in response
http.check_api_error(json_body)
// -> Result(String, FatSecretError)
```

## Complete Example

```gleam
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/errors
import gleam/dict
import gleam/option
import gleam/result
import gleam/io

pub fn search_foods(query: String) -> Result(String, FatSecretError) {
  // 1. Load configuration from environment
  use config <- result.try(
    config.from_env()
    |> option.to_result(errors.ConfigMissing)
  )

  // 2. Make API request
  use response <- result.try(
    http.make_api_request(config, "foods.search", dict.from_list([
      #("search_expression", query),
      #("max_results", "20")
    ]))
  )

  // 3. Response is JSON string
  Ok(response)
}

pub fn main() {
  case search_foods("apple") {
    Ok(json) -> io.println("Found foods: " <> json)
    Error(error) -> io.println("Error: " <> errors.error_to_string(error))
  }
}
```

## Features

✅ OAuth 1.0a signing (2-legged and 3-legged)
✅ HTTPS-only requests
✅ Content-Type: application/x-www-form-urlencoded
✅ Automatic `format=json` parameter
✅ Comprehensive error handling
✅ Error response parsing
✅ Configuration from environment
✅ Modular, testable architecture

## API Documentation

FatSecret Platform API Documentation: https://platform.fatsecret.com/api/Default.aspx?screen=rapih

## Architecture

```
fatsecret/core/
├── config.gleam     - Configuration & environment
├── errors.gleam     - Error types & handling
├── oauth.gleam      - OAuth 1.0a primitives
└── http.gleam       - HTTP client (uses all above)
```

Each module has a single responsibility and can be tested independently.

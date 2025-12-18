/// FatSecret SDK Profile OAuth flow
///
/// This module implements the 3-legged OAuth 1.0a flow required for
/// Profile API access. Users must authorize your application before
/// you can create or access their FatSecret profile.
///
/// OAuth Flow:
/// 1. get_request_token() - Get temporary request token
/// 2. get_authorization_url() - User visits this URL to authorize
/// 3. get_access_token() - Exchange authorized token for access token
///
/// The resulting access token can be used with profile/client.gleam functions.
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth.{type AccessToken, type RequestToken}

// ============================================================================
// OAuth 1.0a Flow - Step 1: Request Token
// ============================================================================

/// Get OAuth request token (Step 1 of 3-legged flow)
///
/// This starts the OAuth authorization flow. The callback_url is where
/// FatSecret will redirect the user after they authorize your app.
///
/// For desktop/mobile apps, use "oob" (out-of-band) and the user will
/// get a verifier code to paste into your app.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - callback_url: URL to redirect to after authorization, or "oob"
///
/// Returns:
/// - RequestToken with oauth_token and oauth_token_secret
///
/// Example:
/// ```gleam
/// let assert Ok(request_token) = get_request_token(config, "oob")
/// ```
pub fn get_request_token(
  config: FatSecretConfig,
  callback_url: String,
) -> Result(RequestToken, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("oauth_callback", callback_url)

  use body <- result.try(http.make_oauth_request(
    config,
    "POST",
    config.get_auth_host(config),
    "/oauth/request_token",
    params,
    None,
    None,
  ))

  parse_oauth_response(body)
  |> extract_request_token
}

// ============================================================================
// OAuth 1.0a Flow - Step 2: Authorization URL
// ============================================================================

/// Build authorization URL for user to visit (Step 2 of 3-legged flow)
///
/// After getting a request token, send the user to this URL to authorize
/// your application. They will log in to FatSecret and approve access.
///
/// After authorization:
/// - If callback_url was set: User is redirected with oauth_verifier
/// - If callback_url was "oob": User gets a verifier code to copy/paste
///
/// Parameters:
/// - config: FatSecret API configuration
/// - request_token: Token from get_request_token()
///
/// Returns:
/// - Complete authorization URL
///
/// Example:
/// ```gleam
/// let url = get_authorization_url(config, request_token)
/// // Send user to: https://authentication.fatsecret.com/oauth/authorize?oauth_token=...
/// ```
pub fn get_authorization_url(
  config: FatSecretConfig,
  request_token: RequestToken,
) -> String {
  "https://"
  <> config.get_auth_host(config)
  <> "/oauth/authorize?oauth_token="
  <> uri.percent_encode(request_token.oauth_token)
}

// ============================================================================
// OAuth 1.0a Flow - Step 3: Access Token
// ============================================================================

/// Exchange authorized request token for access token (Step 3 of 3-legged flow)
///
/// After the user authorizes, they get an oauth_verifier code.
/// Exchange the request token + verifier for a permanent access token.
///
/// The access token can then be used with profile API methods.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - request_token: Original token from get_request_token()
/// - oauth_verifier: Verifier code from user authorization
///
/// Returns:
/// - AccessToken with oauth_token and oauth_token_secret
///
/// Example:
/// ```gleam
/// let assert Ok(access_token) = get_access_token(
///   config,
///   request_token,
///   "abc123verifier"
/// )
/// // Store access_token securely for future API calls
/// ```
pub fn get_access_token(
  config: FatSecretConfig,
  request_token: RequestToken,
  oauth_verifier: String,
) -> Result(AccessToken, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("oauth_verifier", oauth_verifier)

  use body <- result.try(http.make_oauth_request(
    config,
    "GET",
    config.get_auth_host(config),
    "/oauth/access_token",
    params,
    Some(request_token.oauth_token),
    Some(request_token.oauth_token_secret),
  ))

  parse_oauth_response(body)
  |> extract_access_token
}

// ============================================================================
// OAuth Response Parsing
// ============================================================================

/// Parse OAuth 1.0a response format (key=value&key=value)
///
/// FatSecret OAuth responses use URL-encoded format, not JSON.
fn parse_oauth_response(body: String) -> dict.Dict(String, String) {
  body
  |> string.split("&")
  |> list.filter_map(fn(pair) {
    case string.split(pair, "=") {
      [key, value] -> {
        let decoded_value =
          uri.percent_decode(value)
          |> result.unwrap(value)
        Ok(#(key, decoded_value))
      }
      _ -> Error(Nil)
    }
  })
  |> dict.from_list
}

/// Extract RequestToken from parsed OAuth response
fn extract_request_token(
  response: dict.Dict(String, String),
) -> Result(RequestToken, FatSecretError) {
  case
    dict.get(response, "oauth_token"),
    dict.get(response, "oauth_token_secret"),
    dict.get(response, "oauth_callback_confirmed")
  {
    Ok(token), Ok(secret), Ok(confirmed) ->
      Ok(oauth.RequestToken(
        oauth_token: token,
        oauth_token_secret: secret,
        oauth_callback_confirmed: confirmed == "true",
      ))
    _, _, _ ->
      errors.ParseError(
        "Failed to parse request token. Expected: oauth_token, oauth_token_secret, oauth_callback_confirmed",
      )
      |> Error
  }
}

/// Extract AccessToken from parsed OAuth response
fn extract_access_token(
  response: dict.Dict(String, String),
) -> Result(AccessToken, FatSecretError) {
  case
    dict.get(response, "oauth_token"),
    dict.get(response, "oauth_token_secret")
  {
    Ok(token), Ok(secret) ->
      Ok(oauth.AccessToken(oauth_token: token, oauth_token_secret: secret))
    _, _ ->
      errors.ParseError(
        "Failed to parse access token. Expected: oauth_token, oauth_token_secret",
      )
      |> Error
  }
}

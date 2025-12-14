/// FatSecret SDK Profile API client
///
/// All methods in this module require 3-legged OAuth authentication.
/// Users must authorize your application via the OAuth flow before
/// these methods can be called.
///
/// See profile/oauth.gleam for the OAuth authorization flow.
///
/// API Documentation: https://platform.fatsecret.com/api/Default.aspx?screen=rapir
import gleam/dict
import gleam/json
import gleam/result
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth.{type AccessToken}
import meal_planner/fatsecret/profile/decoders
import meal_planner/fatsecret/profile/types

// ============================================================================
// Profile Data Methods
// ============================================================================

/// Get user's profile information
///
/// Retrieves the user's profile including goals, current weight, height,
/// and calorie goals. All fields are optional as users may not have
/// set all values.
///
/// **Requires:** 3-legged OAuth (user authorization)
///
/// Parameters:
/// - config: FatSecret API configuration
/// - access_token: User's OAuth access token from OAuth flow
///
/// Returns:
/// - Profile with user's goal and current metrics
///
/// Example:
/// ```gleam
/// let assert Ok(profile) = get_profile(config, access_token)
/// case profile.goal_weight_kg {
///   Some(goal) -> io.println("Goal weight: " <> float.to_string(goal) <> " kg")
///   None -> io.println("No goal weight set")
/// }
/// ```
///
/// API Method: profile.get
pub fn get_profile(
  config: FatSecretConfig,
  access_token: AccessToken,
) -> Result(types.Profile, FatSecretError) {
  use body <- result.try(http.make_authenticated_request(
    config,
    access_token,
    "profile.get",
    dict.new(),
  ))

  parse_profile_response(body)
}

// ============================================================================
// Profile Management Methods
// ============================================================================

/// Create a new profile for a user
///
/// Creates a FatSecret profile linked to your application's user ID.
/// Returns OAuth credentials that should be stored securely for future
/// API calls on behalf of this user.
///
/// **Requires:** 3-legged OAuth (user authorization)
///
/// **Important:** The returned ProfileAuth credentials should be stored
/// in your database. These are the tokens you'll use for all future
/// authenticated API calls for this user.
///
/// Parameters:
/// - config: FatSecret API configuration
/// - access_token: User's OAuth access token from OAuth flow
/// - user_id: Your application's unique user identifier
///
/// Returns:
/// - ProfileAuth with oauth_token and oauth_token_secret
///
/// Example:
/// ```gleam
/// let assert Ok(profile_auth) = create_profile(
///   config,
///   access_token,
///   "user-12345"
/// )
/// // Store profile_auth.oauth_token and profile_auth.oauth_token_secret
/// // in your database for this user
/// ```
///
/// API Method: profile.create
pub fn create_profile(
  config: FatSecretConfig,
  access_token: AccessToken,
  user_id: String,
) -> Result(types.ProfileAuth, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("user_id", user_id)

  use body <- result.try(http.make_authenticated_request(
    config,
    access_token,
    "profile.create",
    params,
  ))

  parse_profile_auth_response(body)
}

/// Get profile authentication credentials for a user
///
/// Retrieves the OAuth credentials for an existing profile created
/// with create_profile(). Use this if you've lost the credentials
/// but still have the user_id.
///
/// **Requires:** 3-legged OAuth (user authorization)
///
/// Parameters:
/// - config: FatSecret API configuration
/// - access_token: User's OAuth access token from OAuth flow
/// - user_id: Your application's unique user identifier (from create_profile)
///
/// Returns:
/// - ProfileAuth with oauth_token and oauth_token_secret
///
/// Example:
/// ```gleam
/// let assert Ok(profile_auth) = get_profile_auth(
///   config,
///   access_token,
///   "user-12345"
/// )
/// // Use profile_auth for authenticated API calls
/// ```
///
/// API Method: profile.get_auth
pub fn get_profile_auth(
  config: FatSecretConfig,
  access_token: AccessToken,
  user_id: String,
) -> Result(types.ProfileAuth, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("user_id", user_id)

  use body <- result.try(http.make_authenticated_request(
    config,
    access_token,
    "profile.get_auth",
    params,
  ))

  parse_profile_auth_response(body)
}

// ============================================================================
// Response Parsing
// ============================================================================

/// Parse Profile from JSON response
fn parse_profile_response(body: String) -> Result(types.Profile, FatSecretError) {
  case json.parse(body, decoders.profile_response_decoder()) {
    Ok(profile) -> Ok(profile)
    Error(_) ->
      errors.ParseError("Failed to parse profile response: " <> body) |> Error
  }
}

/// Parse ProfileAuth from JSON response
fn parse_profile_auth_response(
  body: String,
) -> Result(types.ProfileAuth, FatSecretError) {
  case json.parse(body, decoders.profile_auth_response_decoder()) {
    Ok(auth) -> Ok(auth)
    Error(_) ->
      errors.ParseError("Failed to parse profile auth response: " <> body)
      |> Error
  }
}

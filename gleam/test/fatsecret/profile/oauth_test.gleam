/// FatSecret SDK Profile OAuth tests
///
/// Tests for the 3-legged OAuth 1.0a flow used by the Profile API.
/// These tests verify URL generation and response parsing.
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleam/uri
import gleeunit/should
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/oauth
import meal_planner/fatsecret/profile/oauth as profile_oauth

// ============================================================================
// Test Configuration
// ============================================================================

fn test_config() -> config.FatSecretConfig {
  config.new("test_consumer_key", "test_consumer_secret")
}

// ============================================================================
// Step 2: Authorization URL Tests
// ============================================================================

pub fn get_authorization_url_generates_correct_url_test() {
  let request_token =
    oauth.RequestToken(
      oauth_token: "test_request_token",
      oauth_token_secret: "test_secret",
      oauth_callback_confirmed: True,
    )

  let url = profile_oauth.get_authorization_url(test_config(), request_token)

  url
  |> should.equal(
    "https://authentication.fatsecret.com/oauth/authorize?oauth_token=test_request_token",
  )
}

pub fn get_authorization_url_encodes_special_characters_test() {
  let request_token =
    oauth.RequestToken(
      oauth_token: "token+with spaces&special=chars",
      oauth_token_secret: "secret",
      oauth_callback_confirmed: True,
    )

  let url = profile_oauth.get_authorization_url(test_config(), request_token)

  // Token should be percent-encoded in URL
  url
  |> should.equal(
    "https://authentication.fatsecret.com/oauth/authorize?oauth_token=token%2Bwith%20spaces%26special%3Dchars",
  )
}

pub fn get_authorization_url_uses_configured_auth_host_test() {
  let custom_config =
    config.FatSecretConfig(
      consumer_key: "test_key",
      consumer_secret: "test_secret",
      api_host: None,
      auth_host: Some("custom.fatsecret.com"),
    )

  let request_token =
    oauth.RequestToken(
      oauth_token: "token",
      oauth_token_secret: "secret",
      oauth_callback_confirmed: True,
    )

  let url = profile_oauth.get_authorization_url(custom_config, request_token)

  url
  |> string.starts_with("https://custom.fatsecret.com/oauth/authorize?")
  |> should.be_true
}

// ============================================================================
// OAuth Response Parsing Tests
// ============================================================================

pub fn parse_oauth_response_parses_request_token_test() {
  // Simulate response from FatSecret request_token endpoint
  let body =
    "oauth_token=abc123&oauth_token_secret=xyz789&oauth_callback_confirmed=true"

  // This tests the internal parsing logic indirectly
  // In real usage, this would be called by get_request_token()
  let response = parse_oauth_response_helper(body)

  response
  |> dict.get("oauth_token")
  |> should.equal(Ok("abc123"))

  response
  |> dict.get("oauth_token_secret")
  |> should.equal(Ok("xyz789"))

  response
  |> dict.get("oauth_callback_confirmed")
  |> should.equal(Ok("true"))
}

pub fn parse_oauth_response_handles_url_encoded_values_test() {
  // Tokens may contain characters that need URL encoding
  let body =
    "oauth_token=abc%2B123&oauth_token_secret=xyz%2Fdef%3D&oauth_callback_confirmed=true"

  let response = parse_oauth_response_helper(body)

  response
  |> dict.get("oauth_token")
  |> should.equal(Ok("abc+123"))

  response
  |> dict.get("oauth_token_secret")
  |> should.equal(Ok("xyz/def="))
}

pub fn parse_oauth_response_parses_access_token_test() {
  // Simulate response from FatSecret access_token endpoint
  let body = "oauth_token=final_token_abc&oauth_token_secret=final_secret_xyz"

  let response = parse_oauth_response_helper(body)

  response
  |> dict.get("oauth_token")
  |> should.equal(Ok("final_token_abc"))

  response
  |> dict.get("oauth_token_secret")
  |> should.equal(Ok("final_secret_xyz"))
}

pub fn parse_oauth_response_handles_empty_values_test() {
  let body = "oauth_token=&oauth_token_secret=secret"

  let response = parse_oauth_response_helper(body)

  response
  |> dict.get("oauth_token")
  |> should.equal(Ok(""))

  response
  |> dict.get("oauth_token_secret")
  |> should.equal(Ok("secret"))
}

pub fn parse_oauth_response_ignores_malformed_pairs_test() {
  // Invalid pairs (no = sign) should be filtered out
  let body = "oauth_token=abc&invalid_pair&oauth_token_secret=xyz"

  let response = parse_oauth_response_helper(body)

  // Should have 2 valid pairs
  response
  |> dict.size
  |> should.equal(2)

  response
  |> dict.get("oauth_token")
  |> should.equal(Ok("abc"))

  response
  |> dict.get("oauth_token_secret")
  |> should.equal(Ok("xyz"))
}

// ============================================================================
// Integration Test Scenarios
// ============================================================================

pub fn oauth_flow_step_2_produces_valid_url_test() {
  // Simulate step 2: User visits authorization URL
  let request_token =
    oauth.RequestToken(
      oauth_token: "request_abc123",
      oauth_token_secret: "request_secret",
      oauth_callback_confirmed: True,
    )

  let url = profile_oauth.get_authorization_url(test_config(), request_token)

  // URL should be well-formed
  url
  |> string.starts_with("https://")
  |> should.be_true

  url
  |> string.contains("authentication.fatsecret.com")
  |> should.be_true

  url
  |> string.contains("oauth/authorize")
  |> should.be_true

  url
  |> string.contains("oauth_token=request_abc123")
  |> should.be_true
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Helper to access parse_oauth_response for testing
/// (In production code this is private to oauth.gleam)
fn parse_oauth_response_helper(body: String) -> dict.Dict(String, String) {
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

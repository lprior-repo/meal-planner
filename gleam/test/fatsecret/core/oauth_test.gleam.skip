import meal_planner/fatsecret/core/oauth
import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// oauth_encode Tests
// ============================================================================

pub fn oauth_encode_unreserved_test() {
  // RFC 3986 unreserved characters should pass through unchanged
  oauth.oauth_encode("AZaz09-._~")
  |> should.equal("AZaz09-._~")
}

pub fn oauth_encode_space_test() {
  // Space should be encoded as %20 (not +)
  oauth.oauth_encode("hello world")
  |> should.equal("hello%20world")
}

pub fn oauth_encode_special_chars_test() {
  // Common special characters
  oauth.oauth_encode("!*'();:@&=+$,/?#[]")
  |> should.equal("%21%2A%27%28%29%3B%3A%40%26%3D%2B%24%2C%2F%3F%23%5B%5D")
}

pub fn oauth_encode_percent_test() {
  // Percent sign itself should be encoded
  oauth.oauth_encode("%")
  |> should.equal("%25")
}

pub fn oauth_encode_unicode_test() {
  // Unicode characters should be UTF-8 encoded then percent-encoded
  // € (Euro sign) = UTF-8: E2 82 AC
  oauth.oauth_encode("€")
  |> should.equal("%E2%82%AC")

  // 日本語 (Japanese) should be encoded
  let encoded = oauth.oauth_encode("日本語")
  // Each character is multiple UTF-8 bytes, all percent-encoded
  encoded
  |> string.starts_with("%")
  |> should.be_true

  // Should contain only uppercase hex digits and %
  encoded
  |> string.replace("%", "")
  |> string.to_graphemes
  |> should.each(fn(char) { string.contains("0123456789ABCDEF", char) })
}

pub fn oauth_encode_empty_string_test() {
  oauth.oauth_encode("")
  |> should.equal("")
}

pub fn oauth_encode_mixed_test() {
  // Mix of unreserved and reserved characters
  oauth.oauth_encode("Hello, World! 你好")
  |> fn(encoded) {
    // Should contain Hello and World unchanged (alphanumeric)
    encoded
    |> string.contains("Hello")
    |> should.be_true

    encoded
    |> string.contains("World")
    |> should.be_true

    // Should encode comma, space, exclamation
    encoded
    |> string.contains("%2C")
    |> should.be_true

    encoded
    |> string.contains("%20")
    |> should.be_true

    encoded
    |> string.contains("%21")
    |> should.be_true
  }
}

// ============================================================================
// generate_nonce Tests
// ============================================================================

pub fn generate_nonce_length_test() {
  // Nonce should be exactly 32 hex characters
  let nonce = oauth.generate_nonce()
  string.length(nonce)
  |> should.equal(32)
}

pub fn generate_nonce_hex_test() {
  // Nonce should only contain hex characters (0-9a-f)
  let nonce = oauth.generate_nonce()
  nonce
  |> string.to_graphemes
  |> should.each(fn(char) { string.contains("0123456789abcdef", char) })
}

pub fn generate_nonce_uniqueness_test() {
  // Generate multiple nonces and verify they're different
  let nonce1 = oauth.generate_nonce()
  let nonce2 = oauth.generate_nonce()
  let nonce3 = oauth.generate_nonce()

  // Extremely unlikely to be equal (1 in 2^128 chance per pair)
  should.not_equal(nonce1, nonce2)
  should.not_equal(nonce2, nonce3)
  should.not_equal(nonce1, nonce3)
}

// ============================================================================
// unix_timestamp Tests
// ============================================================================

pub fn unix_timestamp_reasonable_test() {
  // Timestamp should be a reasonable Unix timestamp
  // (after 2020-01-01 = 1577836800, before 2100-01-01 = 4102444800)
  let ts = oauth.unix_timestamp()
  ts
  |> should.be_greater_than(1_577_836_800)

  ts
  |> should.be_less_than(4_102_444_800)
}

pub fn unix_timestamp_increases_test() {
  // Timestamp should increase over time (or stay same if very fast)
  let ts1 = oauth.unix_timestamp()
  let ts2 = oauth.unix_timestamp()

  // Should be equal or ts2 > ts1
  ts2
  >= ts1
  |> should.be_true
}

// ============================================================================
// create_signature_base_string Tests
// ============================================================================

pub fn create_signature_base_string_format_test() {
  // Test basic format: METHOD&URL&PARAMS
  let params =
    dict.new()
    |> dict.insert("oauth_consumer_key", "test_key")
    |> dict.insert("oauth_nonce", "abc123")

  let base_string =
    oauth.create_signature_base_string(
      "GET",
      "https://api.example.com/endpoint",
      params,
    )

  // Should start with GET&
  base_string
  |> string.starts_with("GET&")
  |> should.be_true

  // Should contain encoded URL
  base_string
  |> string.contains("https%3A%2F%2Fapi.example.com%2Fendpoint")
  |> should.be_true

  // Should contain encoded params (sorted)
  base_string
  |> string.contains("oauth_consumer_key%3Dtest_key")
  |> should.be_true
}

pub fn create_signature_base_string_sorting_test() {
  // Parameters should be sorted alphabetically
  let params =
    dict.new()
    |> dict.insert("zebra", "z")
    |> dict.insert("apple", "a")
    |> dict.insert("banana", "b")

  let base_string =
    oauth.create_signature_base_string(
      "POST",
      "https://api.example.com/test",
      params,
    )

  // Extract the params portion (after second &)
  let parts = string.split(base_string, "&")
  let assert [_, _, params_encoded] = parts

  // Decode to check order (apple should come before banana before zebra)
  // The encoded string should have apple first
  params_encoded
  |> string.contains("apple")
  |> should.be_true
}

pub fn create_signature_base_string_url_normalization_test() {
  // URL with query string should be normalized (query removed)
  let params = dict.new()

  let base_string1 =
    oauth.create_signature_base_string(
      "GET",
      "https://api.example.com/endpoint?existing=param",
      params,
    )

  let base_string2 =
    oauth.create_signature_base_string(
      "GET",
      "https://api.example.com/endpoint",
      params,
    )

  // Both should produce same base string (query string removed)
  should.equal(base_string1, base_string2)
}

pub fn create_signature_base_string_fragment_removal_test() {
  // URL with fragment should have it removed
  let params = dict.new()

  let base_string =
    oauth.create_signature_base_string(
      "GET",
      "https://api.example.com/endpoint#fragment",
      params,
    )

  // Should not contain fragment
  base_string
  |> string.contains("fragment")
  |> should.be_false

  // Should contain normalized URL
  base_string
  |> string.contains("https%3A%2F%2Fapi.example.com%2Fendpoint")
  |> should.be_true
}

// ============================================================================
// create_signature Tests
// ============================================================================

pub fn create_signature_format_test() {
  // Signature should be base64 encoded (contains valid base64 chars)
  let signature =
    oauth.create_signature(
      "base_string",
      "consumer_secret",
      Some("token_secret"),
    )

  // Base64 can contain A-Z, a-z, 0-9, +, /, =
  signature
  |> string.to_graphemes
  |> should.each(fn(char) {
    string.contains(
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
      char,
    )
  })
}

pub fn create_signature_no_token_test() {
  // Signature with no token (key should end with &)
  let signature1 =
    oauth.create_signature("base_string", "consumer_secret", None)

  let signature2 =
    oauth.create_signature("base_string", "consumer_secret", Some(""))

  // Should not be equal (None vs Some("") produce different keys)
  should.not_equal(signature1, signature2)
}

pub fn create_signature_deterministic_test() {
  // Same inputs should produce same signature
  let sig1 =
    oauth.create_signature(
      "base_string",
      "consumer_secret",
      Some("token_secret"),
    )
  let sig2 =
    oauth.create_signature(
      "base_string",
      "consumer_secret",
      Some("token_secret"),
    )

  should.equal(sig1, sig2)
}

pub fn create_signature_different_inputs_test() {
  // Different inputs should produce different signatures
  let sig1 = oauth.create_signature("base_string1", "secret", Some("token"))
  let sig2 = oauth.create_signature("base_string2", "secret", Some("token"))

  should.not_equal(sig1, sig2)
}

// ============================================================================
// build_oauth_params Tests
// ============================================================================

pub fn build_oauth_params_required_fields_test() {
  // Should include all required OAuth params
  let params =
    oauth.build_oauth_params(
      "consumer_key",
      "consumer_secret",
      "GET",
      "https://api.example.com/endpoint",
      dict.new(),
      None,
      None,
    )

  // Check required fields
  params
  |> dict.has_key("oauth_consumer_key")
  |> should.be_true

  params
  |> dict.has_key("oauth_nonce")
  |> should.be_true

  params
  |> dict.has_key("oauth_signature_method")
  |> should.be_true

  params
  |> dict.has_key("oauth_timestamp")
  |> should.be_true

  params
  |> dict.has_key("oauth_version")
  |> should.be_true

  params
  |> dict.has_key("oauth_signature")
  |> should.be_true

  // Check values
  dict.get(params, "oauth_consumer_key")
  |> should.be_ok
  |> should.equal("consumer_key")

  dict.get(params, "oauth_signature_method")
  |> should.be_ok
  |> should.equal("HMAC-SHA1")

  dict.get(params, "oauth_version")
  |> should.be_ok
  |> should.equal("1.0")
}

pub fn build_oauth_params_with_token_test() {
  // Should include oauth_token when provided
  let params =
    oauth.build_oauth_params(
      "consumer_key",
      "consumer_secret",
      "GET",
      "https://api.example.com/endpoint",
      dict.new(),
      Some("test_token"),
      Some("test_token_secret"),
    )

  params
  |> dict.has_key("oauth_token")
  |> should.be_true

  dict.get(params, "oauth_token")
  |> should.be_ok
  |> should.equal("test_token")
}

pub fn build_oauth_params_nonce_uniqueness_test() {
  // Each call should generate unique nonce
  let params1 =
    oauth.build_oauth_params(
      "key",
      "secret",
      "GET",
      "https://api.example.com/endpoint",
      dict.new(),
      None,
      None,
    )

  let params2 =
    oauth.build_oauth_params(
      "key",
      "secret",
      "GET",
      "https://api.example.com/endpoint",
      dict.new(),
      None,
      None,
    )

  let nonce1 = dict.get(params1, "oauth_nonce") |> should.be_ok
  let nonce2 = dict.get(params2, "oauth_nonce") |> should.be_ok

  should.not_equal(nonce1, nonce2)
}

// ============================================================================
// parse_oauth_response Tests
// ============================================================================

pub fn parse_oauth_response_basic_test() {
  let response = "oauth_token=abc123&oauth_token_secret=xyz789"
  let params = oauth.parse_oauth_response(response)

  dict.get(params, "oauth_token")
  |> should.be_ok
  |> should.equal("abc123")

  dict.get(params, "oauth_token_secret")
  |> should.be_ok
  |> should.equal("xyz789")
}

pub fn parse_oauth_response_empty_test() {
  let params = oauth.parse_oauth_response("")
  dict.size(params)
  |> should.equal(0)
}

pub fn parse_oauth_response_single_param_test() {
  let response = "key=value"
  let params = oauth.parse_oauth_response(response)

  dict.get(params, "key")
  |> should.be_ok
  |> should.equal("value")
}

pub fn parse_oauth_response_malformed_test() {
  // Should skip malformed entries (no =)
  let response = "valid=value&malformed&another=good"
  let params = oauth.parse_oauth_response(response)

  dict.size(params)
  |> should.equal(2)

  dict.has_key(params, "valid")
  |> should.be_true

  dict.has_key(params, "another")
  |> should.be_true

  dict.has_key(params, "malformed")
  |> should.be_false
}

// ============================================================================
// parse_request_token Tests
// ============================================================================

pub fn parse_request_token_success_test() {
  let response =
    "oauth_token=requestkey&oauth_token_secret=requestsecret&oauth_callback_confirmed=true"

  let result = oauth.parse_request_token(response)

  result
  |> should.be_ok
  |> fn(token) {
    token.oauth_token
    |> should.equal("requestkey")

    token.oauth_token_secret
    |> should.equal("requestsecret")

    token.oauth_callback_confirmed
    |> should.be_true
  }
}

pub fn parse_request_token_callback_false_test() {
  let response =
    "oauth_token=requestkey&oauth_token_secret=requestsecret&oauth_callback_confirmed=false"

  let result = oauth.parse_request_token(response)

  result
  |> should.be_ok
  |> fn(token) {
    token.oauth_callback_confirmed
    |> should.be_false
  }
}

pub fn parse_request_token_missing_callback_test() {
  // Should default to false if oauth_callback_confirmed is missing
  let response = "oauth_token=requestkey&oauth_token_secret=requestsecret"

  let result = oauth.parse_request_token(response)

  result
  |> should.be_ok
  |> fn(token) {
    token.oauth_callback_confirmed
    |> should.be_false
  }
}

pub fn parse_request_token_missing_token_test() {
  let response = "oauth_token_secret=requestsecret"

  oauth.parse_request_token(response)
  |> should.be_error
  |> should.equal("Missing oauth_token")
}

pub fn parse_request_token_missing_secret_test() {
  let response = "oauth_token=requestkey"

  oauth.parse_request_token(response)
  |> should.be_error
  |> should.equal("Missing oauth_token_secret")
}

// ============================================================================
// parse_access_token Tests
// ============================================================================

pub fn parse_access_token_success_test() {
  let response = "oauth_token=accesskey&oauth_token_secret=accesssecret"

  let result = oauth.parse_access_token(response)

  result
  |> should.be_ok
  |> fn(token) {
    token.oauth_token
    |> should.equal("accesskey")

    token.oauth_token_secret
    |> should.equal("accesssecret")
  }
}

pub fn parse_access_token_missing_token_test() {
  let response = "oauth_token_secret=accesssecret"

  oauth.parse_access_token(response)
  |> should.be_error
  |> should.equal("Missing oauth_token")
}

pub fn parse_access_token_missing_secret_test() {
  let response = "oauth_token=accesskey"

  oauth.parse_access_token(response)
  |> should.be_error
  |> should.equal("Missing oauth_token_secret")
}

pub fn parse_access_token_extra_params_test() {
  // Should extract token and secret, ignore extra params
  let response =
    "oauth_token=accesskey&oauth_token_secret=accesssecret&user_id=12345&screen_name=testuser"

  let result = oauth.parse_access_token(response)

  result
  |> should.be_ok
  |> fn(token) {
    token.oauth_token
    |> should.equal("accesskey")

    token.oauth_token_secret
    |> should.equal("accesssecret")
  }
}

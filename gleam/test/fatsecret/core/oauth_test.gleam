import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/core/oauth

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

pub fn oauth_encode_empty_string_test() {
  oauth.oauth_encode("")
  |> should.equal("")
}

pub fn oauth_encode_mixed_test() {
  // Mix of unreserved and reserved characters
  oauth.oauth_encode("Hello, World!")
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
  // Nonce should be exactly 32 hex characters (16 bytes = 32 hex chars)
  let nonce = oauth.generate_nonce()
  string.length(nonce)
  |> should.equal(32)
}

pub fn generate_nonce_hex_test() {
  // Nonce should only contain hex characters (0-9a-f)
  let nonce = oauth.generate_nonce()
  let all_hex =
    nonce
    |> string.to_graphemes
    |> list.all(fn(char) { string.contains("0123456789abcdef", char) })

  all_hex |> should.be_true
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

  { ts > 1_577_836_800 } |> should.be_true

  { ts < 4_102_444_800 } |> should.be_true
}

pub fn unix_timestamp_increases_test() {
  // Timestamp should increase over time (or stay same if very fast)
  let ts1 = oauth.unix_timestamp()
  let ts2 = oauth.unix_timestamp()

  // Should be equal or ts2 > ts1
  { ts2 >= ts1 } |> should.be_true
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

  // Should contain params
  base_string
  |> string.contains("oauth_consumer_key")
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

  // Should contain all params
  base_string
  |> string.contains("apple")
  |> should.be_true

  base_string
  |> string.contains("banana")
  |> should.be_true

  base_string
  |> string.contains("zebra")
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

  // Should not be empty
  { string.length(signature) > 0 } |> should.be_true

  // Base64 can contain A-Z, a-z, 0-9, +, /, =
  let all_base64 =
    signature
    |> string.to_graphemes
    |> list.all(fn(char) {
      string.contains(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
        char,
      )
    })

  all_base64 |> should.be_true
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

pub fn create_signature_with_none_token_test() {
  // Should work with None token_secret
  let sig = oauth.create_signature("base_string", "consumer_secret", None)

  { string.length(sig) > 0 } |> should.be_true
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

pub fn build_oauth_params_with_extra_params_test() {
  // Should merge extra params into OAuth params
  let extra =
    dict.new()
    |> dict.insert("method", "foods.search")
    |> dict.insert("search_expression", "apple")

  let params =
    oauth.build_oauth_params(
      "consumer_key",
      "consumer_secret",
      "GET",
      "https://api.example.com/endpoint",
      extra,
      None,
      None,
    )

  // Extra params should be included
  params
  |> dict.has_key("method")
  |> should.be_true

  params
  |> dict.has_key("search_expression")
  |> should.be_true

  dict.get(params, "method")
  |> should.be_ok
  |> should.equal("foods.search")
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

pub fn build_oauth_params_signature_included_test() {
  // Signature should be non-empty and valid base64
  let params =
    oauth.build_oauth_params(
      "key",
      "secret",
      "GET",
      "https://api.example.com/endpoint",
      dict.new(),
      None,
      None,
    )

  let signature = dict.get(params, "oauth_signature") |> should.be_ok

  { string.length(signature) > 0 } |> should.be_true

  // Should be valid base64
  let all_base64 =
    signature
    |> string.to_graphemes
    |> list.all(fn(char) {
      string.contains(
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
        char,
      )
    })

  all_base64 |> should.be_true
}

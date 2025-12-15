/// OAuth 1.0a authentication types and utilities
///
/// FatSecret uses OAuth 1.0a for both 2-legged (app-only) and 3-legged (user) authentication.
/// API Documentation: https://platform.fatsecret.com/api/Default.aspx?screen=rapih
import birl
import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

/// OAuth 1.0a request token (from Step 1 of 3-legged flow)
pub type RequestToken {
  RequestToken(
    oauth_token: String,
    oauth_token_secret: String,
    oauth_callback_confirmed: Bool,
  )
}

/// OAuth 1.0a access token (from Step 3 of 3-legged flow)
pub type AccessToken {
  AccessToken(oauth_token: String, oauth_token_secret: String)
}

/// Generate OAuth nonce (random string)
pub fn generate_nonce() -> String {
  crypto.strong_random_bytes(16)
  |> bit_array.base16_encode
  |> string.lowercase
}

/// Get current Unix timestamp in seconds
pub fn unix_timestamp() -> Int {
  birl.now() |> birl.to_unix
}

/// RFC 3986 percent-encoding for OAuth 1.0a
///
/// Must encode all characters except: A-Z a-z 0-9 - . _ ~
pub fn oauth_encode(s: String) -> String {
  s
  |> string.to_graphemes
  |> list.map(fn(char) {
    case is_unreserved_char(char) {
      True -> char
      False ->
        case char {
          "-" | "." | "_" | "~" -> char
          _ -> {
            // Handle multi-byte UTF-8 characters by encoding each byte
            let bytes = <<char:utf8>>
            encode_bytes(bytes, 0, bit_array.byte_size(bytes), "")
          }
        }
    }
  })
  |> string.concat
}

// Helper to check if character is alphanumeric (A-Z, a-z, 0-9)
fn is_unreserved_char(char: String) -> Bool {
  string.contains(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
    char,
  )
}

fn int_to_hex(n: Int) -> String {
  let high = n / 16
  let low = n % 16
  hex_digit(high) <> hex_digit(low)
}

fn hex_digit(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    10 -> "A"
    11 -> "B"
    12 -> "C"
    13 -> "D"
    14 -> "E"
    15 -> "F"
    _ -> "0"
  }
}

// Encode bytes recursively to handle multi-byte UTF-8 characters
fn encode_bytes(bytes: BitArray, index: Int, size: Int, acc: String) -> String {
  case index >= size {
    True -> acc
    False -> {
      let assert Ok(byte) = bit_array.slice(bytes, index, 1)
      let assert <<byte_val:int>> = byte
      let encoded = "%" <> string.uppercase(int_to_hex(byte_val))
      encode_bytes(bytes, index + 1, size, acc <> encoded)
    }
  }
}

/// Create OAuth 1.0a signature base string
///
/// Format: METHOD&URL&SORTED_PARAMS
/// All components must be percent-encoded
pub fn create_signature_base_string(
  method: String,
  url: String,
  params: Dict(String, String),
) -> String {
  let sorted_params =
    params
    |> dict.to_list
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.map(fn(pair) { oauth_encode(pair.0) <> "=" <> oauth_encode(pair.1) })
    |> string.join("&")

  method <> "&" <> oauth_encode(url) <> "&" <> oauth_encode(sorted_params)
}

/// Create HMAC-SHA1 signature for OAuth 1.0a
///
/// Signing key = consumer_secret& OR consumer_secret&token_secret
/// Note: The signing key components are NOT percent-encoded per OAuth 1.0a spec
/// Result is base64-encoded
pub fn create_signature(
  base_string: String,
  consumer_secret: String,
  token_secret: Option(String),
) -> String {
  let token_secret_str = option.unwrap(token_secret, "")
  // OAuth 1.0a spec: signing key is raw values, NOT percent-encoded
  let signing_key = consumer_secret <> "&" <> token_secret_str

  crypto.hmac(<<base_string:utf8>>, crypto.Sha1, <<signing_key:utf8>>)
  |> bit_array.base64_encode(True)
}

/// Build complete OAuth 1.0a parameter set with signature
///
/// Includes: oauth_consumer_key, oauth_signature_method, oauth_timestamp,
/// oauth_nonce, oauth_version, oauth_token (if provided), oauth_signature,
/// plus any extra_params
pub fn build_oauth_params(
  consumer_key: String,
  consumer_secret: String,
  method: String,
  url: String,
  extra_params: Dict(String, String),
  token: Option(String),
  token_secret: Option(String),
) -> Dict(String, String) {
  let timestamp = int.to_string(unix_timestamp())
  let nonce = generate_nonce()

  let params =
    dict.new()
    |> dict.insert("oauth_consumer_key", consumer_key)
    |> dict.insert("oauth_signature_method", "HMAC-SHA1")
    |> dict.insert("oauth_timestamp", timestamp)
    |> dict.insert("oauth_nonce", nonce)
    |> dict.insert("oauth_version", "1.0")

  let params = case token {
    Some(t) -> dict.insert(params, "oauth_token", t)
    None -> params
  }

  let params =
    dict.fold(extra_params, params, fn(acc, key, value) {
      dict.insert(acc, key, value)
    })

  let base_string = create_signature_base_string(method, url, params)
  let signature = create_signature(base_string, consumer_secret, token_secret)

    dict.insert(params, "oauth_signature", signature)
}

/// Parse OAuth response string (key=value&key2=value2) into a dictionary
pub fn parse_oauth_response(response: String) -> Dict(String, String) {
  response
  |> string.split("&")
  |> list.fold(dict.new(), fn(acc, pair) {
    case string.split(pair, "=") {
      [key, value] -> dict.insert(acc, key, value)
      _ -> acc
    }
  })
}

/// Parse request token response from OAuth 1.0a step 1
pub fn parse_request_token(
  response: String,
) -> Result(RequestToken, String) {
  let params = parse_oauth_response(response)

  case dict.get(params, "oauth_token") {
    Error(_) -> Error("Missing oauth_token")
    Ok(token) ->
      case dict.get(params, "oauth_token_secret") {
        Error(_) -> Error("Missing oauth_token_secret")
        Ok(secret) -> {
          let callback_confirmed =
            dict.get(params, "oauth_callback_confirmed")
            |> result.map(fn(v) { v == "true" })
            |> result.unwrap(False)

          Ok(RequestToken(
            oauth_token: token,
            oauth_token_secret: secret,
            oauth_callback_confirmed: callback_confirmed,
          ))
        }
      }
  }
}

/// Parse access token response from OAuth 1.0a step 3
pub fn parse_access_token(
  response: String,
) -> Result(AccessToken, String) {
  let params = parse_oauth_response(response)

  case dict.get(params, "oauth_token") {
    Error(_) -> Error("Missing oauth_token")
    Ok(token) ->
      case dict.get(params, "oauth_token_secret") {
        Error(_) -> Error("Missing oauth_token_secret")
        Ok(secret) ->
          Ok(AccessToken(oauth_token: token, oauth_token_secret: secret))
      }
  }
}

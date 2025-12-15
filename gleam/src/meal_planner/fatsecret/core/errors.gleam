import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/result

/// FatSecret API error codes as documented in the API reference
pub type ApiErrorCode {
  MissingOAuthParameter
  // 2
  UnsupportedOAuthParameter
  // 3
  InvalidSignatureMethod
  // 4
  InvalidConsumerCredentials
  // 5
  InvalidOrExpiredToken
  // 6
  InvalidSignature
  // 7
  InvalidNonce
  // 8
  InvalidAccessToken
  // 9
  InvalidMethod
  // 13
  ApiUnavailable
  // 14
  MissingRequiredParameter
  // 101
  InvalidId
  // 106
  InvalidSearchValue
  // 107
  InvalidDate
  // 108
  WeightDateTooFar
  // 205
  WeightDateEarlier
  // 206
  NoEntries
  // 207
  UnknownError(code: Int)
}

/// All possible errors from the FatSecret SDK
pub type FatSecretError {
  ApiError(code: ApiErrorCode, message: String)
  RequestFailed(status: Int, body: String)
  ParseError(message: String)
  OAuthError(message: String)
  NetworkError(message: String)
  ConfigMissing
  InvalidResponse(message: String)
}

/// Convert an integer error code to the corresponding ApiErrorCode
pub fn code_from_int(code: Int) -> ApiErrorCode {
  case code {
    2 -> MissingOAuthParameter
    3 -> UnsupportedOAuthParameter
    4 -> InvalidSignatureMethod
    5 -> InvalidConsumerCredentials
    6 -> InvalidOrExpiredToken
    7 -> InvalidSignature
    8 -> InvalidNonce
    9 -> InvalidAccessToken
    13 -> InvalidMethod
    14 -> ApiUnavailable
    101 -> MissingRequiredParameter
    106 -> InvalidId
    107 -> InvalidSearchValue
    108 -> InvalidDate
    205 -> WeightDateTooFar
    206 -> WeightDateEarlier
    207 -> NoEntries
    _ -> UnknownError(code)
  }
}

/// Convert an ApiErrorCode to its integer representation
pub fn code_to_int(code: ApiErrorCode) -> Int {
  case code {
    MissingOAuthParameter -> 2
    UnsupportedOAuthParameter -> 3
    InvalidSignatureMethod -> 4
    InvalidConsumerCredentials -> 5
    InvalidOrExpiredToken -> 6
    InvalidSignature -> 7
    InvalidNonce -> 8
    InvalidAccessToken -> 9
    InvalidMethod -> 13
    ApiUnavailable -> 14
    MissingRequiredParameter -> 101
    InvalidId -> 106
    InvalidSearchValue -> 107
    InvalidDate -> 108
    WeightDateTooFar -> 205
    WeightDateEarlier -> 206
    NoEntries -> 207
    UnknownError(n) -> n
  }
}

/// Convert an ApiErrorCode to a human-readable string
pub fn code_to_string(code: ApiErrorCode) -> String {
  case code {
    MissingOAuthParameter -> "Missing OAuth Parameter"
    UnsupportedOAuthParameter -> "Unsupported OAuth Parameter"
    InvalidSignatureMethod -> "Invalid Signature Method"
    InvalidConsumerCredentials -> "Invalid Consumer Credentials"
    InvalidOrExpiredToken -> "Invalid or Expired Token"
    InvalidSignature -> "Invalid Signature"
    InvalidNonce -> "Invalid Nonce"
    InvalidAccessToken -> "Invalid Access Token"
    InvalidMethod -> "Invalid Method"
    ApiUnavailable -> "API Unavailable"
    MissingRequiredParameter -> "Missing Required Parameter"
    InvalidId -> "Invalid ID"
    InvalidSearchValue -> "Invalid Search Value"
    InvalidDate -> "Invalid Date"
    WeightDateTooFar -> "Weight Date Too Far in Future"
    WeightDateEarlier -> "Weight Date Earlier Than Expected"
    NoEntries -> "No Entries Found"
    UnknownError(n) -> "Unknown Error (" <> int.to_string(n) <> ")"
  }
}

/// Convert a FatSecretError to a human-readable string
pub fn error_to_string(error: FatSecretError) -> String {
  case error {
    ApiError(code, message) ->
      code_to_string(code)
      <> " (code "
      <> int.to_string(code_to_int(code))
      <> "): "
      <> message
    RequestFailed(status, body) ->
      "Request failed with status " <> int.to_string(status) <> ": " <> body
    ParseError(message) -> "Failed to parse response: " <> message
    OAuthError(message) -> "OAuth error: " <> message
    NetworkError(message) -> "Network error: " <> message
    ConfigMissing ->
      "FatSecret configuration is missing. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET environment variables."
    InvalidResponse(message) -> "Invalid response from API: " <> message
  }
}

/// Parse an error response from the FatSecret API
///
/// The API returns errors in JSON format:
/// {"error": {"code": 101, "message": "Missing required parameter"}}
pub fn parse_error_response(body: String) -> Result(FatSecretError, Nil) {
  let error_decoder = {
    use code <- decode.field("code", decode.int)
    use message <- decode.field("message", decode.string)
    decode.success(ApiError(code_from_int(code), message))
  }

  let response_decoder = {
    use error <- decode.field("error", error_decoder)
    decode.success(error)
  }

  json.parse(body, response_decoder)
  |> result.map_error(fn(_) { Nil })
}

/// Determine if an error is recoverable (i.e., retrying might succeed)
pub fn is_recoverable(error: FatSecretError) -> Bool {
  case error {
    // Network errors are recoverable
    NetworkError(_) -> True

    // API unavailable might be temporary
    ApiError(ApiUnavailable, _) -> True

    // Request failures might be temporary (5xx errors)
    RequestFailed(status, _) if status >= 500 -> True

    // Other errors are not recoverable
    _ -> False
  }
}

/// Determine if an error is authentication-related
pub fn is_auth_error(error: FatSecretError) -> Bool {
  case error {
    OAuthError(_) -> True
    ConfigMissing -> True
    ApiError(MissingOAuthParameter, _) -> True
    ApiError(UnsupportedOAuthParameter, _) -> True
    ApiError(InvalidSignatureMethod, _) -> True
    ApiError(InvalidConsumerCredentials, _) -> True
    ApiError(InvalidOrExpiredToken, _) -> True
    ApiError(InvalidSignature, _) -> True
    ApiError(InvalidNonce, _) -> True
    ApiError(InvalidAccessToken, _) -> True
    _ -> False
  }
}

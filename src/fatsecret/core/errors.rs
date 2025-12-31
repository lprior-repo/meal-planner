//! FatSecret API Error Types
//!
//! Defines error codes and error types for the FatSecret Platform API.
//! Ported from src/meal_planner/fatsecret/core/errors.gleam

use serde::Deserialize;
use thiserror::Error;

/// FatSecret API error codes as documented in the API reference
///
/// These correspond to the numeric error codes returned by the FatSecret API.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ApiErrorCode {
    /// Code 2: Missing OAuth parameter
    MissingOAuthParameter,
    /// Code 3: Unsupported OAuth parameter
    UnsupportedOAuthParameter,
    /// Code 4: Invalid signature method
    InvalidSignatureMethod,
    /// Code 5: Invalid consumer credentials
    InvalidConsumerCredentials,
    /// Code 6: Invalid or expired token
    InvalidOrExpiredToken,
    /// Code 7: Invalid signature
    InvalidSignature,
    /// Code 8: Invalid nonce
    InvalidNonce,
    /// Code 9: Invalid access token
    InvalidAccessToken,
    /// Code 13: Invalid method
    InvalidMethod,
    /// Code 14: API unavailable
    ApiUnavailable,
    /// Code 101: Missing required parameter
    MissingRequiredParameter,
    /// Code 106: Invalid ID
    InvalidId,
    /// Code 107: Invalid search value
    InvalidSearchValue,
    /// Code 108: Invalid date
    InvalidDate,
    /// Code 205: Weight date too far in future
    WeightDateTooFar,
    /// Code 206: Weight date earlier than expected
    WeightDateEarlier,
    /// Code 207: No entries found
    NoEntries,
    /// Unknown error code
    UnknownError(i32),
}

impl ApiErrorCode {
    /// Convert an integer error code to the corresponding ApiErrorCode
    pub fn from_code(code: i32) -> Self {
        match code {
            2 => Self::MissingOAuthParameter,
            3 => Self::UnsupportedOAuthParameter,
            4 => Self::InvalidSignatureMethod,
            5 => Self::InvalidConsumerCredentials,
            6 => Self::InvalidOrExpiredToken,
            7 => Self::InvalidSignature,
            8 => Self::InvalidNonce,
            9 => Self::InvalidAccessToken,
            13 => Self::InvalidMethod,
            14 => Self::ApiUnavailable,
            101 => Self::MissingRequiredParameter,
            106 => Self::InvalidId,
            107 => Self::InvalidSearchValue,
            108 => Self::InvalidDate,
            205 => Self::WeightDateTooFar,
            206 => Self::WeightDateEarlier,
            207 => Self::NoEntries,
            _ => Self::UnknownError(code),
        }
    }

    /// Convert an ApiErrorCode to its integer representation
    pub fn to_code(&self) -> i32 {
        match self {
            Self::MissingOAuthParameter => 2,
            Self::UnsupportedOAuthParameter => 3,
            Self::InvalidSignatureMethod => 4,
            Self::InvalidConsumerCredentials => 5,
            Self::InvalidOrExpiredToken => 6,
            Self::InvalidSignature => 7,
            Self::InvalidNonce => 8,
            Self::InvalidAccessToken => 9,
            Self::InvalidMethod => 13,
            Self::ApiUnavailable => 14,
            Self::MissingRequiredParameter => 101,
            Self::InvalidId => 106,
            Self::InvalidSearchValue => 107,
            Self::InvalidDate => 108,
            Self::WeightDateTooFar => 205,
            Self::WeightDateEarlier => 206,
            Self::NoEntries => 207,
            Self::UnknownError(n) => *n,
        }
    }

    /// Get a human-readable description of the error code
    pub fn description(&self) -> &'static str {
        match self {
            Self::MissingOAuthParameter => "Missing OAuth Parameter",
            Self::UnsupportedOAuthParameter => "Unsupported OAuth Parameter",
            Self::InvalidSignatureMethod => "Invalid Signature Method",
            Self::InvalidConsumerCredentials => "Invalid Consumer Credentials",
            Self::InvalidOrExpiredToken => "Invalid or Expired Token",
            Self::InvalidSignature => "Invalid Signature",
            Self::InvalidNonce => "Invalid Nonce",
            Self::InvalidAccessToken => "Invalid Access Token",
            Self::InvalidMethod => "Invalid Method",
            Self::ApiUnavailable => "API Unavailable",
            Self::MissingRequiredParameter => "Missing Required Parameter",
            Self::InvalidId => "Invalid ID",
            Self::InvalidSearchValue => "Invalid Search Value",
            Self::InvalidDate => "Invalid Date",
            Self::WeightDateTooFar => "Weight Date Too Far in Future",
            Self::WeightDateEarlier => "Weight Date Earlier Than Expected",
            Self::NoEntries => "No Entries Found",
            Self::UnknownError(_) => "Unknown Error",
        }
    }

    /// Check if this error code indicates an authentication problem
    pub fn is_auth_related(&self) -> bool {
        matches!(
            self,
            Self::MissingOAuthParameter
                | Self::UnsupportedOAuthParameter
                | Self::InvalidSignatureMethod
                | Self::InvalidConsumerCredentials
                | Self::InvalidOrExpiredToken
                | Self::InvalidSignature
                | Self::InvalidNonce
                | Self::InvalidAccessToken
        )
    }
}

impl std::fmt::Display for ApiErrorCode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::UnknownError(code) => write!(f, "Unknown Error (code {})", code),
            Self::MissingOAuthParameter
            | Self::UnsupportedOAuthParameter
            | Self::InvalidSignatureMethod
            | Self::InvalidConsumerCredentials
            | Self::InvalidOrExpiredToken
            | Self::InvalidSignature
            | Self::InvalidNonce
            | Self::InvalidAccessToken
            | Self::InvalidMethod
            | Self::ApiUnavailable
            | Self::MissingRequiredParameter
            | Self::InvalidId
            | Self::InvalidSearchValue
            | Self::InvalidDate
            | Self::WeightDateTooFar
            | Self::WeightDateEarlier
            | Self::NoEntries => write!(f, "{}", self.description()),
        }
    }
}

/// All possible errors from the FatSecret SDK
#[derive(Error, Debug)]
pub enum FatSecretError {
    /// Error returned by the FatSecret API
    #[error("{} (code {}): {message}", code.description(), code.to_code())]
    ApiError {
        /// The structured error code from the API
        code: ApiErrorCode,
        /// Human-readable error message from the API
        message: String,
    },

    /// HTTP request failed with non-2xx status
    #[error("Request failed with status {status}: {body}")]
    RequestFailed {
        /// HTTP status code
        status: u16,
        /// Response body content
        body: String,
    },

    /// Failed to parse API response
    #[error("Failed to parse response: {0}")]
    ParseError(String),

    /// OAuth-related error during authentication
    #[error("OAuth error: {0}")]
    OAuthError(String),

    /// Network-level error (connection, timeout, etc.)
    #[error("Network error: {0}")]
    NetworkError(String),

    /// FatSecret configuration is missing
    #[error("FatSecret configuration is missing. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET environment variables.")]
    ConfigMissing,

    /// Invalid response structure from API
    #[error("Invalid response from API: {0}")]
    InvalidResponse(String),
}

impl FatSecretError {
    /// Create an API error from code and message
    pub fn api_error(code: i32, message: impl Into<String>) -> Self {
        Self::ApiError {
            code: ApiErrorCode::from_code(code),
            message: message.into(),
        }
    }

    /// Create a request failed error
    pub fn request_failed(status: u16, body: impl Into<String>) -> Self {
        Self::RequestFailed {
            status,
            body: body.into(),
        }
    }

    /// Create a parse error
    pub fn parse_error(message: impl Into<String>) -> Self {
        Self::ParseError(message.into())
    }

    /// Create an OAuth error
    pub fn oauth_error(message: impl Into<String>) -> Self {
        Self::OAuthError(message.into())
    }

    /// Create a network error
    pub fn network_error(message: impl Into<String>) -> Self {
        Self::NetworkError(message.into())
    }

    /// Create an invalid response error
    pub fn invalid_response(message: impl Into<String>) -> Self {
        Self::InvalidResponse(message.into())
    }

    /// Determine if an error is recoverable (i.e., retrying might succeed)
    ///
    /// Recoverable errors include:
    /// - Network errors (temporary connectivity issues)
    /// - API unavailable (temporary outage)
    /// - Server errors (5xx status codes)
    pub fn is_recoverable(&self) -> bool {
        match self {
            // Network errors and API unavailable are recoverable
            Self::NetworkError(_)
            | Self::ApiError {
                code: ApiErrorCode::ApiUnavailable,
                ..
            } => true,

            // Request failures might be temporary (5xx errors)
            Self::RequestFailed { status, .. } if *status >= 500 => true,

            // Other errors are not recoverable
            Self::ApiError { .. }
            | Self::RequestFailed { .. }
            | Self::ParseError(_)
            | Self::OAuthError(_)
            | Self::ConfigMissing
            | Self::InvalidResponse(_) => false,
        }
    }

    /// Determine if an error is authentication-related
    ///
    /// Auth errors include:
    /// - OAuth errors
    /// - Missing configuration
    /// - API errors related to OAuth (codes 2-9)
    pub fn is_auth_error(&self) -> bool {
        match self {
            Self::OAuthError(_) | Self::ConfigMissing => true,
            Self::ApiError { code, .. } => code.is_auth_related(),
            Self::RequestFailed { .. }
            | Self::ParseError(_)
            | Self::NetworkError(_)
            | Self::InvalidResponse(_) => false,
        }
    }

    /// Get the API error code if this is an API error
    pub fn api_error_code(&self) -> Option<&ApiErrorCode> {
        match self {
            Self::ApiError { code, .. } => Some(code),
            Self::RequestFailed { .. }
            | Self::ParseError(_)
            | Self::OAuthError(_)
            | Self::NetworkError(_)
            | Self::ConfigMissing
            | Self::InvalidResponse(_) => None,
        }
    }
}

/// JSON structure for FatSecret API error responses
///
/// The API returns errors in the format:
/// ```json
/// {"error": {"code": 101, "message": "Missing required parameter"}}
/// ```
#[derive(Debug, Deserialize)]
struct ApiErrorResponse {
    error: ApiErrorInner,
}

#[derive(Debug, Deserialize)]
struct ApiErrorInner {
    code: i32,
    message: String,
}

/// Parse an error response from the FatSecret API
///
/// Returns `Some(FatSecretError::ApiError)` if the body contains a valid error response,
/// `None` otherwise.
pub fn parse_error_response(body: &str) -> Option<FatSecretError> {
    serde_json::from_str::<ApiErrorResponse>(body)
        .ok()
        .map(|response| FatSecretError::ApiError {
            code: ApiErrorCode::from_code(response.error.code),
            message: response.error.message,
        })
}

impl From<reqwest::Error> for FatSecretError {
    fn from(error: reqwest::Error) -> Self {
        if error.is_timeout() {
            Self::NetworkError(format!("Request timed out: {}", error))
        } else if error.is_connect() {
            Self::NetworkError(format!("Connection failed: {}", error))
        } else if error.is_decode() {
            Self::ParseError(format!("Failed to decode response: {}", error))
        } else {
            Self::NetworkError(error.to_string())
        }
    }
}

impl From<serde_json::Error> for FatSecretError {
    fn from(error: serde_json::Error) -> Self {
        Self::ParseError(format!("JSON parse error: {}", error))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_api_error_code_from_code() {
        assert_eq!(
            ApiErrorCode::from_code(2),
            ApiErrorCode::MissingOAuthParameter
        );
        assert_eq!(ApiErrorCode::from_code(9), ApiErrorCode::InvalidAccessToken);
        assert_eq!(
            ApiErrorCode::from_code(101),
            ApiErrorCode::MissingRequiredParameter
        );
        assert_eq!(ApiErrorCode::from_code(207), ApiErrorCode::NoEntries);
        assert_eq!(
            ApiErrorCode::from_code(999),
            ApiErrorCode::UnknownError(999)
        );
    }

    #[test]
    fn test_api_error_code_to_code() {
        assert_eq!(ApiErrorCode::MissingOAuthParameter.to_code(), 2);
        assert_eq!(ApiErrorCode::InvalidAccessToken.to_code(), 9);
        assert_eq!(ApiErrorCode::MissingRequiredParameter.to_code(), 101);
        assert_eq!(ApiErrorCode::UnknownError(42).to_code(), 42);
    }

    #[test]
    fn test_api_error_code_roundtrip() {
        for code in [
            2, 3, 4, 5, 6, 7, 8, 9, 13, 14, 101, 106, 107, 108, 205, 206, 207,
        ] {
            let error_code = ApiErrorCode::from_code(code);
            assert_eq!(error_code.to_code(), code);
        }
    }

    #[test]
    fn test_is_auth_related() {
        // OAuth-related codes should be auth errors
        assert!(ApiErrorCode::MissingOAuthParameter.is_auth_related());
        assert!(ApiErrorCode::InvalidAccessToken.is_auth_related());
        assert!(ApiErrorCode::InvalidSignature.is_auth_related());

        // Non-OAuth codes should not be auth errors
        assert!(!ApiErrorCode::MissingRequiredParameter.is_auth_related());
        assert!(!ApiErrorCode::InvalidId.is_auth_related());
        assert!(!ApiErrorCode::NoEntries.is_auth_related());
        assert!(!ApiErrorCode::UnknownError(999).is_auth_related());
    }

    #[test]
    fn test_fatsecret_error_is_recoverable() {
        // Network errors are recoverable
        assert!(FatSecretError::network_error("timeout").is_recoverable());

        // API unavailable is recoverable
        assert!(FatSecretError::ApiError {
            code: ApiErrorCode::ApiUnavailable,
            message: "try again".into()
        }
        .is_recoverable());

        // 5xx errors are recoverable
        assert!(FatSecretError::request_failed(500, "server error").is_recoverable());
        assert!(FatSecretError::request_failed(503, "service unavailable").is_recoverable());

        // 4xx errors are not recoverable
        assert!(!FatSecretError::request_failed(400, "bad request").is_recoverable());
        assert!(!FatSecretError::request_failed(404, "not found").is_recoverable());

        // Other API errors are not recoverable
        assert!(!FatSecretError::ApiError {
            code: ApiErrorCode::InvalidAccessToken,
            message: "invalid token".into()
        }
        .is_recoverable());

        // Other errors are not recoverable
        assert!(!FatSecretError::ConfigMissing.is_recoverable());
        assert!(!FatSecretError::parse_error("bad json").is_recoverable());
    }

    #[test]
    fn test_fatsecret_error_is_auth_error() {
        // OAuth errors are auth errors
        assert!(FatSecretError::oauth_error("invalid token").is_auth_error());

        // Config missing is an auth error
        assert!(FatSecretError::ConfigMissing.is_auth_error());

        // API errors with OAuth-related codes are auth errors
        assert!(FatSecretError::ApiError {
            code: ApiErrorCode::InvalidAccessToken,
            message: "expired".into()
        }
        .is_auth_error());

        assert!(FatSecretError::ApiError {
            code: ApiErrorCode::InvalidSignature,
            message: "bad sig".into()
        }
        .is_auth_error());

        // Non-auth API errors are not auth errors
        assert!(!FatSecretError::ApiError {
            code: ApiErrorCode::MissingRequiredParameter,
            message: "missing param".into()
        }
        .is_auth_error());

        // Other errors are not auth errors
        assert!(!FatSecretError::network_error("timeout").is_auth_error());
        assert!(!FatSecretError::parse_error("bad json").is_auth_error());
    }

    #[test]
    fn test_parse_error_response() {
        let body = r#"{"error": {"code": 101, "message": "Missing required parameter"}}"#;
        let error = parse_error_response(body).expect("should parse");

        match error {
            FatSecretError::ApiError { code, message } => {
                assert_eq!(code, ApiErrorCode::MissingRequiredParameter);
                assert_eq!(message, "Missing required parameter");
            }
            FatSecretError::RequestFailed { .. }
            | FatSecretError::ParseError(_)
            | FatSecretError::OAuthError(_)
            | FatSecretError::NetworkError(_)
            | FatSecretError::ConfigMissing
            | FatSecretError::InvalidResponse(_) => panic!("expected ApiError"),
        }
    }

    #[test]
    fn test_parse_error_response_invalid() {
        assert!(parse_error_response("not json").is_none());
        assert!(parse_error_response(r#"{"other": "data"}"#).is_none());
        assert!(parse_error_response("").is_none());
    }

    #[test]
    fn test_error_display() {
        let error = FatSecretError::ApiError {
            code: ApiErrorCode::InvalidAccessToken,
            message: "Token has expired".into(),
        };
        let display = error.to_string();
        assert!(display.contains("Invalid Access Token"));
        assert!(display.contains("code 9"));
        assert!(display.contains("Token has expired"));

        let network_error = FatSecretError::network_error("connection refused");
        assert_eq!(
            network_error.to_string(),
            "Network error: connection refused"
        );

        let config_error = FatSecretError::ConfigMissing;
        assert!(config_error.to_string().contains("FATSECRET_CONSUMER_KEY"));
    }
}

//! `FatSecret` API Error Types
//!
//! Defines error codes and error types for the `FatSecret` Platform API.
//! Error codes documented at: docs/fatsecret/guides-error-codes.md

use serde::Deserialize;
use thiserror::Error;

/// `FatSecret` API error codes as documented in the API reference.
///
/// These correspond to the numeric error codes returned by the `FatSecret` API.
/// See docs/fatsecret/guides-error-codes.md for full documentation.
///
/// # Important Distinctions
///
/// - **Code 12 (`MethodNotAccessible`)**: OAuth scope/permission issue.
///   The token is valid but lacks required scopes (e.g., 'barcode', 'premier').
///   Solution: Re-authenticate with correct scopes.
///   This is NOT a premium issue.
///
/// - **Code 24 (`PremiumRequired`)**: Requires a paid subscription plan.
///   This is the ONLY code that indicates a premium/plan limitation.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ApiErrorCode {
    // ============================================
    // General Errors (1, 10-12, 20-24)
    // ============================================
    /// Code 1: General error - see message for details
    GeneralError,
    /// Code 10: Invalid API method name
    InvalidApiMethod,
    /// Code 11: Method requires secure connection (HTTPS)
    RequiresHttps,
    /// Code 12: Method not accessible with current authentication.
    /// This is a SCOPE issue - the OAuth token lacks required permissions.
    /// NOT a premium issue. Solution: Re-authenticate with correct scopes.
    MethodNotAccessible,
    /// Code 20: User does not have permission for this action
    UserPermissionDenied,
    /// Code 21: User account is suspended
    AccountSuspended,
    /// Code 22: Rate limit exceeded - wait and retry
    RateLimitExceeded,
    /// Code 23: API access disabled for this account
    ApiAccessDisabled,
    /// Code 24: Feature not available for current plan.
    /// This is the ONLY code that indicates a premium/plan issue.
    PremiumRequired,

    // ============================================
    // OAuth 1.0 Errors (2-9)
    // ============================================
    /// Code 2: Missing required OAuth parameter
    MissingOAuthParameter,
    /// Code 3: Unsupported OAuth parameter
    UnsupportedOAuthParameter,
    /// Code 4: Invalid signature method - must be HMAC-SHA1
    InvalidSignatureMethod,
    /// Code 5: Invalid consumer key
    InvalidConsumerCredentials,
    /// Code 6: Invalid or expired timestamp
    InvalidOrExpiredTimestamp,
    /// Code 7: Invalid or already used nonce
    InvalidNonce,
    /// Code 8: Invalid signature
    InvalidSignature,
    /// Code 9: Invalid or expired access token
    InvalidAccessToken,

    // ============================================
    // OAuth 2.0 Errors (13-14)
    // ============================================
    /// Code 13: Invalid access token (OAuth 2.0)
    OAuth2InvalidToken,
    /// Code 14: Access token has expired (OAuth 2.0)
    OAuth2TokenExpired,

    // ============================================
    // Parameter Errors (101-109)
    // ============================================
    /// Code 101: Missing required parameter
    MissingRequiredParameter,
    /// Code 102: Invalid parameter type
    InvalidParameterType,
    /// Code 103: Invalid parameter value
    InvalidParameterValue,
    /// Code 104: Parameter value out of range
    ParameterOutOfRange,
    /// Code 105: Invalid date format
    InvalidDateFormat,
    /// Code 106: Invalid `food_id`
    InvalidFoodId,
    /// Code 107: Invalid `serving_id`
    InvalidServingId,
    /// Code 108: Invalid `recipe_id`
    InvalidRecipeId,
    /// Code 109: Invalid `food_entry_id`
    InvalidFoodEntryId,

    // ============================================
    // Resource Not Found Errors (201-211)
    // ============================================
    /// Code 201: Food not found
    FoodNotFound,
    /// Code 202: Recipe not found
    RecipeNotFound,
    /// Code 203: Serving not found
    ServingNotFound,
    /// Code 204: Food entry not found
    FoodEntryNotFound,
    /// Code 205: Exercise entry not found
    ExerciseEntryNotFound,
    /// Code 206: Weight entry not found
    WeightEntryNotFound,
    /// Code 207: User profile not found
    UserProfileNotFound,
    /// Code 208: Meal not found
    MealNotFound,
    /// Code 209: Brand not found
    BrandNotFound,
    /// Code 210: Duplicate entry
    DuplicateEntry,
    /// Code 211: Maximum limit reached
    MaximumLimitReached,

    /// Unknown error code - check the message for details
    UnknownError(i32),
}

impl ApiErrorCode {
    /// Convert an integer error code to the corresponding `ApiErrorCode`
    #[must_use]
    pub fn from_code(code: i32) -> Self {
        match code {
            // General errors
            1 => Self::GeneralError,
            10 => Self::InvalidApiMethod,
            11 => Self::RequiresHttps,
            12 => Self::MethodNotAccessible,
            20 => Self::UserPermissionDenied,
            21 => Self::AccountSuspended,
            22 => Self::RateLimitExceeded,
            23 => Self::ApiAccessDisabled,
            24 => Self::PremiumRequired,
            // OAuth 1.0 errors
            2 => Self::MissingOAuthParameter,
            3 => Self::UnsupportedOAuthParameter,
            4 => Self::InvalidSignatureMethod,
            5 => Self::InvalidConsumerCredentials,
            6 => Self::InvalidOrExpiredTimestamp,
            7 => Self::InvalidNonce,
            8 => Self::InvalidSignature,
            9 => Self::InvalidAccessToken,
            // OAuth 2.0 errors
            13 => Self::OAuth2InvalidToken,
            14 => Self::OAuth2TokenExpired,
            // Parameter errors
            101 => Self::MissingRequiredParameter,
            102 => Self::InvalidParameterType,
            103 => Self::InvalidParameterValue,
            104 => Self::ParameterOutOfRange,
            105 => Self::InvalidDateFormat,
            106 => Self::InvalidFoodId,
            107 => Self::InvalidServingId,
            108 => Self::InvalidRecipeId,
            109 => Self::InvalidFoodEntryId,
            // Resource not found errors
            201 => Self::FoodNotFound,
            202 => Self::RecipeNotFound,
            203 => Self::ServingNotFound,
            204 => Self::FoodEntryNotFound,
            205 => Self::ExerciseEntryNotFound,
            206 => Self::WeightEntryNotFound,
            207 => Self::UserProfileNotFound,
            208 => Self::MealNotFound,
            209 => Self::BrandNotFound,
            210 => Self::DuplicateEntry,
            211 => Self::MaximumLimitReached,
            _ => Self::UnknownError(code),
        }
    }

    /// Convert an `ApiErrorCode` to its integer representation
    #[must_use]
    pub fn to_code(&self) -> i32 {
        match self {
            // General errors
            Self::GeneralError => 1,
            Self::InvalidApiMethod => 10,
            Self::RequiresHttps => 11,
            Self::MethodNotAccessible => 12,
            Self::UserPermissionDenied => 20,
            Self::AccountSuspended => 21,
            Self::RateLimitExceeded => 22,
            Self::ApiAccessDisabled => 23,
            Self::PremiumRequired => 24,
            // OAuth 1.0 errors
            Self::MissingOAuthParameter => 2,
            Self::UnsupportedOAuthParameter => 3,
            Self::InvalidSignatureMethod => 4,
            Self::InvalidConsumerCredentials => 5,
            Self::InvalidOrExpiredTimestamp => 6,
            Self::InvalidNonce => 7,
            Self::InvalidSignature => 8,
            Self::InvalidAccessToken => 9,
            // OAuth 2.0 errors
            Self::OAuth2InvalidToken => 13,
            Self::OAuth2TokenExpired => 14,
            // Parameter errors
            Self::MissingRequiredParameter => 101,
            Self::InvalidParameterType => 102,
            Self::InvalidParameterValue => 103,
            Self::ParameterOutOfRange => 104,
            Self::InvalidDateFormat => 105,
            Self::InvalidFoodId => 106,
            Self::InvalidServingId => 107,
            Self::InvalidRecipeId => 108,
            Self::InvalidFoodEntryId => 109,
            // Resource not found errors
            Self::FoodNotFound => 201,
            Self::RecipeNotFound => 202,
            Self::ServingNotFound => 203,
            Self::FoodEntryNotFound => 204,
            Self::ExerciseEntryNotFound => 205,
            Self::WeightEntryNotFound => 206,
            Self::UserProfileNotFound => 207,
            Self::MealNotFound => 208,
            Self::BrandNotFound => 209,
            Self::DuplicateEntry => 210,
            Self::MaximumLimitReached => 211,
            Self::UnknownError(n) => *n,
        }
    }

    /// Get a human-readable description of the error code.
    ///
    /// Descriptions are designed to help users understand what went wrong
    /// and how to fix it, especially for commonly confused errors.
    #[must_use]
    pub fn description(&self) -> &'static str {
        match self {
            // General errors
            Self::GeneralError => "General Error",
            Self::InvalidApiMethod => "Invalid API Method",
            Self::RequiresHttps => "Method Requires HTTPS",
            Self::MethodNotAccessible => {
                "Method Not Accessible - OAuth token lacks required scopes (NOT a premium issue)"
            }
            Self::UserPermissionDenied => "User Permission Denied",
            Self::AccountSuspended => "Account Suspended",
            Self::RateLimitExceeded => "Rate Limit Exceeded",
            Self::ApiAccessDisabled => "API Access Disabled",
            Self::PremiumRequired => "Premium Subscription Required",
            // OAuth 1.0 errors
            Self::MissingOAuthParameter => "Missing OAuth Parameter",
            Self::UnsupportedOAuthParameter => "Unsupported OAuth Parameter",
            Self::InvalidSignatureMethod => "Invalid Signature Method",
            Self::InvalidConsumerCredentials => "Invalid Consumer Credentials",
            Self::InvalidOrExpiredTimestamp => "Invalid or Expired Timestamp",
            Self::InvalidNonce => "Invalid or Used Nonce",
            Self::InvalidSignature => "Invalid Signature",
            Self::InvalidAccessToken => "Invalid or Expired Access Token",
            // OAuth 2.0 errors
            Self::OAuth2InvalidToken => "Invalid Access Token (OAuth 2.0)",
            Self::OAuth2TokenExpired => "Access Token Expired (OAuth 2.0)",
            // Parameter errors
            Self::MissingRequiredParameter => "Missing Required Parameter",
            Self::InvalidParameterType => "Invalid Parameter Type",
            Self::InvalidParameterValue => "Invalid Parameter Value",
            Self::ParameterOutOfRange => "Parameter Value Out of Range",
            Self::InvalidDateFormat => "Invalid Date Format",
            Self::InvalidFoodId => "Invalid food_id",
            Self::InvalidServingId => "Invalid serving_id",
            Self::InvalidRecipeId => "Invalid recipe_id",
            Self::InvalidFoodEntryId => "Invalid food_entry_id",
            // Resource not found errors
            Self::FoodNotFound => "Food Not Found",
            Self::RecipeNotFound => "Recipe Not Found",
            Self::ServingNotFound => "Serving Not Found",
            Self::FoodEntryNotFound => "Food Entry Not Found",
            Self::ExerciseEntryNotFound => "Exercise Entry Not Found",
            Self::WeightEntryNotFound => "Weight Entry Not Found",
            Self::UserProfileNotFound => "User Profile Not Found",
            Self::MealNotFound => "Meal Not Found",
            Self::BrandNotFound => "Brand Not Found",
            Self::DuplicateEntry => "Duplicate Entry",
            Self::MaximumLimitReached => "Maximum Limit Reached",
            Self::UnknownError(_) => "Unknown Error",
        }
    }

    /// Check if this error code indicates an authentication problem.
    ///
    /// Includes OAuth 1.0 errors (2-9), OAuth 2.0 errors (13-14),
    /// and scope issues (12).
    #[must_use]
    pub fn is_auth_related(&self) -> bool {
        matches!(
            self,
            Self::MissingOAuthParameter
                | Self::UnsupportedOAuthParameter
                | Self::InvalidSignatureMethod
                | Self::InvalidConsumerCredentials
                | Self::InvalidOrExpiredTimestamp
                | Self::InvalidNonce
                | Self::InvalidSignature
                | Self::InvalidAccessToken
                | Self::MethodNotAccessible
                | Self::OAuth2InvalidToken
                | Self::OAuth2TokenExpired
        )
    }

    /// Check if this error indicates a premium subscription is required.
    ///
    /// Only code 24 indicates a premium issue. Code 12 (`MethodNotAccessible`)
    /// is an OAuth scope issue, NOT a premium issue.
    #[must_use]
    pub fn is_premium_required(&self) -> bool {
        matches!(self, Self::PremiumRequired)
    }

    /// Check if this error indicates a resource was not found.
    #[must_use]
    pub fn is_not_found(&self) -> bool {
        matches!(
            self,
            Self::FoodNotFound
                | Self::RecipeNotFound
                | Self::ServingNotFound
                | Self::FoodEntryNotFound
                | Self::ExerciseEntryNotFound
                | Self::WeightEntryNotFound
                | Self::UserProfileNotFound
                | Self::MealNotFound
                | Self::BrandNotFound
        )
    }

    /// Check if this error indicates a parameter validation issue.
    #[must_use]
    pub fn is_parameter_error(&self) -> bool {
        matches!(
            self,
            Self::MissingRequiredParameter
                | Self::InvalidParameterType
                | Self::InvalidParameterValue
                | Self::ParameterOutOfRange
                | Self::InvalidDateFormat
                | Self::InvalidFoodId
                | Self::InvalidServingId
                | Self::InvalidRecipeId
                | Self::InvalidFoodEntryId
        )
    }

    /// Check if this error might be recoverable by retrying.
    #[must_use]
    pub fn is_retryable(&self) -> bool {
        matches!(
            self,
            Self::RateLimitExceeded | Self::GeneralError | Self::OAuth2TokenExpired
        )
    }
}

impl std::fmt::Display for ApiErrorCode {
    #[allow(clippy::wildcard_enum_match_arm)]
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::UnknownError(code) => write!(f, "Unknown Error (code {code})"),
            // All other known variants use their description - this is intentional
            // as adding new variants should use description() by default
            other => write!(f, "{}", other.description()),
        }
    }
}

/// All possible errors from the `FatSecret` SDK
#[derive(Error, Debug)]
pub enum FatSecretError {
    /// Error returned by the `FatSecret` API
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

    /// `FatSecret` configuration is missing
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
    /// - Rate limit exceeded (wait and retry)
    /// - OAuth 2.0 token expired (refresh and retry)
    /// - Server errors (5xx status codes)
    #[must_use]
    pub fn is_recoverable(&self) -> bool {
        match self {
            // Network errors are recoverable
            Self::NetworkError(_) => true,

            // Rate limiting and token expiry are recoverable
            Self::ApiError { code, .. } => code.is_retryable(),

            // Request failures might be temporary (5xx errors)
            Self::RequestFailed { status, .. } if *status >= 500 => true,

            // Other errors are not recoverable
            Self::RequestFailed { .. }
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
    #[must_use]
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
    #[must_use]
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

    /// Determine if an error indicates a premium subscription is required
    ///
    /// Returns true only for API error code 24 (Feature not available for current plan).
    /// Note: Error code 12 (`MethodNotAccessible`) is an auth/scope issue, NOT premium.
    #[must_use]
    pub fn is_premium_required(&self) -> bool {
        matches!(
            self,
            Self::ApiError {
                code: ApiErrorCode::PremiumRequired,
                ..
            }
        )
    }

    /// Determine if an error indicates a resource was not found
    ///
    /// Returns true for:
    /// - Error code 204 (Food entry not found)
    /// - Error code 207 (No entries found)
    /// - Error code 106 (Invalid ID - often means not found)
    #[must_use]
    pub fn is_not_found(&self) -> bool {
        match self {
            Self::ApiError { code, .. } => code.is_not_found(),
            Self::RequestFailed { .. }
            | Self::ParseError(_)
            | Self::OAuthError(_)
            | Self::NetworkError(_)
            | Self::ConfigMissing
            | Self::InvalidResponse(_) => false,
        }
    }
}

/// JSON structure for `FatSecret` API error responses
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

/// Parse an error response from the `FatSecret` API
///
/// Returns `Some(FatSecretError::ApiError)` if the body contains a valid error response,
/// `None` otherwise.
#[must_use]
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
            Self::NetworkError(format!("Request timed out: {error}"))
        } else if error.is_connect() {
            Self::NetworkError(format!("Connection failed: {error}"))
        } else if error.is_decode() {
            Self::ParseError(format!("Failed to decode response: {error}"))
        } else {
            Self::NetworkError(error.to_string())
        }
    }
}

impl From<serde_json::Error> for FatSecretError {
    fn from(error: serde_json::Error) -> Self {
        Self::ParseError(format!("JSON parse error: {error}"))
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used)] // Tests are allowed to use unwrap/expect
mod tests {
    use super::*;

    #[test]
    #[allow(clippy::cognitive_complexity)]
    fn test_api_error_code_from_code() {
        assert_eq!(
            ApiErrorCode::from_code(2),
            ApiErrorCode::MissingOAuthParameter
        );
        assert_eq!(ApiErrorCode::from_code(9), ApiErrorCode::InvalidAccessToken);
        assert_eq!(
            ApiErrorCode::from_code(12),
            ApiErrorCode::MethodNotAccessible
        );
        assert_eq!(
            ApiErrorCode::from_code(13),
            ApiErrorCode::OAuth2InvalidToken
        );
        assert_eq!(
            ApiErrorCode::from_code(14),
            ApiErrorCode::OAuth2TokenExpired
        );
        assert_eq!(ApiErrorCode::from_code(24), ApiErrorCode::PremiumRequired);
        assert_eq!(
            ApiErrorCode::from_code(101),
            ApiErrorCode::MissingRequiredParameter
        );
        assert_eq!(
            ApiErrorCode::from_code(204),
            ApiErrorCode::FoodEntryNotFound
        );
        assert_eq!(
            ApiErrorCode::from_code(207),
            ApiErrorCode::UserProfileNotFound
        );
        assert_eq!(
            ApiErrorCode::from_code(999),
            ApiErrorCode::UnknownError(999)
        );
    }

    #[test]
    fn test_api_error_code_roundtrip() {
        // All known error codes should roundtrip correctly
        let codes = [
            1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 20, 21, 22, 23, 24, 101, 102, 103, 104,
            105, 106, 107, 108, 109, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211,
        ];
        for code in codes {
            let error_code = ApiErrorCode::from_code(code);
            assert_eq!(
                error_code.to_code(),
                code,
                "Failed roundtrip for code {}",
                code
            );
        }
    }

    #[test]
    #[allow(clippy::cognitive_complexity)]
    fn test_is_auth_related() {
        // OAuth 1.0 codes (2-9) should be auth errors
        assert!(ApiErrorCode::MissingOAuthParameter.is_auth_related());
        assert!(ApiErrorCode::InvalidAccessToken.is_auth_related());
        assert!(ApiErrorCode::InvalidSignature.is_auth_related());

        // OAuth 2.0 codes (13-14) should be auth errors
        assert!(ApiErrorCode::OAuth2InvalidToken.is_auth_related());
        assert!(ApiErrorCode::OAuth2TokenExpired.is_auth_related());

        // Code 12 (MethodNotAccessible) should be auth-related (scope issue)
        assert!(ApiErrorCode::MethodNotAccessible.is_auth_related());

        // Non-auth codes should NOT be auth errors
        assert!(!ApiErrorCode::MissingRequiredParameter.is_auth_related());
        assert!(!ApiErrorCode::FoodNotFound.is_auth_related());
        assert!(!ApiErrorCode::PremiumRequired.is_auth_related());
        assert!(!ApiErrorCode::RateLimitExceeded.is_auth_related());
        assert!(!ApiErrorCode::UnknownError(999).is_auth_related());
    }

    #[test]
    fn test_code_12_is_not_premium() {
        // Code 12 is a scope issue, NOT a premium issue
        let code = ApiErrorCode::MethodNotAccessible;
        assert!(
            !code.is_premium_required(),
            "Code 12 should NOT be premium required"
        );
        assert!(
            code.is_auth_related(),
            "Code 12 should be auth-related (scope issue)"
        );
    }

    #[test]
    fn test_code_24_is_premium() {
        // Only code 24 indicates premium required
        let code = ApiErrorCode::PremiumRequired;
        assert!(
            code.is_premium_required(),
            "Code 24 should be premium required"
        );
        assert!(
            !code.is_auth_related(),
            "Code 24 should NOT be auth-related"
        );
    }

    #[test]
    fn test_is_not_found() {
        assert!(ApiErrorCode::FoodNotFound.is_not_found());
        assert!(ApiErrorCode::RecipeNotFound.is_not_found());
        assert!(ApiErrorCode::FoodEntryNotFound.is_not_found());
        assert!(ApiErrorCode::UserProfileNotFound.is_not_found());

        // Non-404 codes should not be "not found"
        assert!(!ApiErrorCode::MissingRequiredParameter.is_not_found());
        assert!(!ApiErrorCode::DuplicateEntry.is_not_found());
    }

    #[test]
    fn test_is_parameter_error() {
        assert!(ApiErrorCode::MissingRequiredParameter.is_parameter_error());
        assert!(ApiErrorCode::InvalidFoodId.is_parameter_error());
        assert!(ApiErrorCode::InvalidDateFormat.is_parameter_error());

        // Non-parameter codes should not match
        assert!(!ApiErrorCode::FoodNotFound.is_parameter_error());
        assert!(!ApiErrorCode::InvalidAccessToken.is_parameter_error());
    }

    #[test]
    #[allow(clippy::cognitive_complexity)]
    fn test_fatsecret_error_is_recoverable() {
        // Network errors are recoverable
        assert!(FatSecretError::network_error("timeout").is_recoverable());

        // Rate limit exceeded is recoverable
        assert!(FatSecretError::ApiError {
            code: ApiErrorCode::RateLimitExceeded,
            message: "try again".into()
        }
        .is_recoverable());

        // OAuth 2.0 token expired is recoverable (can refresh)
        assert!(FatSecretError::ApiError {
            code: ApiErrorCode::OAuth2TokenExpired,
            message: "token expired".into()
        }
        .is_recoverable());

        // 5xx errors are recoverable
        assert!(FatSecretError::request_failed(500, "server error").is_recoverable());
        assert!(FatSecretError::request_failed(503, "service unavailable").is_recoverable());

        // 4xx errors are not recoverable
        assert!(!FatSecretError::request_failed(400, "bad request").is_recoverable());
        assert!(!FatSecretError::request_failed(404, "not found").is_recoverable());

        // Auth errors (except token expiry) are not recoverable (need re-auth)
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
    fn test_fatsecret_error_is_premium_required() {
        // Only code 24 should indicate premium required
        assert!(FatSecretError::ApiError {
            code: ApiErrorCode::PremiumRequired,
            message: "feature not available".into()
        }
        .is_premium_required());

        // Code 12 should NOT indicate premium required
        assert!(!FatSecretError::ApiError {
            code: ApiErrorCode::MethodNotAccessible,
            message: "method not accessible".into()
        }
        .is_premium_required());
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

        // OAuth 2.0 errors are also auth errors
        assert!(FatSecretError::ApiError {
            code: ApiErrorCode::OAuth2InvalidToken,
            message: "invalid".into()
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
    fn test_parse_error_response_code_12() {
        let body = r#"{"error": {"code": 12, "message": "Method not accessible"}}"#;
        let error = parse_error_response(body).expect("should parse");

        match error {
            FatSecretError::ApiError { code, message } => {
                assert_eq!(code, ApiErrorCode::MethodNotAccessible);
                assert_eq!(message, "Method not accessible");
                assert!(
                    code.is_auth_related(),
                    "Code 12 should be auth-related (scope issue)"
                );
                assert!(!code.is_premium_required(), "Code 12 should NOT be premium");
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
    fn test_error_display_code_12_clarifies_not_premium() {
        let error = FatSecretError::ApiError {
            code: ApiErrorCode::MethodNotAccessible,
            message: "Method not accessible".into(),
        };
        let display = error.to_string();
        assert!(display.contains("code 12"), "should contain code 12");
        assert!(
            display.contains("NOT a premium issue"),
            "should clarify this is not premium: {}",
            display
        );
    }

    #[test]
    fn test_error_display() {
        let error = FatSecretError::ApiError {
            code: ApiErrorCode::InvalidAccessToken,
            message: "Token has expired".into(),
        };
        let display = error.to_string();
        assert!(display.contains("Invalid"));
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

    #[test]
    fn test_error_code_distinctions() {
        // Ensure error codes are correctly distinguished:
        // - Code 12: Auth/scope issue (is_auth_related = true, is_premium_required = false)
        // - Code 24: Premium required (is_auth_related = false, is_premium_required = true)
        // - Code 204: Not found (is_auth_related = false, is_premium_required = false, is_not_found = true)

        // Code 12 - MethodNotAccessible
        assert!(ApiErrorCode::MethodNotAccessible.is_auth_related());
        assert!(!ApiErrorCode::MethodNotAccessible.is_premium_required());
        assert!(!ApiErrorCode::MethodNotAccessible.is_not_found());

        // Code 24 - PremiumRequired
        assert!(!ApiErrorCode::PremiumRequired.is_auth_related());
        assert!(ApiErrorCode::PremiumRequired.is_premium_required());
        assert!(!ApiErrorCode::PremiumRequired.is_not_found());

        // Code 204 - FoodEntryNotFound
        assert!(!ApiErrorCode::FoodEntryNotFound.is_auth_related());
        assert!(!ApiErrorCode::FoodEntryNotFound.is_premium_required());
        assert!(ApiErrorCode::FoodEntryNotFound.is_not_found());
    }
}

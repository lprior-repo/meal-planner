//! Error Types for Sync Layer
//!
//! This module provides comprehensive error handling for all sync operations.
//! Errors are categorized by source and include rich context for debugging.
//!
//! # Error Categories
//!
//! - **Configuration errors**: Invalid or missing configuration
//! - **API errors**: FatSecret or Tandoor API failures
//! - **Validation errors**: Invalid input data
//! - **Sync errors**: Synchronization logic failures
//! - **Cache errors**: Cache operation failures
//! - **Matching errors**: Ingredient matching failures

use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Result type for sync operations
pub type SyncResult<T> = Result<T, SyncError>;

/// All possible errors from the sync layer
#[derive(Error, Debug)]
pub enum SyncError {
    // =========================================================================
    // Configuration Errors
    // =========================================================================

    /// Missing required configuration
    #[error("Missing configuration: {field}. {hint}")]
    ConfigMissing {
        /// Field that is missing
        field: String,
        /// Hint for resolution
        hint: String,
    },

    /// Invalid configuration value
    #[error("Invalid configuration for {field}: {message}")]
    ConfigInvalid {
        /// Field that is invalid
        field: String,
        /// Error message
        message: String,
    },

    // =========================================================================
    // FatSecret API Errors
    // =========================================================================

    /// FatSecret API error
    #[error("FatSecret API error: {message} (code: {code})")]
    FatSecretApi {
        /// Error code
        code: i32,
        /// Error message
        message: String,
    },

    /// FatSecret authentication error
    #[error("FatSecret authentication failed: {message}")]
    FatSecretAuth {
        /// Error message
        message: String,
    },

    /// FatSecret rate limit exceeded
    #[error("FatSecret rate limit exceeded. Retry after {retry_after_seconds} seconds.")]
    FatSecretRateLimit {
        /// Seconds to wait before retry
        retry_after_seconds: u32,
    },

    /// FatSecret food not found
    #[error("FatSecret food not found: {query}")]
    FatSecretFoodNotFound {
        /// Search query
        query: String,
    },

    // =========================================================================
    // Tandoor API Errors
    // =========================================================================

    /// Tandoor API error
    #[error("Tandoor API error: {message} (status: {status})")]
    TandoorApi {
        /// HTTP status code
        status: u16,
        /// Error message
        message: String,
    },

    /// Tandoor authentication error
    #[error("Tandoor authentication failed: {message}")]
    TandoorAuth {
        /// Error message
        message: String,
    },

    /// Tandoor recipe not found
    #[error("Tandoor recipe not found: ID {recipe_id}")]
    TandoorRecipeNotFound {
        /// Recipe ID
        recipe_id: i64,
    },

    /// Tandoor meal plan not found
    #[error("Tandoor meal plan not found: ID {meal_plan_id}")]
    TandoorMealPlanNotFound {
        /// Meal plan ID
        meal_plan_id: i64,
    },

    // =========================================================================
    // Validation Errors
    // =========================================================================

    /// Invalid date format
    #[error("Invalid date format: {date}. Expected YYYY-MM-DD")]
    InvalidDate {
        /// The invalid date string
        date: String,
    },

    /// Invalid date range
    #[error("Invalid date range: {start} to {end}. {reason}")]
    InvalidDateRange {
        /// Start date
        start: String,
        /// End date
        end: String,
        /// Reason for invalidity
        reason: String,
    },

    /// Invalid meal type
    #[error("Invalid meal type: {meal_type}. Expected: breakfast, lunch, dinner, or other")]
    InvalidMealType {
        /// The invalid meal type
        meal_type: String,
    },

    /// Invalid nutrition data
    #[error("Invalid nutrition data: {message}")]
    InvalidNutrition {
        /// Error message
        message: String,
    },

    /// Invalid serving
    #[error("Invalid serving: {message}")]
    InvalidServing {
        /// Error message
        message: String,
    },

    /// Validation failed
    #[error("Validation failed: {message}")]
    ValidationFailed {
        /// Error message
        message: String,
    },

    // =========================================================================
    // Sync Operation Errors
    // =========================================================================

    /// Sync operation failed
    #[error("Sync failed: {operation}. {message}")]
    SyncFailed {
        /// Operation that failed
        operation: String,
        /// Error message
        message: String,
    },

    /// Partial sync failure
    #[error("Partial sync failure: {succeeded} succeeded, {failed} failed out of {total}")]
    PartialSyncFailure {
        /// Number of successful items
        succeeded: usize,
        /// Number of failed items
        failed: usize,
        /// Total items
        total: usize,
        /// Error details
        errors: Vec<String>,
    },

    /// Recipe has no nutrition data
    #[error("Recipe {recipe_id} ({recipe_name}) has no nutrition data. Run nutrition calculation first.")]
    RecipeNoNutrition {
        /// Recipe ID
        recipe_id: i64,
        /// Recipe name
        recipe_name: String,
    },

    /// Ingredient has no match
    #[error("No match found for ingredient: {ingredient}")]
    IngredientNoMatch {
        /// Ingredient name
        ingredient: String,
    },

    // =========================================================================
    // Cache Errors
    // =========================================================================

    /// Cache miss
    #[error("Cache miss for key: {key}")]
    CacheMiss {
        /// Cache key
        key: String,
    },

    /// Cache expired
    #[error("Cache expired for key: {key}")]
    CacheExpired {
        /// Cache key
        key: String,
    },

    /// Cache operation failed
    #[error("Cache operation failed: {operation}. {message}")]
    CacheError {
        /// Operation that failed
        operation: String,
        /// Error message
        message: String,
    },

    // =========================================================================
    // Matching Errors
    // =========================================================================

    /// No matches found
    #[error("No matches found for: {query}")]
    NoMatches {
        /// Search query
        query: String,
    },

    /// Ambiguous match
    #[error("Ambiguous match for: {query}. Found {count} potential matches.")]
    AmbiguousMatch {
        /// Search query
        query: String,
        /// Number of matches
        count: usize,
    },

    /// Low confidence match
    #[error("Low confidence match for: {query}. Best match: {best_match} (confidence: {confidence:.2})")]
    LowConfidenceMatch {
        /// Search query
        query: String,
        /// Best matching result
        best_match: String,
        /// Confidence score (0.0 - 1.0)
        confidence: f64,
    },

    // =========================================================================
    // Batch Operation Errors
    // =========================================================================

    /// Batch operation exceeded limit
    #[error("Batch operation exceeded limit: {count} items (max: {max})")]
    BatchLimitExceeded {
        /// Requested count
        count: usize,
        /// Maximum allowed
        max: usize,
    },

    /// Batch operation cancelled
    #[error("Batch operation cancelled after processing {processed} of {total} items")]
    BatchCancelled {
        /// Items processed before cancellation
        processed: usize,
        /// Total items
        total: usize,
    },

    // =========================================================================
    // Network Errors
    // =========================================================================

    /// Network error
    #[error("Network error: {message}")]
    Network {
        /// Error message
        message: String,
    },

    /// Timeout error
    #[error("Request timed out after {timeout_ms}ms")]
    Timeout {
        /// Timeout in milliseconds
        timeout_ms: u64,
    },

    // =========================================================================
    // Internal Errors
    // =========================================================================

    /// Parse error
    #[error("Parse error: {message}")]
    Parse {
        /// Error message
        message: String,
    },

    /// Serialization error
    #[error("Serialization error: {message}")]
    Serialization {
        /// Error message
        message: String,
    },

    /// Internal error (should not happen)
    #[error("Internal error: {message}")]
    Internal {
        /// Error message
        message: String,
    },
}

impl SyncError {
    // =========================================================================
    // Constructor Helpers
    // =========================================================================

    /// Create a configuration missing error
    pub fn config_missing(field: impl Into<String>, hint: impl Into<String>) -> Self {
        Self::ConfigMissing {
            field: field.into(),
            hint: hint.into(),
        }
    }

    /// Create a configuration invalid error
    pub fn config_invalid(field: impl Into<String>, message: impl Into<String>) -> Self {
        Self::ConfigInvalid {
            field: field.into(),
            message: message.into(),
        }
    }

    /// Create a FatSecret API error
    pub fn fatsecret_api(code: i32, message: impl Into<String>) -> Self {
        Self::FatSecretApi {
            code,
            message: message.into(),
        }
    }

    /// Create a FatSecret auth error
    pub fn fatsecret_auth(message: impl Into<String>) -> Self {
        Self::FatSecretAuth {
            message: message.into(),
        }
    }

    /// Create a Tandoor API error
    pub fn tandoor_api(status: u16, message: impl Into<String>) -> Self {
        Self::TandoorApi {
            status,
            message: message.into(),
        }
    }

    /// Create a sync failed error
    pub fn sync_failed(operation: impl Into<String>, message: impl Into<String>) -> Self {
        Self::SyncFailed {
            operation: operation.into(),
            message: message.into(),
        }
    }

    /// Create a validation failed error
    pub fn validation_failed(message: impl Into<String>) -> Self {
        Self::ValidationFailed {
            message: message.into(),
        }
    }

    /// Create a cache error
    pub fn cache_error(operation: impl Into<String>, message: impl Into<String>) -> Self {
        Self::CacheError {
            operation: operation.into(),
            message: message.into(),
        }
    }

    /// Create a parse error
    pub fn parse_error(message: impl Into<String>) -> Self {
        Self::Parse {
            message: message.into(),
        }
    }

    /// Create an internal error
    pub fn internal(message: impl Into<String>) -> Self {
        Self::Internal {
            message: message.into(),
        }
    }

    /// Create a serialization error
    pub fn serialization(message: impl Into<String>) -> Self {
        Self::Serialization {
            message: message.into(),
        }
    }

    /// Create a validation error (alias for validation_failed)
    pub fn validation(message: impl Into<String>) -> Self {
        Self::ValidationFailed {
            message: message.into(),
        }
    }

    // =========================================================================
    // Error Classification
    // =========================================================================

    /// Check if error is recoverable (can retry)
    #[must_use]
    pub fn is_recoverable(&self) -> bool {
        matches!(
            self,
            Self::FatSecretRateLimit { .. }
                | Self::Network { .. }
                | Self::Timeout { .. }
                | Self::CacheMiss { .. }
                | Self::CacheExpired { .. }
        )
    }

    /// Check if error is an authentication error
    #[must_use]
    pub fn is_auth_error(&self) -> bool {
        matches!(
            self,
            Self::FatSecretAuth { .. } | Self::TandoorAuth { .. }
        )
    }

    /// Check if error is a not found error
    #[must_use]
    pub fn is_not_found(&self) -> bool {
        matches!(
            self,
            Self::FatSecretFoodNotFound { .. }
                | Self::TandoorRecipeNotFound { .. }
                | Self::TandoorMealPlanNotFound { .. }
                | Self::NoMatches { .. }
                | Self::CacheMiss { .. }
        )
    }

    /// Check if error is a validation error
    #[must_use]
    pub fn is_validation_error(&self) -> bool {
        matches!(
            self,
            Self::InvalidDate { .. }
                | Self::InvalidDateRange { .. }
                | Self::InvalidMealType { .. }
                | Self::InvalidNutrition { .. }
                | Self::InvalidServing { .. }
                | Self::ValidationFailed { .. }
                | Self::ConfigInvalid { .. }
        )
    }

    /// Check if error is a rate limit error
    #[must_use]
    pub fn is_rate_limit(&self) -> bool {
        matches!(self, Self::FatSecretRateLimit { .. })
    }

    /// Get recommended retry delay in seconds (if applicable)
    #[must_use]
    #[allow(clippy::wildcard_enum_match_arm)] // Only specific errors are retryable
    pub fn retry_after_seconds(&self) -> Option<u32> {
        match self {
            Self::FatSecretRateLimit { retry_after_seconds } => Some(*retry_after_seconds),
            Self::Network { .. } | Self::Timeout { .. } => Some(5),
            _ => None,
        }
    }

    /// Convert to error code for API responses
    #[must_use]
    pub fn error_code(&self) -> &'static str {
        match self {
            Self::ConfigMissing { .. } => "CONFIG_MISSING",
            Self::ConfigInvalid { .. } => "CONFIG_INVALID",
            Self::FatSecretApi { .. } => "FATSECRET_API_ERROR",
            Self::FatSecretAuth { .. } => "FATSECRET_AUTH_ERROR",
            Self::FatSecretRateLimit { .. } => "FATSECRET_RATE_LIMIT",
            Self::FatSecretFoodNotFound { .. } => "FATSECRET_FOOD_NOT_FOUND",
            Self::TandoorApi { .. } => "TANDOOR_API_ERROR",
            Self::TandoorAuth { .. } => "TANDOOR_AUTH_ERROR",
            Self::TandoorRecipeNotFound { .. } => "TANDOOR_RECIPE_NOT_FOUND",
            Self::TandoorMealPlanNotFound { .. } => "TANDOOR_MEAL_PLAN_NOT_FOUND",
            Self::InvalidDate { .. } => "INVALID_DATE",
            Self::InvalidDateRange { .. } => "INVALID_DATE_RANGE",
            Self::InvalidMealType { .. } => "INVALID_MEAL_TYPE",
            Self::InvalidNutrition { .. } => "INVALID_NUTRITION",
            Self::InvalidServing { .. } => "INVALID_SERVING",
            Self::ValidationFailed { .. } => "VALIDATION_FAILED",
            Self::SyncFailed { .. } => "SYNC_FAILED",
            Self::PartialSyncFailure { .. } => "PARTIAL_SYNC_FAILURE",
            Self::RecipeNoNutrition { .. } => "RECIPE_NO_NUTRITION",
            Self::IngredientNoMatch { .. } => "INGREDIENT_NO_MATCH",
            Self::CacheMiss { .. } => "CACHE_MISS",
            Self::CacheExpired { .. } => "CACHE_EXPIRED",
            Self::CacheError { .. } => "CACHE_ERROR",
            Self::NoMatches { .. } => "NO_MATCHES",
            Self::AmbiguousMatch { .. } => "AMBIGUOUS_MATCH",
            Self::LowConfidenceMatch { .. } => "LOW_CONFIDENCE_MATCH",
            Self::BatchLimitExceeded { .. } => "BATCH_LIMIT_EXCEEDED",
            Self::BatchCancelled { .. } => "BATCH_CANCELLED",
            Self::Network { .. } => "NETWORK_ERROR",
            Self::Timeout { .. } => "TIMEOUT",
            Self::Parse { .. } => "PARSE_ERROR",
            Self::Serialization { .. } => "SERIALIZATION_ERROR",
            Self::Internal { .. } => "INTERNAL_ERROR",
        }
    }
}

// =============================================================================
// Error Response Types (for JSON output)
// =============================================================================

/// Structured error response for JSON output
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorResponse {
    /// Whether the operation succeeded (always false for errors)
    pub success: bool,
    /// Error code
    pub error_code: String,
    /// Human-readable error message
    pub error: String,
    /// Whether the error is recoverable
    pub recoverable: bool,
    /// Recommended retry delay in seconds (if applicable)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub retry_after_seconds: Option<u32>,
    /// Additional error details
    #[serde(skip_serializing_if = "Option::is_none")]
    pub details: Option<serde_json::Value>,
}

impl From<&SyncError> for ErrorResponse {
    fn from(error: &SyncError) -> Self {
        Self {
            success: false,
            error_code: error.error_code().to_string(),
            error: error.to_string(),
            recoverable: error.is_recoverable(),
            retry_after_seconds: error.retry_after_seconds(),
            details: None,
        }
    }
}

impl From<SyncError> for ErrorResponse {
    fn from(error: SyncError) -> Self {
        Self::from(&error)
    }
}

// =============================================================================
// Error Conversions
// =============================================================================

impl From<serde_json::Error> for SyncError {
    fn from(error: serde_json::Error) -> Self {
        Self::Parse {
            message: error.to_string(),
        }
    }
}

impl From<std::io::Error> for SyncError {
    fn from(error: std::io::Error) -> Self {
        Self::Internal {
            message: format!("I/O error: {error}"),
        }
    }
}

// =============================================================================
// Validation Result Type
// =============================================================================

/// Result of a validation operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationResult {
    /// Whether validation passed
    pub is_valid: bool,
    /// List of validation errors
    pub errors: Vec<ValidationError>,
    /// List of validation warnings
    pub warnings: Vec<ValidationWarning>,
}

impl ValidationResult {
    /// Create a successful validation result
    #[must_use]
    pub fn ok() -> Self {
        Self {
            is_valid: true,
            errors: Vec::new(),
            warnings: Vec::new(),
        }
    }

    /// Create a failed validation result
    #[must_use]
    pub fn fail(errors: Vec<ValidationError>) -> Self {
        Self {
            is_valid: false,
            errors,
            warnings: Vec::new(),
        }
    }

    /// Add an error
    pub fn add_error(&mut self, error: ValidationError) {
        self.errors.push(error);
        self.is_valid = false;
    }

    /// Add a warning
    pub fn add_warning(&mut self, warning: ValidationWarning) {
        self.warnings.push(warning);
    }

    /// Convert to SyncError if validation failed
    pub fn to_sync_error(&self) -> Option<SyncError> {
        if self.is_valid {
            None
        } else {
            let messages: Vec<String> = self.errors.iter().map(|e| e.message.clone()).collect();
            Some(SyncError::validation_failed(messages.join("; ")))
        }
    }
}

impl Default for ValidationResult {
    fn default() -> Self {
        Self::ok()
    }
}

/// A validation error
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationError {
    /// Field that failed validation
    pub field: String,
    /// Error message
    pub message: String,
    /// Error code
    pub code: String,
}

impl ValidationError {
    /// Create a new validation error
    pub fn new(field: impl Into<String>, message: impl Into<String>, code: impl Into<String>) -> Self {
        Self {
            field: field.into(),
            message: message.into(),
            code: code.into(),
        }
    }

    /// Create a required field error
    pub fn required(field: impl Into<String>) -> Self {
        let field_str = field.into();
        Self {
            field: field_str.clone(),
            message: format!("{field_str} is required"),
            code: "REQUIRED".to_string(),
        }
    }

    /// Create an invalid value error
    pub fn invalid(field: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            field: field.into(),
            message: message.into(),
            code: "INVALID".to_string(),
        }
    }
}

/// A validation warning
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ValidationWarning {
    /// Field with warning
    pub field: String,
    /// Warning message
    pub message: String,
}

impl ValidationWarning {
    /// Create a new validation warning
    pub fn new(field: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            field: field.into(),
            message: message.into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sync_error_is_recoverable() {
        assert!(SyncError::FatSecretRateLimit { retry_after_seconds: 60 }.is_recoverable());
        assert!(SyncError::Network { message: "timeout".into() }.is_recoverable());
        assert!(SyncError::Timeout { timeout_ms: 5000 }.is_recoverable());
        assert!(SyncError::CacheMiss { key: "test".into() }.is_recoverable());

        assert!(!SyncError::FatSecretAuth { message: "invalid".into() }.is_recoverable());
        assert!(!SyncError::TandoorRecipeNotFound { recipe_id: 1 }.is_recoverable());
    }

    #[test]
    fn test_sync_error_is_auth_error() {
        assert!(SyncError::FatSecretAuth { message: "invalid".into() }.is_auth_error());
        assert!(SyncError::TandoorAuth { message: "invalid".into() }.is_auth_error());

        assert!(!SyncError::FatSecretApi { code: 101, message: "error".into() }.is_auth_error());
    }

    #[test]
    fn test_sync_error_is_not_found() {
        assert!(SyncError::FatSecretFoodNotFound { query: "test".into() }.is_not_found());
        assert!(SyncError::TandoorRecipeNotFound { recipe_id: 1 }.is_not_found());
        assert!(SyncError::NoMatches { query: "test".into() }.is_not_found());

        assert!(!SyncError::FatSecretAuth { message: "invalid".into() }.is_not_found());
    }

    #[test]
    fn test_sync_error_retry_after() {
        assert_eq!(
            SyncError::FatSecretRateLimit { retry_after_seconds: 60 }.retry_after_seconds(),
            Some(60)
        );
        assert_eq!(
            SyncError::Network { message: "timeout".into() }.retry_after_seconds(),
            Some(5)
        );
        assert_eq!(
            SyncError::FatSecretAuth { message: "invalid".into() }.retry_after_seconds(),
            None
        );
    }

    #[test]
    fn test_error_response_from_sync_error() {
        let error = SyncError::FatSecretRateLimit { retry_after_seconds: 60 };
        let response = ErrorResponse::from(&error);

        assert!(!response.success);
        assert_eq!(response.error_code, "FATSECRET_RATE_LIMIT");
        assert!(response.recoverable);
        assert_eq!(response.retry_after_seconds, Some(60));
    }

    #[test]
    fn test_validation_result() {
        let mut result = ValidationResult::ok();
        assert!(result.is_valid);

        result.add_error(ValidationError::required("name"));
        assert!(!result.is_valid);

        let sync_error = result.to_sync_error();
        assert!(sync_error.is_some());
    }

    #[test]
    fn test_sync_error_constructors() {
        let error = SyncError::config_missing("api_token", "Set TANDOOR_API_TOKEN environment variable");
        assert!(matches!(error, SyncError::ConfigMissing { .. }));

        let error = SyncError::fatsecret_api(101, "Missing parameter");
        assert!(matches!(error, SyncError::FatSecretApi { code: 101, .. }));

        let error = SyncError::sync_failed("meal_plan_sync", "Recipe not found");
        assert!(matches!(error, SyncError::SyncFailed { .. }));
    }

    #[test]
    fn test_error_codes() {
        assert_eq!(SyncError::ConfigMissing { field: "x".into(), hint: "y".into() }.error_code(), "CONFIG_MISSING");
        assert_eq!(SyncError::FatSecretApi { code: 1, message: "x".into() }.error_code(), "FATSECRET_API_ERROR");
        assert_eq!(SyncError::TandoorRecipeNotFound { recipe_id: 1 }.error_code(), "TANDOOR_RECIPE_NOT_FOUND");
        assert_eq!(SyncError::Internal { message: "x".into() }.error_code(), "INTERNAL_ERROR");
    }
}

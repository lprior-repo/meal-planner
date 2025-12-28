//! Error handling for the Meal Planner application
//!
//! Provides custom error types and error handling utilities.

use std::fmt;

use serde::{Deserialize, Serialize};
use thiserror::Error;
use tracing::{error, warn};

/// Application error types
#[derive(Error, Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum Error {
    /// Database error
    #[error("Database error: {message}")]
    Database {
        message: String,
        #[source]
        source: Option<Box<dyn std::error::Error>>,
    },
    
    /// HTTP error
    #[error("HTTP error: {message}")]
    Http {
        message: String,
        status_code: u16,
        #[source]
        source: Option<Box<dyn std::error::Error>>,
    },
    
    /// Configuration error
    #[error("Configuration error: {message}")]
    Config {
        message: String,
        #[source]
        source: Option<Box<dyn std::error::Error>>,
    },
    
    /// Validation error
    #[error("Validation error: {message}")]
    Validation {
        message: String,
        field: Option<String>,
        #[source]
        source: Option<Box<dyn std::error::Error>>,
    },
    
    /// Authentication error
    #[error("Authentication error: {message}")]
    Auth {
        message: String,
        #[source]
        source: Option<Box<dyn std::error::Error>>,
    },
    
    /// External API error
    #[error("External API error: {message}")]
    ExternalApi {
        message: String,
        service: String,
        #[source]
        source: Option<Box<dyn std::error::Error>>,
    },
    
    /// Resource not found error
    #[error("Resource not found: {message}")]
    NotFound {
        message: String,
        resource_type: String,
        #[source]
        source: Option<Box<dyn std::error::Error>>,
    },
    
    /// Internal error
    #[error("Internal error: {message}")]
    Internal {
        message: String,
        #[source]
        source: Option<Box<dyn std::error::Error>>,
    },
}

impl Error {
    /// Create a new database error
    pub fn database(message: impl Into<String>) -> Self {
        Self::Database {
            message: message.into(),
            source: None,
        }
    }
    
    /// Create a new HTTP error
    pub fn http(message: impl Into<String>, status_code: u16) -> Self {
        Self::Http {
            message: message.into(),
            status_code,
            source: None,
        }
    }
    
    /// Create a new configuration error
    pub fn config(message: impl Into<String>) -> Self {
        Self::Config {
            message: message.into(),
            source: None,
        }
    }
    
    /// Create a new validation error
    pub fn validation(message: impl Into<String>, field: Option<String>) -> Self {
        Self::Validation {
            message: message.into(),
            field,
            source: None,
        }
    }
    
    /// Create a new authentication error
    pub fn auth(message: impl Into<String>) -> Self {
        Self::Auth {
            message: message.into(),
            source: None,
        }
    }
    
    /// Create a new external API error
    pub fn external_api(message: impl Into<String>, service: impl Into<String>) -> Self {
        Self::ExternalApi {
            message: message.into(),
            service: service.into(),
            source: None,
        }
    }
    
    /// Create a new not found error
    pub fn not_found(message: impl Into<String>, resource_type: impl Into<String>) -> Self {
        Self::NotFound {
            message: message.into(),
            resource_type: resource_type.into(),
            source: None,
        }
    }
    
    /// Create a new internal error
    pub fn internal(message: impl Into<String>) -> Self {
        Self::Internal {
            message: message.into(),
            source: None,
        }
    }
    
    /// Get the error status code (for HTTP responses)
    pub fn status_code(&self) -> u16 {
        match self {
            Error::Database { .. } => 500,
            Error::Http { status_code, .. } => *status_code,
            Error::Config { .. } => 500,
            Error::Validation { .. } => 400,
            Error::Auth { .. } => 401,
            Error::ExternalApi { .. } => 502,
            Error::NotFound { .. } => 404,
            Error::Internal { .. } => 500,
        }
    }
    
    /// Get the error type as a string
    pub fn error_type(&self) -> &str {
        match self {
            Error::Database { .. } => "database",
            Error::Http { .. } => "http",
            Error::Config { .. } => "config",
            Error::Validation { .. } => "validation",
            Error::Auth { .. } => "auth",
            Error::ExternalApi { .. } => "external_api",
            Error::NotFound { .. } => "not_found",
            Error::Internal { .. } => "internal",
        }
    }
}

impl From<tokio_postgres::Error> for Error {
    fn from(error: tokio_postgres::Error) -> Self {
        Self::Database {
            message: error.to_string(),
            source: Some(Box::new(error)),
        }
    }
}

impl From<serde_json::Error> for Error {
    fn from(error: serde_json::Error) -> Self {
        Self::Internal {
            message: format!("JSON serialization error: {}", error),
            source: Some(Box::new(error)),
        }
    }
}

impl From<reqwest::Error> for Error {
    fn from(error: reqwest::Error) -> Self {
        Self::ExternalApi {
            message: format!("External API error: {}", error),
            service: "external".to_string(),
            source: Some(Box::new(error)),
        }
    }
}

impl From<clap::Error> for Error {
    fn from(error: clap::Error) -> Self {
        Self::Validation {
            message: format!("CLI argument error: {}", error),
            field: None,
            source: Some(Box::new(error)),
        }
    }
}

impl From<uuid::Error> for Error {
    fn from(error: uuid::Error) -> Self {
        Self::Validation {
            message: format!("UUID error: {}", error),
            field: None,
            source: Some(Box::new(error)),
        }
    }
}

impl From<chrono::ParseError> for Error {
    fn from(error: chrono::ParseError) -> Self {
        Self::Validation {
            message: format!("Date parsing error: {}", error),
            field: None,
            source: Some(Box::new(error)),
        }
    }
}

/// Error logging helper
pub fn log_error(error: &Error) {
    error!(
        error_type = error.error_type(),
        status_code = error.status_code(),
        message = error.to_string()
    );
}

/// Error formatting helper
pub fn format_error(error: &Error) -> String {
    match error {
        Error::Database { message, .. } => format!("Database Error: {}", message),
        Error::Http { message, status_code, .. } => format!("HTTP Error {}: {}", status_code, message),
        Error::Config { message, .. } => format!("Configuration Error: {}", message),
        Error::Validation { message, field, .. } => {
            if let Some(field) = field {
                format!("Validation Error ({}): {}", field, message)
            } else {
                format!("Validation Error: {}", message)
            }
        }
        Error::Auth { message, .. } => format!("Authentication Error: {}", message),
        Error::ExternalApi { message, service, .. } => {
            format!("External API Error ({}): {}", service, message)
        }
        Error::NotFound { message, resource_type, .. } => {
            format!("Not Found Error ({}): {}", resource_type, message)
        }
        Error::Internal { message, .. } => format!("Internal Error: {}", message),
    }
}

/// Result type alias for convenience
pub type Result<T> = std::result::Result<T, Error>;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_error_creation() {
        let db_error = Error::database("Test database error");
        assert_eq!(db_error.error_type(), "database");
        
        let http_error = Error::http("Test HTTP error", 404);
        assert_eq!(http_error.error_type(), "http");
        assert_eq!(http_error.status_code(), 404);
    }

    #[test]
    fn test_error_formatting() {
        let error = Error::validation("Test validation error", Some("field".to_string()));
        let formatted = format_error(&error);
        assert!(formatted.contains("Validation Error"));
        assert!(formatted.contains("field"));
    }
}
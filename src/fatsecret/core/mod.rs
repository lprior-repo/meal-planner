//! `FatSecret` Core module
//!
//! Contains configuration, error types, OAuth utilities, and HTTP client.

pub mod config;
pub mod errors;
pub mod http;
pub mod oauth;
pub mod serde_utils;

pub use config::FatSecretConfig;
pub use errors::{parse_error_response, ApiErrorCode, FatSecretError};
pub use http::{make_api_request, make_authenticated_request, make_oauth_request};
pub use oauth::{AccessToken, RequestToken};

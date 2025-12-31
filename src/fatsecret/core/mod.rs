//! `FatSecret` Core module
//!
//! Contains configuration, error types, OAuth utilities, and HTTP client.

pub mod config;
pub mod errors;
pub mod http;
pub mod oauth;
pub mod params;
pub mod serde_utils;

pub use config::FatSecretConfig;
pub use errors::{parse_error_response, ApiErrorCode, FatSecretError};
pub use http::{
    make_api_request, make_authenticated_request, make_oauth_request, parse_api_response,
    parse_authenticated_response,
};
pub use oauth::{AccessToken, RequestToken};
pub use params::ParamBuilder;

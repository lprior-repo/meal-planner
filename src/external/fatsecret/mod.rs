//! FatSecret API integration for calorie tracking sync
//!
//! This module provides OAuth token storage and encryption for the FatSecret API.
//! Ported from the Gleam implementation in src/meal_planner/fatsecret/.

pub mod crypto;
pub mod storage;

// Re-export commonly used types
pub use crypto::{
    decrypt, encrypt, generate_key, is_configured as encryption_configured, CryptoError,
};
pub use storage::{
    cleanup_expired_pending, delete_access_token,
    encryption_configured as storage_encryption_configured, get_access_token, get_access_token_opt,
    get_pending_token, is_connected, store_access_token, store_pending_token, touch_access_token,
    verify_token_validity, AccessToken, RequestToken, StorageError, TokenValidity,
};

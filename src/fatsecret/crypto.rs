//! Encryption utilities for OAuth token storage
//!
//! Uses AES-256-GCM for authenticated encryption of OAuth tokens.

use aes_gcm::{
    aead::rand_core::RngCore,
    aead::{Aead, AeadCore, KeyInit, OsRng},
    Aes256Gcm, Nonce,
};
use base64::{engine::general_purpose::STANDARD, Engine};
use std::env;
use thiserror::Error;

/// Encryption errors
#[derive(Debug, Error)]
pub enum CryptoError {
    /// Encryption key not configured in environment
    #[error("Encryption key not configured (set OAUTH_ENCRYPTION_KEY env var)")]
    KeyNotConfigured,
    /// Key has invalid length (expected 64 hex chars / 32 bytes)
    #[error("Encryption key must be 64 hex characters (32 bytes), got {0} chars")]
    KeyInvalidLength(usize),
    /// Key contains invalid hexadecimal characters
    #[error("Encryption key must be valid hex string")]
    KeyInvalidHex,
    /// Ciphertext format is invalid or data is corrupted
    #[error("Ciphertext is invalid or corrupted")]
    InvalidCiphertext,
    /// Decryption failed due to wrong key or corrupted data
    #[error("Decryption failed (wrong key or corrupted data)")]
    DecryptionFailed,
}

/// Token storage errors
#[derive(Debug, Error)]
pub enum StorageError {
    /// No token found in storage
    #[error("Token not found")]
    NotFound,
    /// Database operation failed
    #[error("Database error: {0}")]
    DatabaseError(String),
    /// Encryption or decryption operation failed
    #[error("Crypto error: {0}")]
    CryptoError(String),
}

impl From<CryptoError> for StorageError {
    fn from(err: CryptoError) -> Self {
        StorageError::CryptoError(err.to_string())
    }
}

/// Token validity status
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TokenValidity {
    /// Token is valid and ready to use
    Valid,
    /// No token stored
    NotFound,
    /// Token exists but is old (> 365 days)
    Old {
        /// Number of days since the OAuth connection was established
        days_since_connected: i32,
    },
}

/// Check if encryption is properly configured
pub fn encryption_configured() -> bool {
    match get_encryption_key() {
        Ok(_) => true,
        Err(
            CryptoError::KeyNotConfigured
            | CryptoError::KeyInvalidLength(_)
            | CryptoError::KeyInvalidHex
            | CryptoError::InvalidCiphertext
            | CryptoError::DecryptionFailed,
        ) => false,
    }
}

/// Get encryption key from environment variable
///
/// Expects a 64-character hex string (32 bytes for AES-256)
fn get_encryption_key() -> Result<[u8; 32], CryptoError> {
    let key_str = env::var("OAUTH_ENCRYPTION_KEY").map_err(|_| CryptoError::KeyNotConfigured)?;

    if key_str.len() != 64 {
        return Err(CryptoError::KeyInvalidLength(key_str.len()));
    }

    let mut key = [0u8; 32];
    hex::decode_to_slice(&key_str, &mut key).map_err(|_| CryptoError::KeyInvalidHex)?;

    Ok(key)
}

/// Encrypt plaintext using AES-256-GCM
///
/// Returns a base64-encoded string containing:
/// - 12-byte nonce (IV)
/// - Ciphertext
/// - 16-byte authentication tag (GCM)
///
/// Format: [nonce (12 bytes)] || [ciphertext (N bytes)] || [tag (16 bytes)]
pub fn encrypt(plaintext: &str) -> Result<String, CryptoError> {
    let key_bytes = get_encryption_key()?;
    let cipher = Aes256Gcm::new(&key_bytes.into());

    // Generate nonce safely
    let nonce = {
        let mut rng = OsRng;
        Aes256Gcm::generate_nonce(&mut rng)
    };

    let ciphertext = cipher
        .encrypt(&nonce, plaintext.as_bytes())
        .map_err(|_| CryptoError::InvalidCiphertext)?;

    // Combine nonce + ciphertext and encode as base64
    let mut combined = nonce.to_vec();
    combined.extend_from_slice(&ciphertext);

    Ok(STANDARD.encode(combined))
}

/// Decrypt base64-encoded ciphertext
///
/// Expects format: [nonce (12 bytes)] || [ciphertext (N bytes)] || [tag (16 bytes)]
pub fn decrypt(encrypted: &str) -> Result<String, CryptoError> {
    let key_bytes = get_encryption_key()?;
    let cipher = Aes256Gcm::new(&key_bytes.into());

    // Decode base64
    let combined = STANDARD
        .decode(encrypted)
        .map_err(|_| CryptoError::InvalidCiphertext)?;

    // Check minimum length (12-byte nonce + 16-byte GCM tag)
    if combined.len() < 28 {
        return Err(CryptoError::InvalidCiphertext);
    }

    // Split into nonce and ciphertext+tag
    let (nonce_bytes, ciphertext) = combined.split_at(12);
    let nonce = Nonce::from_slice(nonce_bytes);

    cipher
        .decrypt(nonce, ciphertext)
        .map(|bytes| String::from_utf8(bytes).map_err(|_| CryptoError::DecryptionFailed))
        .map_err(|_| CryptoError::DecryptionFailed)?
}

/// Generate a random 32-byte key encoded as 64 hex characters
///
/// This can be used to generate a new key for OAUTH_ENCRYPTION_KEY env var
pub fn generate_key() -> String {
    let mut key_bytes = [0u8; 32];
    OsRng.fill_bytes(&mut key_bytes);
    hex::encode(key_bytes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_key_length() {
        let key = generate_key();
        assert_eq!(key.len(), 64);
    }

    #[test]
    fn test_generate_key_valid_hex() {
        let key = generate_key();
        assert!(key.chars().all(|c: char| c.is_ascii_hexdigit()));
    }

    #[test]
    fn test_generate_key_unique() {
        let key1 = generate_key();
        let key2 = generate_key();
        assert_ne!(key1, key2);
    }

    #[test]
    fn test_generate_key_unique_unsafe() {
        // Note: This test was previously wrapped in unsafe block unnecessarily
        // generate_key() is not unsafe, so the block was removed
        let key1 = generate_key();
        let key2 = generate_key();
        assert_ne!(key1, key2);
    }

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        env::set_var(
            "OAUTH_ENCRYPTION_KEY",
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        );

        let plaintext = "secret_oauth_token_value";
        let encrypted = encrypt(plaintext).expect("encryption should succeed");
        let decrypted = decrypt(&encrypted).expect("decryption should succeed");

        assert_eq!(plaintext, decrypted);

        env::remove_var("OAUTH_ENCRYPTION_KEY");
    }

    #[test]
    fn test_encrypt_decrypt_roundtrip_unsafe() {
        env::set_var(
            "OAUTH_ENCRYPTION_KEY",
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        );

        let plaintext = "secret_oauth_token_value";
        let encrypted = encrypt(plaintext).expect("encryption should succeed");
        let decrypted = decrypt(&encrypted).expect("decryption should succeed");

        assert_eq!(plaintext, decrypted);

        env::remove_var("OAUTH_ENCRYPTION_KEY");
    }

    #[test]
    fn test_encrypt_different_each_time() {
        env::set_var(
            "OAUTH_ENCRYPTION_KEY",
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        );

        let plaintext = "same_plaintext";
        let encrypted1 = encrypt(plaintext).expect("first encryption should succeed");
        let encrypted2 = encrypt(plaintext).expect("second encryption should succeed");

        assert_ne!(encrypted1, encrypted2);

        env::remove_var("OAUTH_ENCRYPTION_KEY");
    }

    #[test]
    fn test_encrypt_different_each_time_unsafe() {
        env::set_var(
            "OAUTH_ENCRYPTION_KEY",
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        );

        let plaintext = "same_plaintext";
        let encrypted1 = encrypt(plaintext).expect("first encryption should succeed");
        let encrypted2 = encrypt(plaintext).expect("second encryption should succeed");

        assert_ne!(encrypted1, encrypted2);

        env::remove_var("OAUTH_ENCRYPTION_KEY");
    }

    #[test]
    fn test_encrypt_without_key_fails() {
        env::remove_var("OAUTH_ENCRYPTION_KEY");
        let result = encrypt("test");
        assert!(matches!(result, Err(CryptoError::KeyNotConfigured)));
    }

    #[test]
    fn test_decrypt_with_wrong_key_fails() {
        let key1 = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        let key2 = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

        let plaintext = "secret_data";

        env::set_var("OAUTH_ENCRYPTION_KEY", key1);
        let encrypted = encrypt(plaintext).expect("should encrypt");

        env::set_var("OAUTH_ENCRYPTION_KEY", key2);
        let result = decrypt(&encrypted);
        assert!(matches!(result, Err(CryptoError::DecryptionFailed)));

        env::remove_var("OAUTH_ENCRYPTION_KEY");
    }

    #[test]
    fn test_encryption_configured() {
        env::remove_var("OAUTH_ENCRYPTION_KEY");
        assert!(!encryption_configured());

        env::set_var(
            "OAUTH_ENCRYPTION_KEY",
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        );
        assert!(encryption_configured());

        env::remove_var("OAUTH_ENCRYPTION_KEY");
    }
}

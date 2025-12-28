//! Encryption utilities for OAuth token secrets
//!
//! Uses AES-256-GCM for authenticated encryption of sensitive data.
//! The encryption key should be stored in the OAUTH_ENCRYPTION_KEY environment variable.

use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use ring::aead::{self, Aad, BoundKey, Nonce, NonceSequence, UnboundKey, AES_256_GCM};
use ring::error::Unspecified;
use ring::rand::{SecureRandom, SystemRandom};
use std::env;
use thiserror::Error;

/// Errors that can occur during cryptographic operations
#[derive(Error, Debug)]
pub enum CryptoError {
    #[error("OAUTH_ENCRYPTION_KEY environment variable not set")]
    KeyNotConfigured,

    #[error("OAUTH_ENCRYPTION_KEY must be 64 hex characters (32 bytes)")]
    KeyInvalidLength,

    #[error("Invalid hex in encryption key")]
    KeyInvalidHex,

    #[error("Encryption failed")]
    EncryptionFailed,

    #[error("Decryption failed: authentication or data corruption")]
    DecryptionFailed,

    #[error("Invalid ciphertext format")]
    InvalidCiphertext,
}

/// Nonce sequence that uses a single pre-generated nonce
struct SingleNonce(Option<[u8; 12]>);

impl SingleNonce {
    fn new(nonce_bytes: [u8; 12]) -> Self {
        Self(Some(nonce_bytes))
    }
}

impl NonceSequence for SingleNonce {
    fn advance(&mut self) -> Result<Nonce, Unspecified> {
        self.0
            .take()
            .map(Nonce::assume_unique_for_key)
            .ok_or(Unspecified)
    }
}

/// Get the encryption key from environment variable
fn get_encryption_key() -> Result<[u8; 32], CryptoError> {
    let key_hex = env::var("OAUTH_ENCRYPTION_KEY").map_err(|_| CryptoError::KeyNotConfigured)?;

    if key_hex.is_empty() {
        return Err(CryptoError::KeyNotConfigured);
    }

    let key_bytes = hex::decode(&key_hex).map_err(|_| CryptoError::KeyInvalidHex)?;

    if key_bytes.len() != 32 {
        return Err(CryptoError::KeyInvalidLength);
    }

    let mut key = [0u8; 32];
    key.copy_from_slice(&key_bytes);
    Ok(key)
}

/// Encrypt a plaintext string using AES-256-GCM
///
/// Returns base64-encoded ciphertext with prepended 12-byte nonce and appended 16-byte tag.
/// Format: base64(nonce || ciphertext || tag)
pub fn encrypt(plaintext: &str) -> Result<String, CryptoError> {
    let key_bytes = get_encryption_key()?;
    let rng = SystemRandom::new();

    // Generate random 12-byte nonce
    let mut nonce_bytes = [0u8; 12];
    rng.fill(&mut nonce_bytes)
        .map_err(|_| CryptoError::EncryptionFailed)?;

    // Create unbound key and then sealing key
    let unbound_key =
        UnboundKey::new(&AES_256_GCM, &key_bytes).map_err(|_| CryptoError::EncryptionFailed)?;

    let nonce_seq = SingleNonce::new(nonce_bytes);
    let mut sealing_key = aead::SealingKey::new(unbound_key, nonce_seq);

    // Prepare buffer: plaintext + space for 16-byte tag
    let mut in_out = plaintext.as_bytes().to_vec();

    // Seal in place (appends tag)
    sealing_key
        .seal_in_place_append_tag(Aad::empty(), &mut in_out)
        .map_err(|_| CryptoError::EncryptionFailed)?;

    // Combine: nonce || ciphertext_with_tag
    let mut combined = Vec::with_capacity(12 + in_out.len());
    combined.extend_from_slice(&nonce_bytes);
    combined.extend_from_slice(&in_out);

    Ok(BASE64.encode(&combined))
}

/// Decrypt a base64-encoded ciphertext
///
/// Expects format: base64(nonce || ciphertext || tag)
/// where nonce is 12 bytes and tag is 16 bytes
pub fn decrypt(ciphertext_b64: &str) -> Result<String, CryptoError> {
    let key_bytes = get_encryption_key()?;

    // Decode base64
    let combined = BASE64
        .decode(ciphertext_b64)
        .map_err(|_| CryptoError::InvalidCiphertext)?;

    // Must have at least nonce (12) + tag (16) = 28 bytes
    if combined.len() < 28 {
        return Err(CryptoError::InvalidCiphertext);
    }

    // Extract nonce (first 12 bytes)
    let mut nonce_bytes = [0u8; 12];
    nonce_bytes.copy_from_slice(&combined[..12]);

    // Ciphertext with tag is the rest
    let mut ciphertext_with_tag = combined[12..].to_vec();

    // Create opening key
    let unbound_key =
        UnboundKey::new(&AES_256_GCM, &key_bytes).map_err(|_| CryptoError::DecryptionFailed)?;

    let nonce_seq = SingleNonce::new(nonce_bytes);
    let mut opening_key = aead::OpeningKey::new(unbound_key, nonce_seq);

    // Open in place (verifies tag and returns plaintext slice)
    let plaintext_bytes = opening_key
        .open_in_place(Aad::empty(), &mut ciphertext_with_tag)
        .map_err(|_| CryptoError::DecryptionFailed)?;

    String::from_utf8(plaintext_bytes.to_vec()).map_err(|_| CryptoError::DecryptionFailed)
}

/// Check if encryption is properly configured
pub fn is_configured() -> bool {
    get_encryption_key().is_ok()
}

/// Generate a new random 32-byte encryption key as hex string
///
/// Use this to generate a value for OAUTH_ENCRYPTION_KEY environment variable
pub fn generate_key() -> String {
    let rng = SystemRandom::new();
    let mut key = [0u8; 32];
    rng.fill(&mut key).expect("Failed to generate random key");
    hex::encode(key)
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;
    use std::env;

    fn with_test_key<F, R>(f: F) -> R
    where
        F: FnOnce() -> R,
    {
        // Use a fixed test key (32 bytes = 64 hex chars)
        let test_key = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        env::set_var("OAUTH_ENCRYPTION_KEY", test_key);
        let result = f();
        env::remove_var("OAUTH_ENCRYPTION_KEY");
        result
    }

    #[test]
    #[serial]
    fn test_encrypt_decrypt_roundtrip() {
        with_test_key(|| {
            let original = "my_secret_oauth_token";
            let encrypted = encrypt(original).unwrap();
            let decrypted = decrypt(&encrypted).unwrap();
            assert_eq!(original, decrypted);
        });
    }

    #[test]
    #[serial]
    fn test_encrypt_produces_different_ciphertext() {
        with_test_key(|| {
            let original = "same_plaintext";
            let encrypted1 = encrypt(original).unwrap();
            let encrypted2 = encrypt(original).unwrap();
            // Due to random nonce, ciphertexts should differ
            assert_ne!(encrypted1, encrypted2);
        });
    }

    #[test]
    #[serial]
    fn test_decrypt_invalid_ciphertext() {
        with_test_key(|| {
            let result = decrypt("not_valid_base64!!!");
            assert!(matches!(result, Err(CryptoError::InvalidCiphertext)));
        });
    }

    #[test]
    #[serial]
    fn test_decrypt_too_short() {
        with_test_key(|| {
            // Valid base64 but too short (less than 28 bytes)
            let short = BASE64.encode([0u8; 20]);
            let result = decrypt(&short);
            assert!(matches!(result, Err(CryptoError::InvalidCiphertext)));
        });
    }

    #[test]
    #[serial]
    fn test_key_not_configured() {
        env::remove_var("OAUTH_ENCRYPTION_KEY");
        let result = encrypt("test");
        assert!(matches!(result, Err(CryptoError::KeyNotConfigured)));
    }

    #[test]
    #[serial]
    fn test_key_invalid_length() {
        env::set_var("OAUTH_ENCRYPTION_KEY", "too_short");
        let result = encrypt("test");
        env::remove_var("OAUTH_ENCRYPTION_KEY");
        assert!(matches!(
            result,
            Err(CryptoError::KeyInvalidHex) | Err(CryptoError::KeyInvalidLength)
        ));
    }

    #[test]
    #[serial]
    fn test_is_configured() {
        env::remove_var("OAUTH_ENCRYPTION_KEY");
        assert!(!is_configured());

        env::set_var(
            "OAUTH_ENCRYPTION_KEY",
            "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
        );
        assert!(is_configured());
        env::remove_var("OAUTH_ENCRYPTION_KEY");
    }

    #[test]
    fn test_generate_key_format() {
        let key = generate_key();
        assert_eq!(key.len(), 64); // 32 bytes = 64 hex chars
        assert!(key.chars().all(|c| c.is_ascii_hexdigit()));
    }
}

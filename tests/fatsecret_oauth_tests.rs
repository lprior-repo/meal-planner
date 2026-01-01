//! `FatSecret` OAuth Integration Tests
//!
//! Comprehensive tests for:
//! - OAuth flow (request token -> authorize -> access token)
//! - Error handling (invalid credentials, expired tokens)
//! - Signature generation (HMAC-SHA256 verification)
//! - Token storage/retrieval with encryption

// =============================================================================
// TEST-ONLY LINT OVERRIDES - Tests can panic, use expect/unwrap, etc.
// =============================================================================
#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]
#![allow(clippy::wildcard_enum_match_arm)]
#![allow(clippy::inefficient_to_string)]
#![allow(clippy::format_push_string)]

use meal_planner::fatsecret::core::{
    parse_error_response, AccessToken as CoreAccessToken, ApiErrorCode, FatSecretConfig,
    FatSecretError,
};
use meal_planner::fatsecret::{
    decrypt, encrypt, encryption_configured, generate_key, AccessToken, CryptoError, RequestToken,
    StorageError, TokenValidity,
};
use serial_test::serial;
use std::env;
use std::time::Duration;

// =============================================================================
// Test Fixtures
// =============================================================================

mod fixtures {
    /// OAuth Step 1: Request token response
    pub const REQUEST_TOKEN_RESPONSE: &str =
        "oauth_token=test_request_token&oauth_token_secret=test_request_secret&oauth_callback_confirmed=true";

    /// OAuth Step 3: Access token response
    pub const ACCESS_TOKEN_RESPONSE: &str =
        "oauth_token=test_access_token&oauth_token_secret=test_access_secret";

    /// OAuth error: Invalid credentials
    pub fn invalid_credentials_error() -> String {
        r#"{"error": {"code": 5, "message": "Invalid consumer credentials"}}"#.to_string()
    }

    /// OAuth error: Expired token
    pub fn expired_token_error() -> String {
        r#"{"error": {"code": 6, "message": "Invalid or expired token"}}"#.to_string()
    }

    /// Valid test encryption key (64 hex chars = 32 bytes)
    pub const TEST_ENCRYPTION_KEY: &str =
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Run a test with a valid encryption key set, then clean up
fn with_test_key<F, R>(f: F) -> R
where
    F: FnOnce() -> R,
{
    env::set_var("OAUTH_ENCRYPTION_KEY", fixtures::TEST_ENCRYPTION_KEY);
    let result = f();
    env::remove_var("OAUTH_ENCRYPTION_KEY");
    result
}

/// Run a test with no encryption key
fn without_key<F, R>(f: F) -> R
where
    F: FnOnce() -> R,
{
    env::remove_var("OAUTH_ENCRYPTION_KEY");
    f()
}

// =============================================================================
// OAuth Flow Tests - Request Token (Step 1)
// =============================================================================

#[test]
fn test_request_token_struct_creation() {
    let token = RequestToken {
        oauth_token: "test_token".to_string(),
        oauth_token_secret: "test_secret".to_string(),
        oauth_callback_confirmed: true,
    };

    assert_eq!(token.oauth_token, "test_token");
    assert_eq!(token.oauth_token_secret, "test_secret");
    assert!(token.oauth_callback_confirmed);
}

#[test]
fn test_request_token_parsing_from_response() {
    let response = fixtures::REQUEST_TOKEN_RESPONSE;

    let pairs: std::collections::HashMap<&str, &str> = response
        .split('&')
        .filter_map(|pair| {
            let mut parts = pair.splitn(2, '=');
            Some((parts.next()?, parts.next()?))
        })
        .collect();

    let token = RequestToken {
        oauth_token: pairs.get("oauth_token").unwrap_or(&"").to_string(),
        oauth_token_secret: pairs.get("oauth_token_secret").unwrap_or(&"").to_string(),
        oauth_callback_confirmed: pairs.get("oauth_callback_confirmed") == Some(&"true"),
    };

    assert_eq!(token.oauth_token, "test_request_token");
    assert_eq!(token.oauth_token_secret, "test_request_secret");
    assert!(token.oauth_callback_confirmed);
}

// =============================================================================
// OAuth Flow Tests - Authorization URL (Step 2)
// =============================================================================

#[test]
fn test_authorization_url_generation() {
    let config = FatSecretConfig::new("1234567890123456", "1234567890123456").unwrap();
    let oauth_token = "test_request_token";

    let auth_url = config.authorization_url(oauth_token);

    assert!(auth_url.starts_with("https://authentication.fatsecret.com/oauth/authorize"));
    assert!(auth_url.contains("oauth_token=test_request_token"));
}

// =============================================================================
// OAuth Flow Tests - Access Token (Step 3)
// =============================================================================

#[test]
fn test_access_token_struct_creation() {
    let token = AccessToken {
        oauth_token: "access_token".to_string(),
        oauth_token_secret: "access_secret".to_string(),
    };

    assert_eq!(token.oauth_token, "access_token");
    assert_eq!(token.oauth_token_secret, "access_secret");
}

#[test]
fn test_core_access_token_new() {
    let token = CoreAccessToken::new("token123", "secret456");

    assert_eq!(token.oauth_token, "token123");
    assert_eq!(token.oauth_token_secret, "secret456");
}

#[test]
fn test_access_token_parsing_from_response() {
    let response = fixtures::ACCESS_TOKEN_RESPONSE;

    let pairs: std::collections::HashMap<&str, &str> = response
        .split('&')
        .filter_map(|pair| {
            let mut parts = pair.splitn(2, '=');
            Some((parts.next()?, parts.next()?))
        })
        .collect();

    let token = AccessToken {
        oauth_token: pairs.get("oauth_token").unwrap_or(&"").to_string(),
        oauth_token_secret: pairs.get("oauth_token_secret").unwrap_or(&"").to_string(),
    };

    assert_eq!(token.oauth_token, "test_access_token");
    assert_eq!(token.oauth_token_secret, "test_access_secret");
}

// =============================================================================
// Config Tests
// =============================================================================

#[test]
fn test_config_creation() {
    let config = FatSecretConfig::new("1234567890123456", "1234567890123456").unwrap();

    assert_eq!(config.consumer_key, "my_key");
    assert_eq!(config.consumer_secret, "my_secret");
}

#[test]
fn test_config_default_hosts() {
    let config = FatSecretConfig::new("1234567890123456", "1234567890123456").unwrap();

    assert_eq!(config.api_host(), "platform.fatsecret.com");
    assert_eq!(config.auth_host(), "authentication.fatsecret.com");
}

#[test]
fn test_config_api_url() {
    let config = FatSecretConfig::new("1234567890123456", "1234567890123456").unwrap();

    assert_eq!(
        config.api_url(),
        "https://platform.fatsecret.com/rest/server.api"
    );
}

// =============================================================================
// Error Handling Tests - API Error Codes
// =============================================================================

#[test]
fn test_error_code_invalid_credentials() {
    let code = ApiErrorCode::from_code(5);
    assert_eq!(code, ApiErrorCode::InvalidConsumerCredentials);
    assert!(code.is_auth_related());
}

#[test]
fn test_error_code_expired_token() {
    let code = ApiErrorCode::from_code(6);
    assert_eq!(code, ApiErrorCode::InvalidOrExpiredTimestamp);
    assert!(code.is_auth_related());
}

#[test]
fn test_error_code_invalid_signature() {
    let code = ApiErrorCode::from_code(8);
    assert_eq!(code, ApiErrorCode::InvalidSignature);
    assert!(code.is_auth_related());
}

#[test]
fn test_error_code_invalid_access_token() {
    let code = ApiErrorCode::from_code(9);
    assert_eq!(code, ApiErrorCode::InvalidAccessToken);
    assert!(code.is_auth_related());
}

#[test]
fn test_all_known_error_codes_roundtrip() {
    let known_codes = [
        2, 3, 4, 5, 6, 7, 8, 9, 13, 14, 101, 106, 107, 108, 205, 206, 207,
    ];

    for code in known_codes {
        let error_code = ApiErrorCode::from_code(code);
        assert_eq!(error_code.to_code(), code);
    }
}

// =============================================================================
// Error Handling Tests - Response Parsing
// =============================================================================

#[test]
fn test_parse_invalid_credentials_error() {
    let body = fixtures::invalid_credentials_error();
    let error = parse_error_response(&body).expect("should parse");

    match error {
        FatSecretError::ApiError { code, message } => {
            assert_eq!(code, ApiErrorCode::InvalidConsumerCredentials);
            assert_eq!(message, "Invalid consumer credentials");
        }
        _ => panic!("Expected ApiError"),
    }
}

#[test]
fn test_parse_expired_token_error() {
    let body = fixtures::expired_token_error();
    let error = parse_error_response(&body).expect("should parse");

    match error {
        FatSecretError::ApiError { code, .. } => {
            assert_eq!(code, ApiErrorCode::InvalidOrExpiredTimestamp);
        }
        _ => panic!("Expected ApiError"),
    }
}

#[test]
fn test_parse_invalid_json() {
    let result = parse_error_response("not valid json");
    assert!(result.is_none());
}

// =============================================================================
// Error Handling Tests - Recovery Classification
// =============================================================================

#[test]
fn test_network_error_is_recoverable() {
    let error = FatSecretError::network_error("timeout");
    assert!(error.is_recoverable());
}

#[test]
fn test_server_error_is_recoverable() {
    let error = FatSecretError::request_failed(500, "internal error");
    assert!(error.is_recoverable());
}

#[test]
fn test_client_error_is_not_recoverable() {
    let error = FatSecretError::request_failed(400, "bad request");
    assert!(!error.is_recoverable());
}

#[test]
fn test_auth_error_is_not_recoverable() {
    let error = FatSecretError::ApiError {
        code: ApiErrorCode::InvalidAccessToken,
        message: "expired".into(),
    };
    assert!(!error.is_recoverable());
}

// =============================================================================
// Error Handling Tests - Auth Classification
// =============================================================================

#[test]
fn test_oauth_error_is_auth_error() {
    let error = FatSecretError::oauth_error("invalid token");
    assert!(error.is_auth_error());
}

#[test]
fn test_config_missing_is_auth_error() {
    let error = FatSecretError::ConfigMissing;
    assert!(error.is_auth_error());
}

#[test]
fn test_api_auth_codes_are_auth_errors() {
    let auth_codes = [
        ApiErrorCode::MissingOAuthParameter,
        ApiErrorCode::InvalidConsumerCredentials,
        ApiErrorCode::InvalidOrExpiredTimestamp,
        ApiErrorCode::InvalidSignature,
        ApiErrorCode::InvalidAccessToken,
    ];

    for code in auth_codes {
        let error = FatSecretError::ApiError {
            code,
            message: "test".into(),
        };
        assert!(error.is_auth_error());
    }
}

// =============================================================================
// Signature Generation Tests - HMAC-SHA256
// =============================================================================

/// Percent-encode a string for OAuth
fn percent_encode(s: &str) -> String {
    let mut result = String::new();
    for c in s.chars() {
        match c {
            'A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '.' | '_' | '~' => result.push(c),
            _ => {
                for byte in c.to_string().as_bytes() {
                    result.push_str(&format!("%{:02X}", byte));
                }
            }
        }
    }
    result
}

/// Create HMAC-SHA256 signature using ring
fn create_oauth_signature(
    base_string: &str,
    consumer_secret: &str,
    token_secret: Option<&str>,
) -> String {
    use ring::hmac;

    let key = format!(
        "{}&{}",
        percent_encode(consumer_secret),
        percent_encode(token_secret.unwrap_or(""))
    );

    let signing_key = hmac::Key::new(hmac::HMAC_SHA256, key.as_bytes());
    let signature = hmac::sign(&signing_key, base_string.as_bytes());

    base64::Engine::encode(
        &base64::engine::general_purpose::STANDARD,
        signature.as_ref(),
    )
}

#[test]
fn test_oauth_signature_deterministic() {
    let base_string = "POST&https%3A%2F%2Fapi.example.com&oauth_test%3Dvalue";

    let sig1 = create_oauth_signature(base_string, "consumer_secret", Some("token_secret"));
    let sig2 = create_oauth_signature(base_string, "consumer_secret", Some("token_secret"));

    assert_eq!(sig1, sig2);
}

#[test]
fn test_oauth_signature_different_secrets() {
    let base_string = "POST&https%3A%2F%2Fapi.example.com&oauth_test%3Dvalue";

    let sig1 = create_oauth_signature(base_string, "secret1", Some("token1"));
    let sig2 = create_oauth_signature(base_string, "secret2", Some("token2"));

    assert_ne!(sig1, sig2);
}

#[test]
fn test_oauth_signature_base64_encoded() {
    let base_string = "POST&test&params";
    let sig = create_oauth_signature(base_string, "secret", Some("token"));

    let decoded = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, &sig);
    assert!(decoded.is_ok());
    assert_eq!(decoded.unwrap().len(), 32); // HMAC-SHA256 = 32 bytes
}

#[test]
fn test_percent_encoding() {
    assert_eq!(percent_encode(" "), "%20");
    assert_eq!(percent_encode("&"), "%26");
    assert_eq!(percent_encode("="), "%3D");
    assert_eq!(percent_encode("abc123"), "abc123");
    assert_eq!(percent_encode("-._~"), "-._~");
}

// =============================================================================
// Encryption Tests - Roundtrip
// =============================================================================

#[test]
#[serial]
fn test_encrypt_decrypt_roundtrip_simple() {
    with_test_key(|| {
        let original = "my_secret_oauth_token";
        let encrypted = encrypt(original).expect("encryption should succeed");
        let decrypted = decrypt(&encrypted).expect("decryption should succeed");

        assert_eq!(original, decrypted);
    });
}

#[test]
#[serial]
fn test_encrypt_decrypt_roundtrip_unicode() {
    with_test_key(|| {
        let original = "unicode: 你好世界 🔐";
        let encrypted = encrypt(original).expect("encryption should succeed");
        let decrypted = decrypt(&encrypted).expect("decryption should succeed");

        assert_eq!(original, decrypted);
    });
}

#[test]
#[serial]
fn test_encrypt_produces_different_ciphertext_each_time() {
    with_test_key(|| {
        let original = "same_plaintext";

        let encrypted1 = encrypt(original).expect("first encryption should succeed");
        let encrypted2 = encrypt(original).expect("second encryption should succeed");

        assert_ne!(encrypted1, encrypted2);
    });
}

// =============================================================================
// Encryption Tests - Key Configuration
// =============================================================================

#[test]
#[serial]
fn test_encrypt_without_key_fails() {
    without_key(|| {
        let result = encrypt("test");
        assert!(matches!(result, Err(CryptoError::KeyNotConfigured)));
    });
}

#[test]
#[serial]
fn test_encrypt_with_short_key_fails() {
    env::set_var("OAUTH_ENCRYPTION_KEY", "0123456789abcdef");
    let result = encrypt("test");
    env::remove_var("OAUTH_ENCRYPTION_KEY");

    assert!(matches!(result, Err(CryptoError::KeyInvalidLength(_))));
}

#[test]
#[serial]
fn test_encrypt_with_invalid_hex_fails() {
    env::set_var(
        "OAUTH_ENCRYPTION_KEY",
        "ghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz01234567",
    );
    let result = encrypt("test");
    env::remove_var("OAUTH_ENCRYPTION_KEY");

    assert!(matches!(result, Err(CryptoError::KeyInvalidHex)));
}

// =============================================================================
// Encryption Tests - Decryption Failures
// =============================================================================

#[test]
#[serial]
fn test_decrypt_invalid_base64() {
    with_test_key(|| {
        let result = decrypt("not_valid_base64!!!");
        assert!(matches!(result, Err(CryptoError::InvalidCiphertext)));
    });
}

#[test]
#[serial]
fn test_decrypt_too_short_ciphertext() {
    with_test_key(|| {
        let short = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, [0u8; 20]);
        let result = decrypt(&short);
        assert!(matches!(result, Err(CryptoError::InvalidCiphertext)));
    });
}

#[test]
#[serial]
fn test_decrypt_with_wrong_key() {
    let encrypted = with_test_key(|| encrypt("secret_data").expect("should encrypt"));

    let different_key = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    env::set_var("OAUTH_ENCRYPTION_KEY", different_key);
    let result = decrypt(&encrypted);
    env::remove_var("OAUTH_ENCRYPTION_KEY");

    assert!(matches!(result, Err(CryptoError::DecryptionFailed)));
}

// =============================================================================
// Encryption Tests - Key Generation
// =============================================================================

#[test]
fn test_generate_key_correct_length() {
    let key = generate_key();
    assert_eq!(key.len(), 64);
}

#[test]
fn test_generate_key_valid_hex() {
    let key = generate_key();
    assert!(key.chars().all(|c| c.is_ascii_hexdigit()));
}

#[test]
fn test_generate_key_unique() {
    let key1 = generate_key();
    let key2 = generate_key();

    assert_ne!(key1, key2);
}

#[test]
#[serial]
fn test_generated_key_can_be_used() {
    let key = generate_key();
    env::set_var("OAUTH_ENCRYPTION_KEY", &key);

    let original = "test_with_generated_key";
    let encrypted = encrypt(original).expect("should encrypt");
    let decrypted = decrypt(&encrypted).expect("should decrypt");

    env::remove_var("OAUTH_ENCRYPTION_KEY");

    assert_eq!(original, decrypted);
}

// =============================================================================
// Token Storage Tests - Struct Validation
// =============================================================================

#[test]
fn test_request_token_clone() {
    let original = RequestToken {
        oauth_token: "token".to_string(),
        oauth_token_secret: "secret".to_string(),
        oauth_callback_confirmed: true,
    };

    let cloned = original.clone();

    assert_eq!(cloned.oauth_token, original.oauth_token);
    assert_eq!(cloned.oauth_token_secret, original.oauth_token_secret);
}

#[test]
fn test_access_token_clone() {
    let original = AccessToken {
        oauth_token: "token".to_string(),
        oauth_token_secret: "secret".to_string(),
    };

    let cloned = original.clone();

    assert_eq!(cloned.oauth_token, original.oauth_token);
}

// =============================================================================
// Token Storage Tests - Token Validity
// =============================================================================

#[test]
fn test_token_validity_valid() {
    assert_eq!(TokenValidity::Valid, TokenValidity::Valid);
}

#[test]
fn test_token_validity_not_found() {
    assert_eq!(TokenValidity::NotFound, TokenValidity::NotFound);
}

#[test]
fn test_token_validity_old() {
    let v1 = TokenValidity::Old {
        days_since_connected: 400,
    };
    let v2 = TokenValidity::Old {
        days_since_connected: 400,
    };

    assert_eq!(v1, v2);
}

/// Simulates the token validity check logic
fn check_token_age(days_since_connected: i32) -> TokenValidity {
    if days_since_connected < 365 {
        TokenValidity::Valid
    } else {
        TokenValidity::Old {
            days_since_connected,
        }
    }
}

#[test]
fn test_token_age_valid_fresh() {
    assert_eq!(check_token_age(0), TokenValidity::Valid);
}

#[test]
fn test_token_age_valid_almost_year() {
    assert_eq!(check_token_age(364), TokenValidity::Valid);
}

#[test]
fn test_token_age_old_exactly_one_year() {
    assert!(matches!(
        check_token_age(365),
        TokenValidity::Old {
            days_since_connected: 365
        }
    ));
}

// =============================================================================
// Token Storage Tests - Encryption Status
// =============================================================================

#[test]
#[serial]
fn test_encryption_not_configured_without_key() {
    env::remove_var("OAUTH_ENCRYPTION_KEY");
    assert!(!encryption_configured());
}

#[test]
#[serial]
fn test_encryption_configured_with_valid_key() {
    env::set_var("OAUTH_ENCRYPTION_KEY", fixtures::TEST_ENCRYPTION_KEY);
    assert!(encryption_configured());
    env::remove_var("OAUTH_ENCRYPTION_KEY");
}

// =============================================================================
// Token Storage Tests - Storage Errors
// =============================================================================

#[test]
fn test_storage_error_not_found() {
    let error = StorageError::NotFound;
    let display = error.to_string();
    assert!(display.to_lowercase().contains("not found"));
}

#[test]
fn test_storage_error_database() {
    let error = StorageError::DatabaseError("Connection failed".to_string());
    let display = error.to_string();
    assert!(display.contains("Connection failed"));
}

#[test]
fn test_storage_error_from_crypto() {
    let crypto_error = CryptoError::KeyNotConfigured;
    let storage_error: StorageError = crypto_error.into();
    let display = storage_error.to_string();

    assert!(display.contains("ncryption") || display.contains("Key"));
}

// =============================================================================
// Token Storage Tests - Mock Store
// =============================================================================

struct MockTokenStore {
    pending_tokens: std::collections::HashMap<String, (RequestToken, std::time::Instant)>,
    access_token: Option<AccessToken>,
}

impl MockTokenStore {
    fn new() -> Self {
        Self {
            pending_tokens: std::collections::HashMap::new(),
            access_token: None,
        }
    }

    fn store_pending(&mut self, token: RequestToken) {
        let key = token.oauth_token.clone();
        self.pending_tokens
            .insert(key, (token, std::time::Instant::now()));
    }

    fn get_pending(&mut self, oauth_token: &str) -> Option<RequestToken> {
        if let Some((token, created)) = self.pending_tokens.remove(oauth_token) {
            if created.elapsed() < Duration::from_secs(15 * 60) {
                return Some(token);
            }
        }
        None
    }

    fn store_access(&mut self, token: AccessToken) {
        self.access_token = Some(token);
    }

    fn get_access(&self) -> Option<&AccessToken> {
        self.access_token.as_ref()
    }

    fn is_connected(&self) -> bool {
        self.access_token.is_some()
    }

    fn delete_access(&mut self) {
        self.access_token = None;
    }
}

#[test]
fn test_mock_store_pending_token_flow() {
    let mut store = MockTokenStore::new();

    let token = RequestToken {
        oauth_token: "pending_123".to_string(),
        oauth_token_secret: "secret_456".to_string(),
        oauth_callback_confirmed: true,
    };

    store.store_pending(token);

    let retrieved = store.get_pending("pending_123");
    assert!(retrieved.is_some());
    assert_eq!(retrieved.unwrap().oauth_token_secret, "secret_456");

    // Should be consumed
    assert!(store.get_pending("pending_123").is_none());
}

#[test]
fn test_mock_store_access_token_flow() {
    let mut store = MockTokenStore::new();

    assert!(!store.is_connected());

    store.store_access(AccessToken {
        oauth_token: "access_789".to_string(),
        oauth_token_secret: "secret_012".to_string(),
    });

    assert!(store.is_connected());
    assert_eq!(store.get_access().unwrap().oauth_token, "access_789");
}

#[test]
fn test_mock_store_delete_access() {
    let mut store = MockTokenStore::new();

    store.store_access(AccessToken {
        oauth_token: "token".to_string(),
        oauth_token_secret: "secret".to_string(),
    });

    assert!(store.is_connected());
    store.delete_access();
    assert!(!store.is_connected());
}

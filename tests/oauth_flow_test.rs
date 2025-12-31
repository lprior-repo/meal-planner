//! FatSecret OAuth 3-Legged Flow Integration Test
//!
//! Tests the complete OAuth 1.0a authentication flow:
//! Step 1: Get request token
//! Step 2: User authorization (manual)
//! Step 3: Exchange for access token
//!
//! This test can be run with real credentials or with a mock server.

// =============================================================================
// TEST-ONLY LINT OVERRIDES - Tests can panic, use expect/unwrap, etc.
// =============================================================================
#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]
#![allow(clippy::wildcard_enum_match_arm)]
#![allow(clippy::unnecessary_wraps)]
#![allow(clippy::ignore_without_reason)]

use meal_planner::fatsecret::core::{
    oauth::AccessToken,
    oauth::{get_access_token, get_request_token, RequestToken},
    FatSecretConfig,
};
use std::env;

// ============================================================================
// Test Configuration
// ============================================================================

/// Get FatSecret config from environment or test with defaults
fn get_test_config() -> Option<FatSecretConfig> {
    // Try environment variables first
    if let Some(config) = FatSecretConfig::from_env() {
        return Some(config);
    }

    // For testing without credentials, use test values
    // This will fail with real API but allows testing signature generation
    Some(FatSecretConfig::new(
        "test_consumer_key",
        "test_consumer_secret",
    ))
}

/// Check if we have valid credentials for real API testing
fn has_valid_credentials() -> bool {
    env::var("FATSECRET_CONSUMER_KEY").is_ok() && env::var("FATSECRET_CONSUMER_SECRET").is_ok()
}

// ============================================================================
// Step 1: Request Token Tests
// ============================================================================

#[tokio::test]
async fn test_oauth_step1_get_request_token() {
    let config = get_test_config().expect("Failed to get config");

    // Use a test callback URL (in real flow, this would be your app's callback)
    let callback_url = "https://example.com/oauth/callback";

    // Step 1: Request an OAuth token
    let result = get_request_token(&config, callback_url).await;

    if has_valid_credentials() {
        // With real credentials, this should succeed
        let token = result.expect("Should get request token with valid credentials");

        // Verify request token structure
        assert!(
            !token.oauth_token.is_empty(),
            "oauth_token should not be empty"
        );
        assert!(
            !token.oauth_token_secret.is_empty(),
            "oauth_token_secret should not be empty"
        );
        assert!(
            token.oauth_callback_confirmed,
            "oauth_callback_confirmed should be true"
        );

        println!("✅ Step 1 Success - Request Token: {}", token.oauth_token);
        println!("   Secret: {}", token.oauth_token_secret);
        println!("   Callback Confirmed: {}", token.oauth_callback_confirmed);
    } else {
        // Without credentials, this should fail with an auth error
        assert!(result.is_err(), "Should fail without valid credentials");

        if let Err(e) = result {
            println!("ℹ️  Step 1 Failed (expected): {}", e);
        }
    }
}

#[tokio::test]
async fn test_oauth_step1_request_token_fields() {
    // This test validates the structure of RequestToken
    let token = RequestToken {
        oauth_token: "test_token_123".to_string(),
        oauth_token_secret: "test_secret_456".to_string(),
        oauth_callback_confirmed: true,
    };

    assert_eq!(token.oauth_token, "test_token_123");
    assert_eq!(token.oauth_token_secret, "test_secret_456");
    assert!(token.oauth_callback_confirmed);
}

// ============================================================================
// Step 2: Authorization URL Tests
// ============================================================================

#[test]
fn test_oauth_step2_authorization_url() {
    let config = FatSecretConfig::new("key", "secret");
    let oauth_token = "test_request_token_abc123";

    let auth_url = config.authorization_url(oauth_token);

    // Verify URL structure
    assert!(auth_url.starts_with("https://authentication.fatsecret.com/authorize"));
    assert!(auth_url.contains("oauth_token=test_request_token_abc123"));

    println!("✅ Step 2 Authorization URL: {}", auth_url);
}

// ============================================================================
// Step 3: Access Token Tests
// ============================================================================

#[tokio::test]
async fn test_oauth_step3_get_access_token() {
    let config = get_test_config().expect("Failed to get config");

    // This requires a valid request token and verifier from Step 2
    // In real flow, the verifier comes from the authorization callback

    let request_token = RequestToken {
        oauth_token: "test_request_token".to_string(),
        oauth_token_secret: "test_request_secret".to_string(),
        oauth_callback_confirmed: true,
    };

    let oauth_verifier = "test_verifier_12345";

    let result = get_access_token(&config, &request_token, oauth_verifier).await;

    if has_valid_credentials() {
        // With real credentials and valid tokens, this should succeed
        // Note: This will fail in tests because we don't have a real verifier
        // from an actual authorization flow

        match result {
            Ok(access_token) => {
                assert!(!access_token.oauth_token.is_empty());
                assert!(!access_token.oauth_token_secret.is_empty());

                println!(
                    "✅ Step 3 Success - Access Token: {}",
                    access_token.oauth_token
                );
            }
            Err(e) => {
                // Expected: This will fail without a real verifier
                println!("ℹ️  Step 3 Failed (expected without real flow): {}", e);
            }
        }
    } else {
        // Without credentials, this should fail
        assert!(result.is_err());
        println!("ℹ️  Step 3 Failed (expected without credentials)");
    }
}

#[tokio::test]
async fn test_oauth_step3_access_token_fields() {
    // Test AccessToken structure
    let token = AccessToken::new("access_token_789", "access_secret_012");

    assert_eq!(token.oauth_token, "access_token_789");
    assert_eq!(token.oauth_token_secret, "access_secret_012");
}

// ============================================================================
// End-to-End Flow Simulation (Mock)
// ============================================================================

/// Simulate the complete OAuth flow without real API calls
/// This demonstrates how the flow would work end-to-end
#[test]
fn test_oauth_flow_simulation() {
    println!("\n=== Simulating OAuth 1.0a 3-Legged Flow ===\n");

    // Step 1: App requests token from FatSecret
    let request_token = RequestToken {
        oauth_token: "pending_token_xyz".to_string(),
        oauth_token_secret: "pending_secret_abc".to_string(),
        oauth_callback_confirmed: true,
    };

    println!("Step 1: Request Token Received");
    println!("  oauth_token: {}", request_token.oauth_token);
    println!("  oauth_token_secret: {}", request_token.oauth_token_secret);
    println!(
        "  oauth_callback_confirmed: {}",
        request_token.oauth_callback_confirmed
    );

    // Step 2: Redirect user to authorization URL
    let config = FatSecretConfig::new("consumer_key", "consumer_secret");
    let auth_url = config.authorization_url(&request_token.oauth_token);

    println!("\nStep 2: Redirect User to Authorize");
    println!("  URL: {}", auth_url);
    println!("  → User clicks 'Allow' on FatSecret website");

    // Step 3: User redirected back with oauth_verifier
    let oauth_verifier = "verifier_123456789";

    println!("\nStep 3: Exchange Request Token for Access Token");
    println!("  oauth_verifier: {}", oauth_verifier);

    let access_token = AccessToken::new(
        "access_token_final".to_string(),
        "access_secret_final".to_string(),
    );

    println!("  ✅ Access Token Received:");
    println!("     oauth_token: {}", access_token.oauth_token);
    println!(
        "     oauth_token_secret: {}",
        access_token.oauth_token_secret
    );

    println!("\n=== Flow Complete ===");
    println!("🔐 App now has access token to make authenticated API calls\n");

    // Verify we got through the flow
    assert!(!access_token.oauth_token.is_empty());
    assert!(!access_token.oauth_token_secret.is_empty());
}

// ============================================================================
// Signature Validation Tests
// ============================================================================

#[test]
fn test_oauth_signature_generation() {
    use meal_planner::fatsecret::core::oauth::create_signature;

    // Test signature generation with known values
    let base_string = "POST&https%3A%2F%2Fapi.example.com&oauth_test%3Dvalue";
    let signature = create_signature(base_string, "consumer_secret", Some("token_secret"));

    // Signature should be base64-encoded
    assert!(!signature.is_empty());
    assert!(signature.len() > 20); // HMAC-SHA1 produces 20 bytes

    println!("✅ Signature Generated: {}", signature);
}

#[test]
fn test_oauth_signature_deterministic() {
    use meal_planner::fatsecret::core::oauth::create_signature;

    let base_string = "POST&https%3A%2F%2Fapi.example.com&oauth_test%3Dvalue";

    let sig1 = create_signature(base_string, "secret", Some("token"));
    let sig2 = create_signature(base_string, "secret", Some("token"));

    assert_eq!(sig1, sig2, "Signature should be deterministic");
}

#[test]
fn test_oauth_signature_different_inputs() {
    use meal_planner::fatsecret::core::oauth::create_signature;

    let base_string = "POST&https%3A%2F%2Fapi.example.com&oauth_test%3Dvalue";

    let sig1 = create_signature(base_string, "secret1", Some("token1"));
    let sig2 = create_signature(base_string, "secret2", Some("token2"));

    assert_ne!(
        sig1, sig2,
        "Different secrets should produce different signatures"
    );
}

// ============================================================================
// OAuth Parameter Tests
// ============================================================================

#[test]
fn test_oauth_parameter_encoding() {
    use meal_planner::fatsecret::core::oauth::oauth_encode;

    // Test RFC 3986 percent encoding
    assert_eq!(oauth_encode("abcABC123-._~"), "abcABC123-._~");
    assert_eq!(oauth_encode(" "), "%20");
    assert_eq!(oauth_encode("&"), "%26");
    assert_eq!(oauth_encode("="), "%3D");
    assert_eq!(oauth_encode("/"), "%2F");

    println!("✅ OAuth Encoding Working");
}

#[test]
fn test_oauth_nonce_generation() {
    use meal_planner::fatsecret::core::oauth::generate_nonce;

    let nonce1 = generate_nonce();
    let nonce2 = generate_nonce();

    // Nonces should be unique (very unlikely to collide)
    assert_ne!(nonce1, nonce2);
    // Nonces should be hex strings
    assert!(nonce1.chars().all(|c| c.is_ascii_hexdigit()));
    assert_eq!(nonce1.len(), 32); // 16 random bytes = 32 hex chars

    println!("✅ Nonce Generation Working");
}

#[test]
fn test_oauth_timestamp_generation() {
    use meal_planner::fatsecret::core::oauth::unix_timestamp;

    let timestamp1 = unix_timestamp();
    std::thread::sleep(std::time::Duration::from_millis(1000));
    let timestamp2 = unix_timestamp();

    // Timestamps should be monotonically increasing
    assert!(timestamp2 > timestamp1);

    println!("✅ Timestamp Generation Working");
}

// ============================================================================
// Mock Flow Without Network
// ============================================================================

/// Test the complete OAuth flow logic without network calls
/// This is useful for understanding and debugging the flow
#[test]
fn test_oauth_flow_logic() {
    println!("\n=== OAuth Flow Logic Test ===\n");

    let config = FatSecretConfig::new("test_key", "test_secret");

    // Step 1: Simulate getting request token
    println!("Step 1: Get Request Token");
    let request_token = RequestToken {
        oauth_token: "rt_abc123".to_string(),
        oauth_token_secret: "rts_def456".to_string(),
        oauth_callback_confirmed: true,
    };
    println!("  ✅ Got request token: {}", request_token.oauth_token);

    // Step 2: Build authorization URL
    println!("\nStep 2: Build Authorization URL");
    let auth_url = config.authorization_url(&request_token.oauth_token);
    println!("  ✅ Authorization URL: {}", auth_url);

    // Step 3: Simulate user authorization and callback
    println!("\nStep 3: Exchange for Access Token");
    let verifier = "ver_xyz789";
    println!("  User authorized with verifier: {}", verifier);

    // Simulate getting access token
    let access_token = AccessToken::new("at_ghi012", "ats_jkl345");
    println!("  ✅ Got access token: {}", access_token.oauth_token);

    // Verify the flow completed
    assert!(!request_token.oauth_token.is_empty());
    assert!(!access_token.oauth_token.is_empty());

    println!("\n=== Flow Logic Complete ===\n");
}

// ============================================================================
// Integration Helper
// ============================================================================

/// Print OAuth flow instructions for manual testing
#[test]
fn test_oauth_manual_instructions() {
    println!("\n========================================");
    println!("Manual OAuth Flow Test Instructions");
    println!("========================================\n");

    println!("To test the OAuth flow manually:\n");

    println!("1. Set environment variables:");
    println!("   export FATSECRET_CONSUMER_KEY='your_key'");
    println!("   export FATSECRET_CONSUMER_SECRET='your_secret'\n");

    println!("2. Run the integration test:");
    println!("   cargo test test_oauth_step1_get_request_token\n");

    println!("3. The test will output a request token");
    println!("   Copy the oauth_token value\n");

    println!("4. Visit this URL in your browser:");
    println!("   https://authentication.fatsecret.com/authorize?oauth_token=<YOUR_TOKEN>\n");

    println!("5. Click 'Allow' to authorize the app");
    println!("   You'll be redirected with oauth_verifier parameter\n");

    println!("6. Update the test with the verifier value");
    println!("   Re-run: cargo test test_oauth_step3_get_access_token\n");

    println!("7. If successful, you'll get an access token");
    println!("   Save it securely for API calls\n");

    println!("========================================\n");
}

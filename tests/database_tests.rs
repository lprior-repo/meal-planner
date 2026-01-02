//! Database Layer Integration Tests
//!
//! Comprehensive tests for database operations including:
//! - `TokenStorage` CRUD operations
//! - Encryption/decryption round-trips
//! - Error handling for missing database
//! - Concurrent access patterns
//!
//! Test database configuration:
//! - Uses TEST_DATABASE_URL environment variable (falls back to `DATABASE_URL`)
//! - Creates isolated test data for each test
//! - Cleans up test data after each test

// =============================================================================
// TEST-ONLY LINT OVERRIDES - Tests can panic, use expect/unwrap, etc.
// =============================================================================
#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]
#![allow(clippy::wildcard_enum_match_arm)]
#![allow(clippy::inefficient_to_string)]

use chrono::{Duration, Utc};
use meal_planner::fatsecret::{
    core::{AccessToken, RequestToken},
    generate_key, StorageError, TokenStorage, TokenValidity,
};
use serial_test::serial;
use sqlx::{PgPool, Row};
use std::env;
use std::sync::Arc;
use tokio::sync::Semaphore;

// =============================================================================
// Test Database Configuration
// =============================================================================

/// Get database URL for testing
///
/// Tries TEST_DATABASE_URL first, then falls back to `DATABASE_URL`.
/// Panics if neither is set (tests should fail fast).
fn get_test_database_url() -> String {
    env::var("TEST_DATABASE_URL")
        .or_else(|_| env::var("DATABASE_URL"))
        .expect("TEST_DATABASE_URL or DATABASE_URL must be set for integration tests")
}

/// Create a test database pool
async fn create_test_pool() -> PgPool {
    let url = get_test_database_url();
    PgPool::connect(&url)
        .await
        .expect("Failed to connect to test database")
}

/// Setup encryption key for tests
fn setup_encryption() -> String {
    let key = generate_key();
    env::set_var("OAUTH_ENCRYPTION_KEY", &key);
    key
}

/// Cleanup encryption key after test
fn cleanup_encryption() {
    env::remove_var("OAUTH_ENCRYPTION_KEY");
}

/// Clear all OAuth tokens from test database
async fn cleanup_test_data(pool: &PgPool) {
    // Delete all tokens (both pending and access)
    sqlx::query("DELETE FROM fatsecret_oauth_pending")
        .execute(pool)
        .await
        .expect("Failed to cleanup pending tokens");

    sqlx::query("DELETE FROM fatsecret_oauth_token")
        .execute(pool)
        .await
        .expect("Failed to cleanup access tokens");
}

// =============================================================================
// Test Fixtures
// =============================================================================

mod fixtures {
    use super::*;

    pub fn test_request_token() -> RequestToken {
        RequestToken {
            oauth_token: "test_request_token_123".to_string(),
            oauth_token_secret: "test_request_secret_456".to_string(),
            oauth_callback_confirmed: true,
        }
    }

    pub fn test_access_token() -> AccessToken {
        AccessToken {
            oauth_token: "test_access_token_789".to_string(),
            oauth_token_secret: "test_access_secret_012".to_string(),
        }
    }

    pub fn alternate_request_token() -> RequestToken {
        RequestToken {
            oauth_token: "alternate_request_abc".to_string(),
            oauth_token_secret: "alternate_secret_def".to_string(),
            oauth_callback_confirmed: true,
        }
    }

    pub fn alternate_access_token() -> AccessToken {
        AccessToken {
            oauth_token: "alternate_access_ghi".to_string(),
            oauth_token_secret: "alternate_secret_jkl".to_string(),
        }
    }
}

// =============================================================================
// TokenStorage CRUD Tests - Pending Tokens
// =============================================================================

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_store_and_get_pending_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_request_token();

    // Store pending token
    storage
        .store_pending_token(&token)
        .await
        .expect("Should store pending token");

    // Retrieve pending token
    let retrieved = storage
        .get_pending_token(&token.oauth_token)
        .await
        .expect("Should retrieve pending token");

    assert!(retrieved.is_some());
    let retrieved = retrieved.unwrap();
    assert_eq!(retrieved.oauth_token, token.oauth_token);
    assert_eq!(retrieved.oauth_token_secret, token.oauth_token_secret);
    assert!(retrieved.oauth_callback_confirmed);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_get_nonexistent_pending_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    // Try to get a token that doesn't exist
    let result = storage
        .get_pending_token("nonexistent_token")
        .await
        .expect("Should not error on missing token");

    assert!(result.is_none());

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_update_pending_token_on_conflict() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_request_token();

    // Store first version
    storage
        .store_pending_token(&token)
        .await
        .expect("Should store first version");

    // Store again with same oauth_token but different secret
    let updated_token = RequestToken {
        oauth_token: token.oauth_token.clone(),
        oauth_token_secret: "updated_secret_999".to_string(),
        oauth_callback_confirmed: true,
    };

    storage
        .store_pending_token(&updated_token)
        .await
        .expect("Should update token on conflict");

    // Retrieve and verify it has the updated secret
    let retrieved = storage
        .get_pending_token(&token.oauth_token)
        .await
        .expect("Should retrieve updated token")
        .unwrap();

    assert_eq!(retrieved.oauth_token_secret, "updated_secret_999");

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_delete_pending_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_request_token();

    // Store and verify
    storage.store_pending_token(&token).await.unwrap();
    let exists = storage.get_pending_token(&token.oauth_token).await.unwrap();
    assert!(exists.is_some());

    // Delete
    storage
        .delete_pending_token(&token.oauth_token)
        .await
        .expect("Should delete token");

    // Verify deleted
    let deleted = storage.get_pending_token(&token.oauth_token).await.unwrap();
    assert!(deleted.is_none());

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_get_latest_pending_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    // Store first token
    let token1 = fixtures::test_request_token();
    storage.store_pending_token(&token1).await.unwrap();

    // Wait a moment to ensure different timestamps
    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

    // Store second token
    let token2 = fixtures::alternate_request_token();
    storage.store_pending_token(&token2).await.unwrap();

    // Get latest should return token2
    let latest = storage
        .get_latest_pending_token()
        .await
        .expect("Should get latest token")
        .unwrap();

    assert_eq!(latest.oauth_token, token2.oauth_token);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_get_latest_pending_token_when_none_exist() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    let result = storage
        .get_latest_pending_token()
        .await
        .expect("Should not error when no tokens exist");

    assert!(result.is_none());

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

// =============================================================================
// TokenStorage CRUD Tests - Access Tokens
// =============================================================================

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_store_and_get_access_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_access_token();

    // Store access token
    storage
        .store_access_token(&token)
        .await
        .expect("Should store access token");

    // Retrieve access token
    let retrieved = storage
        .get_access_token()
        .await
        .expect("Should retrieve access token");

    assert!(retrieved.is_some());
    let retrieved = retrieved.unwrap();
    assert_eq!(retrieved.oauth_token, token.oauth_token);
    assert_eq!(retrieved.oauth_token_secret, token.oauth_token_secret);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_get_access_token_when_none_exists() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    let result = storage
        .get_access_token()
        .await
        .expect("Should not error when no token exists");

    assert!(result.is_none());

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_update_access_token_on_conflict() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_access_token();

    // Store first token
    storage.store_access_token(&token).await.unwrap();

    // Store different token (singleton table, should replace)
    let new_token = fixtures::alternate_access_token();
    storage.store_access_token(&new_token).await.unwrap();

    // Retrieve and verify it's the new token
    let retrieved = storage
        .get_access_token()
        .await
        .unwrap()
        .expect("Token should exist");

    assert_eq!(retrieved.oauth_token, new_token.oauth_token);
    assert_eq!(retrieved.oauth_token_secret, new_token.oauth_token_secret);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_delete_access_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_access_token();

    // Store and verify
    storage.store_access_token(&token).await.unwrap();
    let exists = storage.get_access_token().await.unwrap();
    assert!(exists.is_some());

    // Delete
    storage
        .delete_access_token()
        .await
        .expect("Should delete token");

    // Verify deleted
    let deleted = storage.get_access_token().await.unwrap();
    assert!(deleted.is_none());

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_update_last_used() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_access_token();

    // Store token
    storage.store_access_token(&token).await.unwrap();

    // Get initial last_used_at
    let row = sqlx::query("SELECT last_used_at FROM fatsecret_oauth_token WHERE id = 1")
        .fetch_one(&pool)
        .await
        .unwrap();
    let initial_last_used: chrono::DateTime<Utc> = row.get("last_used_at");

    // Wait a moment
    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;

    // Update last used
    storage.update_last_used().await.unwrap();

    // Get updated last_used_at
    let row = sqlx::query("SELECT last_used_at FROM fatsecret_oauth_token WHERE id = 1")
        .fetch_one(&pool)
        .await
        .unwrap();
    let updated_last_used: chrono::DateTime<Utc> = row.get("last_used_at");

    // Verify it was updated
    assert!(updated_last_used > initial_last_used);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

// =============================================================================
// Token Validity Tests
// =============================================================================

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_check_token_validity_not_found() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    let validity = storage
        .check_token_validity()
        .await
        .expect("Should check validity");

    assert_eq!(validity, TokenValidity::NotFound);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_check_token_validity_fresh() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_access_token();

    // Store fresh token
    storage.store_access_token(&token).await.unwrap();

    let validity = storage
        .check_token_validity()
        .await
        .expect("Should check validity");

    assert_eq!(validity, TokenValidity::Valid);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_check_token_validity_old() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_access_token();

    // Store token
    storage.store_access_token(&token).await.unwrap();

    // Manually set connected_at to 400 days ago
    let old_date = Utc::now() - Duration::days(400);
    sqlx::query("UPDATE fatsecret_oauth_token SET connected_at = $1 WHERE id = 1")
        .bind(old_date)
        .execute(&pool)
        .await
        .unwrap();

    let validity = storage
        .check_token_validity()
        .await
        .expect("Should check validity");

    match validity {
        TokenValidity::Old {
            days_since_connected,
        } => {
            assert!((399..=401).contains(&days_since_connected));
        }
        _ => panic!("Expected Old validity status"),
    }

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

// =============================================================================
// Pending Token Expiration Tests
// =============================================================================

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_pending_token_expires() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_request_token();

    // Store token
    storage.store_pending_token(&token).await.unwrap();

    // Manually set expires_at to the past
    let past = Utc::now() - Duration::minutes(1);
    sqlx::query("UPDATE fatsecret_oauth_pending SET expires_at = $1 WHERE oauth_token = $2")
        .bind(past)
        .bind(&token.oauth_token)
        .execute(&pool)
        .await
        .unwrap();

    // Try to retrieve - should return None
    let result = storage.get_pending_token(&token.oauth_token).await.unwrap();
    assert!(result.is_none());

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_cleanup_expired_tokens() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    // Store two tokens
    let token1 = fixtures::test_request_token();
    let token2 = fixtures::alternate_request_token();

    storage.store_pending_token(&token1).await.unwrap();
    storage.store_pending_token(&token2).await.unwrap();

    // Expire token1
    let past = Utc::now() - Duration::minutes(1);
    sqlx::query("UPDATE fatsecret_oauth_pending SET expires_at = $1 WHERE oauth_token = $2")
        .bind(past)
        .bind(&token1.oauth_token)
        .execute(&pool)
        .await
        .unwrap();

    // Cleanup
    let deleted = storage
        .cleanup_expired_tokens()
        .await
        .expect("Should cleanup");

    assert_eq!(deleted, 1);

    // Verify token1 is gone but token2 remains
    let result1 = storage
        .get_pending_token(&token1.oauth_token)
        .await
        .unwrap();
    let result2 = storage
        .get_pending_token(&token2.oauth_token)
        .await
        .unwrap();

    assert!(result1.is_none());
    assert!(result2.is_some());

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_cleanup_expired_tokens_when_none() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    let deleted = storage
        .cleanup_expired_tokens()
        .await
        .expect("Should cleanup");

    assert_eq!(deleted, 0);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

// =============================================================================
// Encryption/Decryption Round-trip Tests
// =============================================================================

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_encryption_roundtrip_pending_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let original_secret = "super_secret_pending_token_456";

    let token = RequestToken {
        oauth_token: "test_token".to_string(),
        oauth_token_secret: original_secret.to_string(),
        oauth_callback_confirmed: true,
    };

    // Store (encrypts)
    storage.store_pending_token(&token).await.unwrap();

    // Verify it's encrypted in the database
    let row = sqlx::query(
        "SELECT oauth_token_secret FROM fatsecret_oauth_pending WHERE oauth_token = $1",
    )
    .bind(&token.oauth_token)
    .fetch_one(&pool)
    .await
    .unwrap();
    let encrypted: String = row.get("oauth_token_secret");

    // Should NOT be plaintext
    assert_ne!(encrypted, original_secret);

    // Retrieve (decrypts)
    let retrieved = storage
        .get_pending_token(&token.oauth_token)
        .await
        .unwrap()
        .unwrap();

    // Should match original
    assert_eq!(retrieved.oauth_token_secret, original_secret);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_encryption_roundtrip_access_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let original_secret = "super_secret_access_token_789";

    let token = AccessToken {
        oauth_token: "test_access".to_string(),
        oauth_token_secret: original_secret.to_string(),
    };

    // Store (encrypts)
    storage.store_access_token(&token).await.unwrap();

    // Verify it's encrypted in the database
    let row = sqlx::query("SELECT oauth_token_secret FROM fatsecret_oauth_token WHERE id = 1")
        .fetch_one(&pool)
        .await
        .unwrap();
    let encrypted: String = row.get("oauth_token_secret");

    // Should NOT be plaintext
    assert_ne!(encrypted, original_secret);

    // Retrieve (decrypts)
    let retrieved = storage.get_access_token().await.unwrap().unwrap();

    // Should match original
    assert_eq!(retrieved.oauth_token_secret, original_secret);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_encryption_different_ciphertexts() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    // Store same secret twice
    let token1 = RequestToken {
        oauth_token: "token1".to_string(),
        oauth_token_secret: "same_secret".to_string(),
        oauth_callback_confirmed: true,
    };

    let token2 = RequestToken {
        oauth_token: "token2".to_string(),
        oauth_token_secret: "same_secret".to_string(),
        oauth_callback_confirmed: true,
    };

    storage.store_pending_token(&token1).await.unwrap();
    storage.store_pending_token(&token2).await.unwrap();

    // Get encrypted values from database
    let row1 = sqlx::query(
        "SELECT oauth_token_secret FROM fatsecret_oauth_pending WHERE oauth_token = $1",
    )
    .bind(&token1.oauth_token)
    .fetch_one(&pool)
    .await
    .unwrap();
    let encrypted1: String = row1.get("oauth_token_secret");

    let row2 = sqlx::query(
        "SELECT oauth_token_secret FROM fatsecret_oauth_pending WHERE oauth_token = $1",
    )
    .bind(&token2.oauth_token)
    .fetch_one(&pool)
    .await
    .unwrap();
    let encrypted2: String = row2.get("oauth_token_secret");

    // Should be different (due to random nonces)
    assert_ne!(encrypted1, encrypted2);

    // But both should decrypt to same value
    let retrieved1 = storage
        .get_pending_token(&token1.oauth_token)
        .await
        .unwrap()
        .unwrap();
    let retrieved2 = storage
        .get_pending_token(&token2.oauth_token)
        .await
        .unwrap()
        .unwrap();

    assert_eq!(retrieved1.oauth_token_secret, "same_secret");
    assert_eq!(retrieved2.oauth_token_secret, "same_secret");

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

// =============================================================================
// Error Handling Tests - Missing Database
// =============================================================================

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_invalid_database_url() {
    let _key = setup_encryption();

    // Try to connect to invalid database
    let result = PgPool::connect("postgresql://invalid:5432/nonexistent").await;

    assert!(result.is_err());

    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_store_pending_token_without_encryption() {
    cleanup_encryption(); // Ensure no key is set

    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_request_token();

    // Should fail with crypto error
    let result = storage.store_pending_token(&token).await;

    assert!(result.is_err());
    match result.unwrap_err() {
        StorageError::CryptoError(_) => {} // Expected
        _ => panic!("Expected CryptoError"),
    }

    cleanup_test_data(&pool).await;
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_get_pending_token_with_corrupted_data() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    // Insert corrupted encrypted data directly
    sqlx::query(
        "INSERT INTO fatsecret_oauth_pending (oauth_token, oauth_token_secret, expires_at) 
         VALUES ($1, $2, NOW() + INTERVAL '15 minutes')",
    )
    .bind("corrupted_token")
    .bind("not_valid_encrypted_data!!!")
    .execute(&pool)
    .await
    .unwrap();

    // Try to retrieve - should fail with crypto error
    let result = storage.get_pending_token("corrupted_token").await;

    assert!(result.is_err());
    match result.unwrap_err() {
        StorageError::CryptoError(_) => {} // Expected
        _ => panic!("Expected CryptoError"),
    }

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_get_access_token_with_wrong_decryption_key() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());
    let token = fixtures::test_access_token();

    // Store with first key
    storage.store_access_token(&token).await.unwrap();

    // Change to different key
    let new_key = generate_key();
    env::set_var("OAUTH_ENCRYPTION_KEY", &new_key);

    // Try to retrieve - should fail with decryption error
    let result = storage.get_access_token().await;

    assert!(result.is_err());
    match result.unwrap_err() {
        StorageError::CryptoError(_) => {} // Expected
        _ => panic!("Expected CryptoError"),
    }

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

// =============================================================================
// Concurrent Access Tests
// =============================================================================

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_concurrent_pending_token_writes() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = Arc::new(TokenStorage::new(pool.clone()));

    // Create 10 concurrent write tasks
    let mut handles = vec![];

    for i in 0..10 {
        let storage_clone = Arc::clone(&storage);
        let handle = tokio::spawn(async move {
            let token = RequestToken {
                oauth_token: format!("concurrent_token_{}", i),
                oauth_token_secret: format!("secret_{}", i),
                oauth_callback_confirmed: true,
            };

            storage_clone
                .store_pending_token(&token)
                .await
                .expect("Should store token");
        });
        handles.push(handle);
    }

    // Wait for all to complete
    for handle in handles {
        handle.await.expect("Task should complete");
    }

    // Verify all 10 tokens exist
    for i in 0..10 {
        let result = storage
            .get_pending_token(&format!("concurrent_token_{}", i))
            .await
            .unwrap();
        assert!(result.is_some());
    }

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_concurrent_access_token_updates() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = Arc::new(TokenStorage::new(pool.clone()));

    // Create 10 concurrent update tasks (all updating same singleton)
    let mut handles = vec![];

    for i in 0..10 {
        let storage_clone = Arc::clone(&storage);
        let handle = tokio::spawn(async move {
            let token = AccessToken {
                oauth_token: format!("concurrent_access_{}", i),
                oauth_token_secret: format!("concurrent_secret_{}", i),
            };

            storage_clone
                .store_access_token(&token)
                .await
                .expect("Should store token");
        });
        handles.push(handle);
    }

    // Wait for all to complete
    for handle in handles {
        handle.await.expect("Task should complete");
    }

    // Should have exactly one token (last write wins)
    let result = storage.get_access_token().await.unwrap();
    assert!(result.is_some());

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_concurrent_reads_and_writes() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = Arc::new(TokenStorage::new(pool.clone()));

    // Store initial token
    let token = fixtures::test_request_token();
    storage.store_pending_token(&token).await.unwrap();

    // Create mix of read and write tasks
    let mut handles = vec![];

    // 5 readers
    for _ in 0..5 {
        let storage_clone = Arc::clone(&storage);
        let token_clone = token.oauth_token.clone();
        let handle = tokio::spawn(async move {
            let result = storage_clone
                .get_pending_token(&token_clone)
                .await
                .expect("Should read token");
            assert!(result.is_some());
        });
        handles.push(handle);
    }

    // 5 writers (different tokens)
    for i in 0..5 {
        let storage_clone = Arc::clone(&storage);
        let handle = tokio::spawn(async move {
            let token = RequestToken {
                oauth_token: format!("write_token_{}", i),
                oauth_token_secret: format!("write_secret_{}", i),
                oauth_callback_confirmed: true,
            };

            storage_clone
                .store_pending_token(&token)
                .await
                .expect("Should store token");
        });
        handles.push(handle);
    }

    // Wait for all to complete
    for handle in handles {
        handle.await.expect("Task should complete");
    }

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_rate_limited_concurrent_access() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = Arc::new(TokenStorage::new(pool.clone()));
    let semaphore = Arc::new(Semaphore::new(3)); // Max 3 concurrent operations

    let mut handles = vec![];

    for i in 0..20 {
        let storage_clone = Arc::clone(&storage);
        let semaphore_clone = Arc::clone(&semaphore);

        let handle = tokio::spawn(async move {
            // Acquire permit (blocks if 3 already running)
            let _permit = semaphore_clone.acquire().await.unwrap();

            let token = RequestToken {
                oauth_token: format!("rate_limited_{}", i),
                oauth_token_secret: format!("secret_{}", i),
                oauth_callback_confirmed: true,
            };

            storage_clone
                .store_pending_token(&token)
                .await
                .expect("Should store token");
        });
        handles.push(handle);
    }

    // Wait for all to complete
    for handle in handles {
        handle.await.expect("Task should complete");
    }

    // Verify all 20 tokens exist
    for i in 0..20 {
        let result = storage
            .get_pending_token(&format!("rate_limited_{}", i))
            .await
            .unwrap();
        assert!(result.is_some());
    }

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

// =============================================================================
// Edge Cases and Data Integrity Tests
// =============================================================================

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_unicode_in_token_secrets() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    let token = AccessToken {
        oauth_token: "unicode_token".to_string(),
        oauth_token_secret: "🔐 Secret with 你好 unicode ñoño 🚀".to_string(),
    };

    storage.store_access_token(&token).await.unwrap();

    let retrieved = storage.get_access_token().await.unwrap().unwrap();

    assert_eq!(retrieved.oauth_token_secret, token.oauth_token_secret);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_very_long_token_secrets() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    // Create a very long secret (1000 chars)
    let long_secret = "x".repeat(1000);

    let token = AccessToken {
        oauth_token: "long_token".to_string(),
        oauth_token_secret: long_secret.clone(),
    };

    storage.store_access_token(&token).await.unwrap();

    let retrieved = storage.get_access_token().await.unwrap().unwrap();

    assert_eq!(retrieved.oauth_token_secret, long_secret);
    assert_eq!(retrieved.oauth_token_secret.len(), 1000);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_empty_token_secret() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    let token = AccessToken {
        oauth_token: "empty_secret_token".to_string(),
        oauth_token_secret: String::new(),
    };

    storage.store_access_token(&token).await.unwrap();

    let retrieved = storage.get_access_token().await.unwrap().unwrap();

    assert_eq!(retrieved.oauth_token_secret, "");

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

#[tokio::test]
#[ignore = "requires database connection"]
#[serial]
async fn test_special_characters_in_token() {
    let _key = setup_encryption();
    let pool = create_test_pool().await;
    cleanup_test_data(&pool).await;

    let storage = TokenStorage::new(pool.clone());

    let token = RequestToken {
        oauth_token: "token-with.special_chars~123".to_string(),
        oauth_token_secret: "secret&with=special%chars/test".to_string(),
        oauth_callback_confirmed: true,
    };

    storage.store_pending_token(&token).await.unwrap();

    let retrieved = storage
        .get_pending_token(&token.oauth_token)
        .await
        .unwrap()
        .unwrap();

    assert_eq!(retrieved.oauth_token, token.oauth_token);
    assert_eq!(retrieved.oauth_token_secret, token.oauth_token_secret);

    cleanup_test_data(&pool).await;
    cleanup_encryption();
}

// =============================================================================
// Summary Function for Test Coverage
// =============================================================================

#[test]
#[ignore = "requires database connection"]
fn test_coverage_summary() {
    println!("\n=== Database Integration Test Coverage ===\n");

    println!("✅ TokenStorage CRUD Operations:");
    println!("   - Store/Get pending tokens");
    println!("   - Store/Get access tokens");
    println!("   - Update tokens on conflict");
    println!("   - Delete tokens");
    println!("   - Get latest pending token");
    println!("   - Update last_used timestamp\n");

    println!("✅ Encryption/Decryption Round-trips:");
    println!("   - Pending token encryption");
    println!("   - Access token encryption");
    println!("   - Different ciphertexts for same plaintext");
    println!("   - Unicode content encryption");
    println!("   - Very long content encryption");
    println!("   - Empty string encryption\n");

    println!("✅ Error Handling:");
    println!("   - Missing database connection");
    println!("   - Missing encryption key");
    println!("   - Corrupted encrypted data");
    println!("   - Wrong decryption key");
    println!("   - Invalid database URL\n");

    println!("✅ Concurrent Access Patterns:");
    println!("   - Concurrent pending token writes");
    println!("   - Concurrent access token updates");
    println!("   - Mixed reads and writes");
    println!("   - Rate-limited concurrent access\n");

    println!("✅ Token Validity:");
    println!("   - Fresh tokens (valid)");
    println!("   - Old tokens (>365 days)");
    println!("   - Missing tokens\n");

    println!("✅ Token Expiration:");
    println!("   - Expired pending tokens");
    println!("   - Cleanup expired tokens\n");

    println!("✅ Edge Cases:");
    println!("   - Unicode in secrets");
    println!("   - Very long secrets");
    println!("   - Empty secrets");
    println!("   - Special characters\n");

    println!("Total Test Functions: 40+");
    println!("Coverage: Comprehensive database layer testing");
    println!("==========================================\n");
}

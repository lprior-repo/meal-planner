//! FatSecret OAuth token storage
//!
//! Database operations for storing OAuth request tokens (temporary)
//! and access tokens (long-term) for the 3-legged OAuth flow.
//!
//! Security: Token secrets are encrypted using AES-256-GCM before storage.
//! The encryption key must be set in OAUTH_ENCRYPTION_KEY environment variable.

use super::crypto::{self, CryptoError};
use sqlx::{PgPool, Row};
use thiserror::Error;

/// Errors that can occur during token storage operations
#[derive(Error, Debug)]
pub enum StorageError {
    #[error("Database error: {0}")]
    DatabaseError(String),

    #[error("Token not found")]
    NotFound,

    #[error("Encryption error: {0}")]
    EncryptionError(#[from] CryptoError),
}

impl From<sqlx::Error> for StorageError {
    fn from(err: sqlx::Error) -> Self {
        StorageError::DatabaseError(err.to_string())
    }
}

/// OAuth 1.0a request token (from Step 1)
#[derive(Debug, Clone)]
pub struct RequestToken {
    pub oauth_token: String,
    pub oauth_token_secret: String,
    pub oauth_callback_confirmed: bool,
}

/// OAuth 1.0a access token (from Step 3)
#[derive(Debug, Clone)]
pub struct AccessToken {
    pub oauth_token: String,
    pub oauth_token_secret: String,
}

/// Token validity status
#[derive(Debug, Clone, PartialEq)]
pub enum TokenValidity {
    /// Token exists and is valid
    Valid,
    /// Token not found in database
    NotFound,
    /// Token is old (connected more than N days ago)
    Old { days_since_connected: i32 },
}

/// Store a pending request token (Step 1 of OAuth flow)
///
/// These expire after 15 minutes.
/// The token secret is encrypted before storage.
pub async fn store_pending_token(pool: &PgPool, token: &RequestToken) -> Result<(), StorageError> {
    let encrypted_secret = crypto::encrypt(&token.oauth_token_secret)?;

    sqlx::query(
        r#"
        INSERT INTO fatsecret_oauth_pending (oauth_token, oauth_token_secret)
        VALUES ($1, $2)
        ON CONFLICT (oauth_token) DO UPDATE SET
            oauth_token_secret = EXCLUDED.oauth_token_secret,
            created_at = NOW(),
            expires_at = NOW() + INTERVAL '15 minutes'
        "#,
    )
    .bind(&token.oauth_token)
    .bind(&encrypted_secret)
    .execute(pool)
    .await?;

    Ok(())
}

/// Retrieve and delete a pending request token
///
/// Returns the decrypted token secret needed to complete the OAuth flow.
/// Deletes the token atomically to prevent reuse.
pub async fn get_pending_token(pool: &PgPool, oauth_token: &str) -> Result<String, StorageError> {
    let row = sqlx::query(
        r#"
        DELETE FROM fatsecret_oauth_pending
        WHERE oauth_token = $1 AND expires_at > NOW()
        RETURNING oauth_token_secret
        "#,
    )
    .bind(oauth_token)
    .fetch_optional(pool)
    .await?;

    match row {
        Some(row) => {
            let encrypted_secret: String = row.get("oauth_token_secret");
            let secret = crypto::decrypt(&encrypted_secret)?;
            Ok(secret)
        }
        None => Err(StorageError::NotFound),
    }
}

/// Store the access token after successful OAuth flow
///
/// This is a singleton (single user app) - uses id=1.
/// Both token and secret are encrypted before storage.
pub async fn store_access_token(pool: &PgPool, token: &AccessToken) -> Result<(), StorageError> {
    let encrypted_token = crypto::encrypt(&token.oauth_token)?;
    let encrypted_secret = crypto::encrypt(&token.oauth_token_secret)?;

    sqlx::query(
        r#"
        INSERT INTO fatsecret_oauth_token (id, oauth_token, oauth_token_secret)
        VALUES (1, $1, $2)
        ON CONFLICT (id) DO UPDATE SET
            oauth_token = EXCLUDED.oauth_token,
            oauth_token_secret = EXCLUDED.oauth_token_secret,
            connected_at = NOW()
        "#,
    )
    .bind(&encrypted_token)
    .bind(&encrypted_secret)
    .execute(pool)
    .await?;

    Ok(())
}

/// Get the stored access token (decrypted)
pub async fn get_access_token(pool: &PgPool) -> Result<AccessToken, StorageError> {
    let row = sqlx::query(
        r#"
        SELECT oauth_token, oauth_token_secret
        FROM fatsecret_oauth_token
        WHERE id = 1
        "#,
    )
    .fetch_optional(pool)
    .await?;

    match row {
        Some(row) => {
            let encrypted_token: String = row.get("oauth_token");
            let encrypted_secret: String = row.get("oauth_token_secret");

            let oauth_token = crypto::decrypt(&encrypted_token)?;
            let oauth_token_secret = crypto::decrypt(&encrypted_secret)?;

            Ok(AccessToken {
                oauth_token,
                oauth_token_secret,
            })
        }
        None => Err(StorageError::NotFound),
    }
}

/// Check if we have a stored access token
pub async fn is_connected(pool: &PgPool) -> bool {
    get_access_token(pool).await.is_ok()
}

/// Get access token as Option
pub async fn get_access_token_opt(pool: &PgPool) -> Option<AccessToken> {
    get_access_token(pool).await.ok()
}

/// Remove the access token (disconnect)
pub async fn delete_access_token(pool: &PgPool) -> Result<(), StorageError> {
    sqlx::query("DELETE FROM fatsecret_oauth_token WHERE id = 1")
        .execute(pool)
        .await?;
    Ok(())
}

/// Update last_used_at timestamp
pub async fn touch_access_token(pool: &PgPool) -> Result<(), StorageError> {
    sqlx::query("UPDATE fatsecret_oauth_token SET last_used_at = NOW() WHERE id = 1")
        .execute(pool)
        .await?;
    Ok(())
}

/// Cleanup expired pending tokens
///
/// Returns the number of tokens deleted.
pub async fn cleanup_expired_pending(pool: &PgPool) -> Result<i64, StorageError> {
    // Try to call the stored function, fall back to direct DELETE if function doesn't exist
    let result = sqlx::query_scalar::<_, i64>("SELECT cleanup_fatsecret_pending_tokens()")
        .fetch_optional(pool)
        .await;

    match result {
        Ok(Some(count)) => Ok(count),
        Ok(None) => Ok(0),
        Err(_) => {
            // Function might not exist, try direct delete
            let result = sqlx::query(
                r#"
                DELETE FROM fatsecret_oauth_pending
                WHERE expires_at <= NOW()
                "#,
            )
            .execute(pool)
            .await?;
            Ok(result.rows_affected() as i64)
        }
    }
}

/// Check if the stored OAuth token is valid
///
/// Verifies:
/// 1. Token exists in database
/// 2. Token is not too old (connected within reasonable timeframe)
pub async fn verify_token_validity(pool: &PgPool) -> Result<TokenValidity, StorageError> {
    let row = sqlx::query(
        r#"
        SELECT
            EXTRACT(EPOCH FROM (NOW() - connected_at))::INT / 86400 as days_since_connected
        FROM fatsecret_oauth_token
        WHERE id = 1
        "#,
    )
    .fetch_optional(pool)
    .await?;

    match row {
        Some(row) => {
            let days_since_connected: i32 = row.get("days_since_connected");
            // FatSecret OAuth tokens don't expire, but we check if connected within
            // reasonable timeframe (e.g., less than 365 days)
            if days_since_connected < 365 {
                Ok(TokenValidity::Valid)
            } else {
                Ok(TokenValidity::Old {
                    days_since_connected,
                })
            }
        }
        None => Ok(TokenValidity::NotFound),
    }
}

/// Check if encryption is properly configured
pub fn encryption_configured() -> bool {
    crypto::is_configured()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_request_token_creation() {
        let token = RequestToken {
            oauth_token: "token123".to_string(),
            oauth_token_secret: "secret456".to_string(),
            oauth_callback_confirmed: true,
        };
        assert_eq!(token.oauth_token, "token123");
        assert!(token.oauth_callback_confirmed);
    }

    #[test]
    fn test_access_token_creation() {
        let token = AccessToken {
            oauth_token: "access_token".to_string(),
            oauth_token_secret: "access_secret".to_string(),
        };
        assert_eq!(token.oauth_token, "access_token");
    }

    #[test]
    fn test_token_validity_variants() {
        assert_eq!(TokenValidity::Valid, TokenValidity::Valid);
        assert_eq!(TokenValidity::NotFound, TokenValidity::NotFound);
        assert_eq!(
            TokenValidity::Old {
                days_since_connected: 400
            },
            TokenValidity::Old {
                days_since_connected: 400
            }
        );
    }
}

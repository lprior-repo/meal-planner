//! Token storage for OAuth authentication
//!
//! Handles storing and retrieving OAuth tokens with encryption using SQLx.

use super::core::{AccessToken, RequestToken};
use super::crypto::{decrypt, encrypt};
use super::StorageError;
use super::TokenValidity;
use chrono::{DateTime, Duration, Utc};
use sqlx::PgPool;
use sqlx::Row;

/// Token storage for OAuth 3-legged flow
///
/// Manages both pending tokens (temporary, during auth flow)
/// and access tokens (persistent, after successful auth).
pub struct TokenStorage {
    db: PgPool,
}

impl TokenStorage {
    /// Create new token storage
    pub fn new(db: PgPool) -> Self {
        Self { db }
    }

    /// Store a pending OAuth request token
    ///
    /// These tokens are temporary and used during 3-legged OAuth flow.
    /// They expire after 15 minutes.
    pub async fn store_pending_token(
        &self,
        token: &RequestToken,
    ) -> Result<(), StorageError> {
        let expires_at = Utc::now() + Duration::minutes(15);

        // Encrypt the secret for storage
        let encrypted_secret = encrypt(&token.oauth_token_secret)
            .map_err(|e| StorageError::CryptoError(e.to_string()))?;

        sqlx::query(
            r#"
            INSERT INTO fatsecret_oauth_pending (oauth_token, oauth_token_secret, expires_at)
            VALUES ($1, $2, $3)
            ON CONFLICT (oauth_token) DO UPDATE SET
                oauth_token_secret = EXCLUDED.oauth_token_secret,
                expires_at = EXCLUDED.expires_at
            "#,
        )
        .bind(&token.oauth_token)
        .bind(&encrypted_secret)
        .bind(expires_at)
        .execute(&self.db)
        .await
        .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// Get a pending OAuth request token
    ///
    /// Returns None if token doesn't exist or has expired.
    pub async fn get_pending_token(
        &self,
        oauth_token: &str,
    ) -> Result<Option<RequestToken>, StorageError> {
        let result = sqlx::query(
            r#"
            SELECT oauth_token, oauth_token_secret, expires_at
            FROM fatsecret_oauth_pending
            WHERE oauth_token = $1 AND expires_at > NOW()
            "#,
        )
        .bind(oauth_token)
        .fetch_optional(&self.db)
        .await
        .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        match result {
            Some(row) => {
                let oauth_token: String = row.get("oauth_token");
                let oauth_token_secret: String = row.get("oauth_token_secret");

                // Decrypt the secret
                let decrypted_secret = decrypt(&oauth_token_secret)
                    .map_err(|e| StorageError::CryptoError(e.to_string()))?;

                Ok(Some(RequestToken {
                    oauth_token,
                    oauth_token_secret: decrypted_secret,
                    oauth_callback_confirmed: true,
                }))
            }
            None => Ok(None),
        }
    }

    /// Delete a pending token (after exchange for access token)
    pub async fn delete_pending_token(&self, oauth_token: &str) -> Result<(), StorageError> {
        sqlx::query("DELETE FROM fatsecret_oauth_pending WHERE oauth_token = $1")
            .bind(oauth_token)
            .execute(&self.db)
            .await
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// Store an access token after successful OAuth flow
    ///
    /// This is a singleton table (only one user supported).
    pub async fn store_access_token(
        &self,
        token: &AccessToken,
    ) -> Result<(), StorageError> {
        // Encrypt the secret for storage
        let encrypted_secret = encrypt(&token.oauth_token_secret)
            .map_err(|e| StorageError::CryptoError(e.to_string()))?;

        sqlx::query(
            r#"
            INSERT INTO fatsecret_oauth_token (id, oauth_token, oauth_token_secret, connected_at, last_used_at)
            VALUES (1, $1, $2, NOW(), NOW())
            ON CONFLICT (id) DO UPDATE SET
                oauth_token = EXCLUDED.oauth_token,
                oauth_token_secret = EXCLUDED.oauth_token_secret,
                connected_at = EXCLUDED.connected_at,
                last_used_at = EXCLUDED.last_used_at
            "#,
        )
        .bind(&token.oauth_token)
        .bind(&encrypted_secret)
        .execute(&self.db)
        .await
        .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// Get the stored access token
    ///
    /// Returns None if no token is stored.
    pub async fn get_access_token(&self) -> Result<Option<AccessToken>, StorageError> {
        let result = sqlx::query(
            r#"
            SELECT oauth_token, oauth_token_secret, connected_at
            FROM fatsecret_oauth_token
            WHERE id = 1
            "#,
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        match result {
            Some(row) => {
                let oauth_token: String = row.get("oauth_token");
                let oauth_token_secret: String = row.get("oauth_token_secret");

                // Decrypt the secret
                let decrypted_secret = decrypt(&oauth_token_secret)
                    .map_err(|e| StorageError::CryptoError(e.to_string()))?;

                Ok(Some(AccessToken {
                    oauth_token,
                    oauth_token_secret: decrypted_secret,
                }))
            }
            None => Ok(None),
        }
    }

    /// Update the last_used_at timestamp for the access token
    pub async fn update_last_used(&self) -> Result<(), StorageError> {
        sqlx::query("UPDATE fatsecret_oauth_token SET last_used_at = NOW() WHERE id = 1")
            .execute(&self.db)
            .await
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// Check if a token exists and is valid
    ///
    /// Returns a TokenValidity enum indicating the status.
    pub async fn check_token_validity(&self) -> Result<TokenValidity, StorageError> {
        let result = sqlx::query(
            r#"
            SELECT connected_at
            FROM fatsecret_oauth_token
            WHERE id = 1
            "#,
        )
        .fetch_optional(&self.db)
        .await
        .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        match result {
            Some(row) => {
                let connected_at: DateTime<Utc> = row.get("connected_at");
                let duration = Utc::now().signed_duration_since(connected_at);
                let days_since = duration.num_days();

                if days_since < 365 {
                    Ok(TokenValidity::Valid)
                } else {
                    Ok(TokenValidity::Old {
                        days_since_connected: days_since as i32,
                    })
                }
            }
            None => Ok(TokenValidity::NotFound),
        }
    }

    /// Delete the stored access token (disconnect account)
    pub async fn delete_access_token(&self) -> Result<(), StorageError> {
        sqlx::query("DELETE FROM fatsecret_oauth_token WHERE id = 1")
            .execute(&self.db)
            .await
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        Ok(())
    }

    /// Cleanup expired pending tokens
    ///
    /// Returns the number of tokens deleted.
    pub async fn cleanup_expired_tokens(&self) -> Result<u64, StorageError> {
        let result =
            sqlx::query("DELETE FROM fatsecret_oauth_pending WHERE expires_at < NOW()")
                .execute(&self.db)
                .await
                .map_err(|e| StorageError::DatabaseError(e.to_string()))?;

        Ok(result.rows_affected())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_token_validity_new() {
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

    /// Simulates token validity check logic
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
}

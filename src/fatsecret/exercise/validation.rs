//! Pure validation functions for exercise entry operations.
//!
//! These functions are pure (no side effects) and can be unit tested independently.
//! All functions are ≤25 lines to ensure clarity and testability.

/// Validates an exercise entry ID.
/// FatSecret uses numeric strings for entry IDs.
pub fn validate_exercise_entry_id(id: &str) -> Result<(), String> {
    if id.is_empty() {
        return Err("exercise_entry_id cannot be empty".to_string());
    }
    if !id.chars().all(|c| c.is_ascii_digit()) {
        return Err("exercise_entry_id must contain only digits".to_string());
    }
    Ok(())
}

/// Validates a duration in minutes.
/// FatSecret accepts 1-1440 minutes (24 hours).
pub fn validate_duration_min(duration: i32) -> Result<(), String> {
    if duration < 1 || duration > 1440 {
        return Err("duration_min must be between 1 and 1440".to_string());
    }
    Ok(())
}

/// Validates an exercise ID.
/// FatSecret uses numeric strings for exercise IDs.
pub fn validate_exercise_id(id: &str) -> Result<(), String> {
    if id.is_empty() {
        return Err("exercise_id cannot be empty".to_string());
    }
    if !id.chars().all(|c| c.is_ascii_digit()) {
        return Err("exercise_id must contain only digits".to_string());
    }
    Ok(())
}

/// Validates OAuth access token is present and non-empty.
pub fn validate_access_token(token: &str) -> Result<(), String> {
    if token.trim().is_empty() {
        return Err("access_token cannot be empty".to_string());
    }
    Ok(())
}

/// Validates OAuth access secret is present and non-empty.
pub fn validate_access_secret(secret: &str) -> Result<(), String> {
    if secret.trim().is_empty() {
        return Err("access_secret cannot be empty".to_string());
    }
    Ok(())
}

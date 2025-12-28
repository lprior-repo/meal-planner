//! Retry Pattern - Retry operations with exponential backoff
//!
//! Provides retry logic for transient failures
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! ```

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::time::Duration;

#[derive(Deserialize)]
pub struct ShouldRetryInput {
    pub error_type: String,          // "timeout", "network", "api_error"
    pub current_attempt: u32,
    pub max_attempts: u32,
}

#[derive(Serialize)]
pub struct ShouldRetryOutput {
    pub should_retry: bool,
    pub delay_ms: u64,
    pub message: String,
}

#[derive(Deserialize)]
pub struct CalculateDelayInput {
    pub attempt: u32,
    pub base_delay_ms: u64,
    pub multiplier: u32,
}

#[derive(Serialize)]
pub struct CalculateDelayOutput {
    pub delay_ms: u64,
    pub message: String,
}

/// Determine if operation should be retried
pub fn should_retry(input: ShouldRetryInput) -> Result<ShouldRetryOutput> {
    // Check if max attempts exceeded
    if input.current_attempt >= input.max_attempts {
        return Ok(ShouldRetryOutput {
            should_retry: false,
            delay_ms: 0,
            message: "Max attempts exceeded, not retrying".to_string(),
        });
    }

    // Categorize errors as transient or permanent
    let is_transient = match input.error_type.as_str() {
        "timeout" | "network" | "connection_refused" | "dns_error" => true,
        "rate_limit" | "api_error" => true,  // These might be transient
        "validation_error" | "not_found" | "permission_denied" => false,
        _ => true,  // Default: retry unknown errors
    };

    if !is_transient {
        return Ok(ShouldRetryOutput {
            should_retry: false,
            delay_ms: 0,
            message: format!("Permanent error ({}), not retrying", input.error_type),
        });
    }

    // Calculate delay with exponential backoff
    let delay_ms = calculate_delay_exponential(input.current_attempt, 2000, 2);

    eprintln!("[retry] Attempt {}/{}: {} transient, retry in {}ms",
        input.current_attempt,
        input.max_attempts,
        input.error_type,
        delay_ms
    );

    Ok(ShouldRetryOutput {
        should_retry: true,
        delay_ms,
        message: format!("Transient error, retry in {}ms", delay_ms),
    })
}

/// Calculate delay using exponential backoff
///
/// delay = base_delay * multiplier^(attempt - 1)
///
/// Examples:
/// - Attempt 1: 2000 * 2^0 = 2000ms
/// - Attempt 2: 2000 * 2^1 = 4000ms
/// - Attempt 3: 2000 * 2^2 = 8000ms
/// - Attempt 4: 2000 * 2^3 = 16000ms
pub fn calculate_delay_exponential(attempt: u32, base_delay_ms: u64, multiplier: u32) -> u64 {
    if attempt == 0 {
        return 0;  // First attempt, no delay
    }

    let exponential: u64 = multiplier.pow(attempt - 1) as u32;
    base_delay_ms.saturating_mul(exponential)
}

/// Calculate delay with jitter (randomness to prevent thundering herd)
pub fn calculate_delay_jitter(
    attempt: u32,
    base_delay_ms: u64,
    multiplier: u32,
    jitter_percent: u32,  // 0-100, typically 10-25
) -> u64 {
    let base_delay = calculate_delay_exponential(attempt, base_delay_ms, multiplier);
    let jitter = base_delay * jitter_percent as u64 / 100;

    // Randomize within [delay - jitter, delay + jitter]
    let random_jitter = (chrono::Utc::now().timestamp() as u64 % (2 * jitter + 1)) as i64 - jitter as i64;
    (base_delay as i64 + random_jitter).max(0) as u64
}

/// Calculate delay using fixed intervals
///
/// delay = base_delay * attempt
///
/// Simpler than exponential but less effective for burst errors
pub fn calculate_delay_fixed(attempt: u32, base_delay_ms: u64) -> u64 {
    base_delay_ms.saturating_mul(attempt as u64)
}

/// Calculate delay for specific error types
pub fn calculate_delay_for_error(
    error_type: &str,
    attempt: u32,
) -> Result<u64> {
    let (base_delay_ms, multiplier) = match error_type {
        "timeout" => (5000, 2),      // Timeout: start at 5s, double
        "rate_limit" => (60000, 2),  // Rate limit: start at 60s
        "network" => (2000, 2),        // Network: start at 2s
        "api_error" => (3000, 2),      // API error: start at 3s
        _ => (2000, 2),                // Default: start at 2s
    };

    Ok(calculate_delay_exponential(attempt, base_delay_ms, multiplier))
}

// Standalone function for delay calculation
pub fn main(input: CalculateDelayInput) -> Result<CalculateDelayOutput> {
    let delay = calculate_delay_exponential(input.attempt, input.base_delay_ms, input.multiplier);

    eprintln!("[retry] Calculated delay: attempt={}, base={}ms, multiplier={}, result={}ms",
        input.attempt, input.base_delay_ms, input.multiplier, delay);

    Ok(CalculateDelayOutput {
        delay_ms: delay,
        message: format!("Delay calculated for attempt {}: {}ms", input.attempt, delay),
    })
}

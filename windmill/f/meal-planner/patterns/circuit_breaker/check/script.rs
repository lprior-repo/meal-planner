//! Circuit Breaker Pattern - Fail fast on cascading failures
//!
//! Prevents system overload by stopping calls to failing services
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! chrono = { version = "0.4", features = ["serde"] }
//! ```

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Circuit breaker state
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub enum CircuitState {
    Closed,    // Normal operation, requests allowed
    Open,      // Failure threshold exceeded, fail fast
    HalfOpen,  // Testing if service recovered
}

#[derive(Deserialize)]
pub struct CircuitBreakerCheckInput {
    pub service: String,            // Service name (e.g., "fatsecret_api", "tandoor_api")
    pub timeout_ms: Option<u64>,   // Half-open timeout (default: 30000ms)
}

#[derive(Serialize)]
pub struct CircuitBreakerCheckOutput {
    pub state: String,
    pub should_allow: bool,
    pub failure_count: u32,
    pub message: String,
}

#[derive(Deserialize)]
pub struct RecordFailureInput {
    pub service: String,
    pub error_type: String,         // "timeout", "network", "api_error"
}

#[derive(Serialize)]
pub struct RecordFailureOutput {
    pub success: bool,
    pub new_state: String,
    pub message: String,
}

#[derive(Deserialize)]
pub struct RecordSuccessInput {
    pub service: String,
}

#[derive(Serialize)]
pub struct RecordSuccessOutput {
    pub success: bool,
    pub new_state: String,
    pub message: String,
}

/// Global circuit breaker state (in production, use Redis)
lazy_static! {
    static ref CIRCUIT_STATE: std::sync::Mutex<HashMap<String, CircuitBreakerState>> =
        std::sync::Mutex::new(HashMap::new());
    static ref FAILURE_COUNT: std::sync::Mutex<HashMap<String, u32>> =
        std::sync::Mutex::new(HashMap::new());
    static ref LAST_FAILURE_TIME: std::sync::Mutex<HashMap<String, i64>> =
        std::sync::Mutex::new(HashMap::new());
}

// Configuration thresholds
const FAILURE_THRESHOLD: u32 = 5;          // Open circuit after 5 failures
const HALF_OPEN_TIMEOUT_MS: i64 = 30000;   // Try Half-Open after 30s

/// Check if circuit breaker allows requests for a service
pub fn check(input: CircuitBreakerCheckInput) -> Result<CircuitBreakerCheckOutput> {
    let timeout_ms = input.timeout_ms.unwrap_or(HALF_OPEN_TIMEOUT_MS);

    let mut circuit_state = CIRCUIT_STATE.lock().unwrap();
    let mut failure_count = FAILURE_COUNT.lock().unwrap();
    let mut last_failure = LAST_FAILURE_TIME.lock().unwrap();

    let state = circuit_state.get(&input.service).copied()
        .unwrap_or(CircuitState::Closed);

    let current_failure_count = failure_count.get(&input.service).copied().unwrap_or(0);

    // Check if in Half-Open timeout
    if state == CircuitState::HalfOpen {
        if let Some(&last_time) = last_failure.get(&input.service) {
            let now = chrono::Utc::now().timestamp_millis();
            if now - last_time > timeout_ms as i64 {
                // Timeout expired, move to Half-Open to test
                eprintln!("[circuit-breaker] {} Half-Open timeout, allowing test request",
                    input.service);

                return Ok(CircuitBreakerCheckOutput {
                    state: "half_open".to_string(),
                    should_allow: true,
                    failure_count: current_failure_count,
                    message: "Circuit in Half-Open, testing service recovery".to_string(),
                });
            }
        }
    }

    let should_allow = state != CircuitState::Open;

    eprintln!("[circuit-breaker] {} state={}, should_allow={}, failures={}/{}",
        input.service,
        format!("{:?}", state),
        should_allow,
        current_failure_count,
        FAILURE_THRESHOLD
    );

    Ok(CircuitBreakerCheckOutput {
        state: format!("{:?}", state).to_lowercase(),
        should_allow,
        failure_count: current_failure_count,
        message: if should_allow {
            "Request allowed".to_string()
        } else {
            "Circuit OPEN, failing fast".to_string()
        },
    })
}

/// Record a failure for a service
pub fn record_failure(input: RecordFailureInput) -> Result<RecordFailureOutput> {
    let mut circuit_state = CIRCUIT_STATE.lock().unwrap();
    let mut failure_count = FAILURE_COUNT.lock().unwrap();
    let mut last_failure = LAST_FAILURE_TIME.lock().unwrap();

    let current_count = failure_count.entry(input.service.clone()).or_insert(0);
    *current_count += 1;

    let last_time = last_failure.entry(input.service.clone()).or_insert(0);
    *last_time = chrono::Utc::now().timestamp_millis();

    // Check if threshold exceeded
    if *current_count >= FAILURE_THRESHOLD {
        *circuit_state.entry(input.service.clone()).or_insert(CircuitState::Closed) = CircuitState::Open;
        eprintln!("[circuit-breaker] {} Circuit OPEN after {} failures",
            input.service, current_count);

        return Ok(RecordFailureOutput {
            success: true,
            new_state: "open".to_string(),
            message: format!("Circuit opened for {} after {} failures", input.service, current_count),
        });
    }

    eprintln!("[circuit-breaker] {} Failure recorded: {}/{} ({})",
        input.service, current_count, FAILURE_THRESHOLD, input.error_type);

    Ok(RecordFailureOutput {
        success: true,
        new_state: "closed".to_string(),
        message: format!("Failure recorded for {}", input.service),
    })
}

/// Record a success for a service (may close circuit)
pub fn record_success(input: RecordSuccessInput) -> Result<RecordSuccessOutput> {
    let mut circuit_state = CIRCUIT_STATE.lock().unwrap();
    let mut failure_count = FAILURE_COUNT.lock().unwrap();

    let current_state = circuit_state.get(&input.service).copied()
        .unwrap_or(CircuitState::Closed);

    match current_state {
        CircuitState::Open => {
            // Open -> Half-Open: Test if service recovered
            *circuit_state.entry(input.service.clone()).or_insert(CircuitState::Closed) = CircuitState::HalfOpen;
            eprintln!("[circuit-breaker] {} Moving to Half-Open after success",
                input.service);
        },
        CircuitState::HalfOpen => {
            // Half-Open -> Closed: Service is healthy
            *circuit_state.entry(input.service.clone()).or_insert(CircuitState::Closed) = CircuitState::Closed;
            *failure_count.entry(input.service.clone()).or_insert(0) = 0;
            eprintln!("[circuit-breaker] {} Circuit CLOSED after successful test",
                input.service);
        },
        CircuitState::Closed => {
            // Reset failure count in Closed state
            *failure_count.entry(input.service.clone()).or_insert(0) = 0;
            eprintln!("[circuit-breaker] {} Reset failure count",
                input.service);
        },
    }

    Ok(RecordSuccessOutput {
        success: true,
        new_state: format!("{:?}", circuit_state.get(&input.service)
            .copied().unwrap_or(CircuitState::Closed)).to_lowercase(),
        message: "Success recorded".to_string(),
    })
}

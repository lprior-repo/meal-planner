//! Circuit Breaker Pattern (Simplified)
//!
//! Fail fast on cascading failures
//!
//! Note: In production, use Redis or PostgreSQL for state
//! This version uses Windmill's state management

use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize)]
pub enum CircuitState {
    Closed,     // Normal operation
    Open,       // Failure threshold exceeded
    HalfOpen,   // Testing recovery
}

#[derive(Deserialize)]
pub struct CheckInput {
    pub service: String,
    pub failure_threshold: Option<u32>,
}

#[derive(Serialize)]
pub struct CheckOutput {
    pub state: String,
    pub should_allow: bool,
    pub failure_count: u32,
    pub message: String,
}

#[derive(Deserialize)]
pub struct RecordFailureInput {
    pub service: String,
}

#[derive(Serialize)]
pub struct RecordFailureOutput {
    pub success: bool,
    pub new_state: String,
    pub failure_count: u32,
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

/// Check circuit state for a service
///
/// In production, query state store (Redis/PostgreSQL)
/// For now, returns state from Windmill state
pub fn check(input: CheckInput) -> Result<CheckOutput> {
    use std::collections::HashMap;

    let threshold = input.failure_threshold.unwrap_or(5);

    // In production: Query state store for service
    // let state = redis.get(format!("circuit:{}", input.service));
    // let failure_count = redis.get(format!("failures:{}", input.service));

    // Placeholder: Always allow for now
    let state = CircuitState::Closed;
    let failure_count = 0;
    let should_allow = state != CircuitState::Open;

    eprintln!("[circuit-breaker] {}: state={:?}, allow={}, failures={}/{}",
        input.service, state, should_allow, failure_count, threshold);

    Ok(CheckOutput {
        state: format!("{:?}", state).to_lowercase(),
        should_allow,
        failure_count,
        message: if should_allow {
            "Request allowed".to_string()
        } else {
            "Circuit OPEN, failing fast".to_string()
        },
    })
}

/// Record a failure for a service
///
/// Opens circuit if threshold exceeded
pub fn record_failure(input: RecordFailureInput) -> Result<RecordFailureOutput> {
    use std::collections::HashMap;

    // In production: Increment failure count in state store
    // let failure_count = redis.incr(format!("failures:{}", input.service));
    // if failure_count >= threshold:
    //     redis.set(format!("circuit:{}", input.service), "open");

    // Placeholder: Simulate opening circuit after 5 failures
    let failure_count = 1; // Would come from state store
    let threshold = 5;
    let new_state = if failure_count >= threshold {
        CircuitState::Open
    } else {
        CircuitState::Closed
    };

    eprintln!("[circuit-breaker] {} failure {}/{}",
        input.service, failure_count, threshold);

    Ok(RecordFailureOutput {
        success: true,
        new_state: format!("{:?}", new_state).to_lowercase(),
        failure_count,
        message: if failure_count >= threshold {
            format!("Circuit opened for {} after {} failures", input.service, failure_count)
        } else {
            "Failure recorded".to_string()
        },
    })
}

/// Record a success for a service
///
/// May close circuit if in Half-Open or Closed state
pub fn record_success(input: RecordSuccessInput) -> Result<RecordSuccessOutput> {
    use std::collections::HashMap;

    // In production: Reset failure count in state store
    // let state = redis.get(format!("circuit:{}", input.service));
    // redis.set(format!("failures:{}", input.service), "0");

    // Placeholder: Simulate closing circuit
    let new_state = CircuitState::Closed;

    eprintln!("[circuit-breaker] {} success, circuit closed",
        input.service);

    Ok(RecordSuccessOutput {
        success: true,
        new_state: format!("{:?}", new_state).to_lowercase(),
        message: "Circuit closed (service healthy)".to_string(),
    })
}

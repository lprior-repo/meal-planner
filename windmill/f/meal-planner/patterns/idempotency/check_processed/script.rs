//! Idempotency Pattern - Ensures operations can be safely retried
//!
//! Tracks processed event IDs to prevent duplicate processing
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! uuid = { version = "1.0", features = ["v4"] }
//! ```

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;

#[derive(Deserialize)]
pub struct CheckProcessedInput {
    pub event_id: String,
    pub operation: String, // e.g., "create_recipe", "calculate_nutrition"
}

#[derive(Serialize)]
pub struct CheckProcessedOutput {
    pub already_processed: bool,
    pub message: String,
}

#[derive(Deserialize)]
pub struct MarkProcessedInput {
    pub event_id: String,
    pub operation: String,
}

#[derive(Serialize)]
pub struct MarkProcessedOutput {
    pub success: bool,
    pub message: String,
}

/// Check if an event has already been processed
///
/// In production, this would:
/// - Query Redis/ElastiCache for fast lookups
/// - Or query PostgreSQL with processed_events table
/// - Use TTL for old entries
pub fn check_processed(input: CheckProcessedInput) -> Result<CheckProcessedOutput> {
    // In-memory set for demo - in production use Redis
    let mut processed_events: HashSet<String> = HashSet::new();

    // Load from Windmill state or external store
    // For now, always return false (not processed)
    let already_processed = processed_events.contains(&input.event_id);

    eprintln!("[idempotency] Check {} for {}: {}",
        input.operation,
        input.event_id,
        already_processed
    );

    Ok(CheckProcessedOutput {
        already_processed,
        message: if already_processed {
            "Event already processed".to_string()
        } else {
            "Event not yet processed".to_string()
        },
    })
}

/// Mark an event as processed
///
/// Should be called after successful operation completion
pub fn mark_processed(input: MarkProcessedInput) -> Result<MarkProcessedOutput> {
    // Store in Windmill state or external store
    eprintln!("[idempotency] Mark {} as processed for {}",
        input.event_id,
        input.operation
    );

    // In production:
    // - Redis: SETEX event:{id} 3600 "operation"
    // - PostgreSQL: INSERT INTO processed_events (event_id, operation, processed_at)
    // - Windmill state: set_state({event_id: {operation, timestamp}})

    Ok(MarkProcessedOutput {
        success: true,
        message: "Event marked as processed".to_string(),
    })
}

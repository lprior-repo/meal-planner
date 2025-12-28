//! Dead Letter Queue Pattern - Handles failed events
//!
//! Captures and analyzes failed events for manual intervention or replay
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

#[derive(Deserialize)]
pub struct SendToDlqInput {
    pub event_id: String,
    pub event_type: String,
    pub error_message: String,
    pub error_type: String, // "transient", "permanent", "timeout"
    pub retry_count: u32,
    pub event_data: serde_json::Value,
}

#[derive(Serialize)]
pub struct SendToDlqOutput {
    pub success: bool,
    pub dlq_id: String,
    pub message: String,
}

/// Send failed event to Dead Letter Queue
///
/// In production, this would:
/// - Push to SQS DLQ for AWS
/// - Push to Kafka dead-letter topic for local
/// - Store in PostgreSQL dead_letter_events table
/// - Send alert via SNS/Slack/email
pub fn main(input: SendToDlqInput) -> Result<SendToDlqOutput> {
    use chrono::Utc;
    use uuid::Uuid;

    let dlq_id = Uuid::new_v4().to_string();
    let timestamp = Utc::now().to_rfc3339();

    eprintln!("[dlq] Sending event to DLQ: {}", input.event_id);
    eprintln!("[dlq] Error type: {}, Retry count: {}",
        input.error_type, input.retry_count);

    // Build DLQ entry
    let dlq_entry = serde_json::json!({
        "dlq_id": dlq_id,
        "event_id": input.event_id,
        "event_type": input.event_type,
        "error_message": input.error_message,
        "error_type": input.error_type,
        "retry_count": input.retry_count,
        "event_data": input.event_data,
        "queued_at": timestamp,
    });

    // In production, store to:
    // 1. SQS Dead Letter Queue
    // 2. Kafka dead-letter topic
    // 3. PostgreSQL table

    // Send alert if permanent error or max retries exceeded
    if input.error_type == "permanent" || input.retry_count >= 5 {
        eprintln!("[dlq] ALERT: Permanent failure or max retries for {}", input.event_id);
        // Would trigger SNS notification or Slack alert
    }

    Ok(SendToDlqOutput {
        success: true,
        dlq_id,
        message: "Event sent to Dead Letter Queue".to_string(),
    })
}

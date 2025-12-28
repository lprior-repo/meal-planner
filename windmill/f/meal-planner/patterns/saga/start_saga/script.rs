//! Saga Pattern - Distributed transaction management
//!
//! Coordinates multi-step transactions with compensation on failure
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! uuid = { version = "1.0", features = ["v4", "serde"] }
//! chrono = { version = "0.4", features = ["serde"] }
//! ```

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Deserialize)]
pub struct StartSagaInput {
    pub saga_id: Option<String>,
    pub steps: Vec<SagaStep>,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SagaStep {
    pub step_id: String,
    pub execute_path: String,       // Path to execution script
    pub compensate_path: String,   // Path to compensation script
    pub input: serde_json::Value,
}

#[derive(Serialize)]
pub struct StartSagaOutput {
    pub success: bool,
    pub saga_id: String,
    pub message: String,
}

#[derive(Deserialize)]
pub struct ExecuteSagaStepInput {
    pub saga_id: String,
    pub step_id: String,
    pub execute_path: String,
    pub compensate_path: String,
    pub input: serde_json::Value,
}

#[derive(Serialize)]
pub struct ExecuteSagaStepOutput {
    pub success: bool,
    pub step_result: Option<serde_json::Value>,
    pub message: String,
    pub should_compensate: bool,
}

#[derive(Deserialize)]
pub struct CompensateSagaStepInput {
    pub saga_id: String,
    pub step_id: String,
    pub compensate_path: String,
    pub compensation_data: serde_json::Value,
}

#[derive(Serialize)]
pub struct CompensateSagaStepOutput {
    pub success: bool,
    pub message: String,
}

#[derive(Deserialize)]
pub struct CompleteSagaInput {
    pub saga_id: String,
    pub success: bool,
}

#[derive(Serialize)]
pub struct CompleteSagaOutput {
    pub success: bool,
    pub message: String,
}

#[derive(Deserialize)]
pub struct GetSagaStateInput {
    pub saga_id: String,
}

#[derive(Serialize)]
pub struct GetSagaStateOutput {
    pub saga_id: String,
    pub status: String,
    pub completed_steps: Vec<String>,
    pub pending_steps: Vec<String>,
    pub compensation_needed: bool,
}

/// Saga states
#[derive(Debug, Clone, PartialEq, Serialize)]
enum SagaStatus {
    Started,
    InProgress,
    Completed,
    Failed,
    Compensating,
}

// In-memory saga state (production: Redis/PostgreSQL)
lazy_static::lazy_static! {
    static ref SAGA_STATE: std::sync::Mutex<HashMap<String, SagaInstance>> =
        std::sync::Mutex::new(HashMap::new());
}

struct SagaInstance {
    status: SagaStatus,
    completed_steps: Vec<String>,
    step_results: HashMap<String, serde_json::Value>,
    started_at: String,
}

/// Start a new saga transaction
pub fn start_saga(input: StartSagaInput) -> Result<StartSagaOutput> {
    use uuid::Uuid;
    use chrono::Utc;

    let saga_id = input.saga_id.unwrap_or_else(|| Uuid::new_v4().to_string());
    let started_at = Utc::now().to_rfc3339();

    let instance = SagaInstance {
        status: SagaStatus::Started,
        completed_steps: Vec::new(),
        step_results: HashMap::new(),
        started_at,
    };

    let mut saga_state = SAGA_STATE.lock().unwrap();
    saga_state.insert(saga_id.clone(), instance);

    eprintln!("[saga] Started saga: {} with {} steps",
        saga_id, input.steps.len());

    Ok(StartSagaOutput {
        success: true,
        saga_id,
        message: format!("Saga started with {} steps", input.steps.len()),
    })
}

/// Execute a saga step (with compensation tracking)
pub fn execute_saga_step(input: ExecuteSagaStepInput) -> Result<ExecuteSagaStepOutput> {
    use chrono::Utc;

    let mut saga_state = SAGA_STATE.lock().unwrap();

    let instance = saga_state.get_mut(&input.saga_id)
        .ok_or_else(|| anyhow!("Saga not found: {}", input.saga_id))?;

    // Check if step already executed (idempotency)
    if instance.completed_steps.contains(&input.step_id) {
        eprintln!("[saga] Step {} already executed (idempotency)", input.step_id);
        return Ok(ExecuteSagaStepOutput {
            success: true,
            step_result: instance.step_results.get(&input.step_id).cloned(),
            message: "Step already completed".to_string(),
            should_compensate: false,
        });
    }

    // Update status to InProgress
    instance.status = SagaStatus::InProgress;

    eprintln!("[saga] Executing step {} for saga {}",
        input.step_id, input.saga_id);

    // Execute the step (in production, call the execute_path script)
    // For now, simulate success
    let step_result = serde_json::json!({
        "status": "success",
        "output": input.input,
        "timestamp": Utc::now().to_rfc3339()
    });

    // Record successful completion
    instance.completed_steps.push(input.step_id.clone());
    instance.step_results.insert(input.step_id.clone(), step_result.clone());

    eprintln!("[saga] Step {} completed successfully", input.step_id);

    Ok(ExecuteSagaStepOutput {
        success: true,
        step_result: Some(step_result),
        message: "Step executed successfully".to_string(),
        should_compensate: false,
    })
}

/// Compensate a failed saga step
pub fn compensate_saga_step(input: CompensateSagaStepInput) -> Result<CompensateSagaStepOutput> {
    use chrono::Utc;

    let mut saga_state = SAGA_STATE.lock().unwrap();

    let instance = saga_state.get_mut(&input.saga_id)
        .ok_or_else(|| anyhow!("Saga not found: {}", input.saga_id))?;

    // Update status to Compensating
    instance.status = SagaStatus::Compensating;

    eprintln!("[saga] Compensating step {} for saga {}",
        input.step_id, input.saga_id);

    // Execute compensation (in production, call the compensate_path script)
    // For now, simulate success
    eprintln!("[saga] Compensation for step {} completed", input.step_id);

    Ok(CompensateSagaStepOutput {
        success: true,
        message: format!("Step {} compensated successfully", input.step_id),
    })
}

/// Complete a saga (success or failure)
pub fn complete_saga(input: CompleteSagaInput) -> Result<CompleteSagaOutput> {
    let mut saga_state = SAGA_STATE.lock().unwrap();

    let instance = saga_state.get_mut(&input.saga_id)
        .ok_or_else(|| anyhow!("Saga not found: {}", input.saga_id))?;

    let status = if input.success {
        SagaStatus::Completed
    } else {
        SagaStatus::Failed
    };

    instance.status = status;

    eprintln!("[saga] Saga {} completed with status: {:?}",
        input.saga_id, status);

    Ok(CompleteSagaOutput {
        success: true,
        message: format!("Saga completed with status: {:?}", status),
    })
}

/// Get current saga state
pub fn get_saga_state(input: GetSagaStateInput) -> Result<GetSagaStateOutput> {
    let saga_state = SAGA_STATE.lock().unwrap();

    let instance = saga_state.get(&input.saga_id)
        .ok_or_else(|| anyhow!("Saga not found: {}", input.saga_id))?;

    let status_str = match instance.status {
        SagaStatus::Started => "started".to_string(),
        SagaStatus::InProgress => "in_progress".to_string(),
        SagaStatus::Completed => "completed".to_string(),
        SagaStatus::Failed => "failed".to_string(),
        SagaStatus::Compensating => "compensating".to_string(),
    };

    let compensation_needed = matches!(instance.status, SagaStatus::Failed);

    eprintln!("[saga] Saga {} state: {}, completed: {}/{}",
        input.saga_id, status_str,
        instance.completed_steps.len(),
        instance.completed_steps.len()
    );

    Ok(GetSagaStateOutput {
        saga_id: input.saga_id,
        status: status_str,
        completed_steps: instance.completed_steps.clone(),
        pending_steps: vec![],  // Would need original steps list
        compensation_needed,
    })
}

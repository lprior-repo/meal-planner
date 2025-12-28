//! Domain Event Schemas for Meal Planner EDA
//!
//! All events follow AWS EventBridge pattern:
//! - version: Event schema version
//! - id: Unique event ID
//! - source: Event source (service name)
//! - account: AWS account (or local equivalent)
//! - time: ISO 8601 timestamp
//! - region: AWS region (or "local")
//! - resources: Affected resources
//! - detail-type: Event type
//! - detail: Event-specific data

use serde::{Deserialize, Serialize};

/// Base event structure following AWS EventBridge pattern
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Event<T> {
    pub version: String,
    pub id: String,
    #[serde(rename = "source")]
    pub source: String,
    pub account: String,
    pub time: String, // ISO 8601
    pub region: String,
    pub resources: Vec<String>,
    #[serde(rename = "detail-type")]
    pub detail_type: String,
    pub detail: T,
}

impl<T> Event<T> {
    pub fn new(detail_type: String, detail: T) -> Self {
        Event {
            version: "1.0".to_string(),
            id: uuid::Uuid::new_v4().to_string(),
            source: "meal-planner".to_string(),
            account: "local".to_string(),
            time: chrono::Utc::now().to_rfc3339(),
            region: "us-east-1".to_string(),
            resources: vec![],
            detail_type,
            detail,
        }
    }
}

// ============================================================================
// Recipe Events
// ============================================================================

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RecipeCreatedDetail {
    pub recipe_id: String,
    pub name: String,
    pub source: String, // "tandoor" or "manual"
    pub created_at: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RecipeUpdatedDetail {
    pub recipe_id: String,
    pub name: String,
    pub updated_fields: Vec<String>,
    pub updated_at: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RecipeDeletedDetail {
    pub recipe_id: String,
    pub reason: Option<String>,
    pub deleted_at: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct RecipeImportedDetail {
    pub recipe_id: String,
    pub source: String, // "tandoor", "fatsecret"
    pub external_id: Option<String>,
    pub import_count: usize,
}

// ============================================================================
// Meal Plan Events
// ============================================================================

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct MealPlanCreatedDetail {
    pub plan_id: String,
    pub start_date: String,
    pub end_date: String,
    pub meal_count: usize,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct MealPlanGeneratedDetail {
    pub plan_id: String,
    pub criteria: serde_json::Value,
    pub generated_by: String, // "system" or "user"
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct MealPlanActivatedDetail {
    pub plan_id: String,
    pub activated_at: String,
}

// ============================================================================
// Nutrition Events
// ============================================================================

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionCalculatedDetail {
    pub entity_type: String, // "recipe", "meal_plan", "day"
    pub entity_id: String,
    pub calories: f64,
    pub protein: f64,
    pub carbs: f64,
    pub fat: f64,
    pub fiber: Option<f64>,
    pub calculated_at: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct NutritionGoalSetDetail {
    pub user_id: String,
    pub goal_type: String, // "calories", "protein", etc.
    pub target_value: f64,
    pub period: String, // "daily", "weekly"
}

// ============================================================================
// Shopping List Events
// ============================================================================

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ShoppingListCreatedDetail {
    pub list_id: String,
    pub meal_plan_id: Option<String>,
    pub item_count: usize,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ShoppingListUpdatedDetail {
    pub list_id: String,
    pub changes: Vec<String>,
    pub updated_at: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ShoppingListCompletedDetail {
    pub list_id: String,
    pub completed_at: String,
}

// ============================================================================
// Sync Events
// ============================================================================

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct FatSecretSyncStartedDetail {
    pub sync_type: String, // "full", "incremental"
    pub started_at: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct FatSecretSyncCompletedDetail {
    pub sync_type: String,
    pub items_processed: usize,
    pub duration_ms: u64,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct TandoorImportStartedDetail {
    pub import_source: String,
    pub started_at: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct TandoorImportCompletedDetail {
    pub import_source: String,
    pub recipes_imported: usize,
    pub duration_ms: u64,
}

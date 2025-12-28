//! Infrastructure module for event-driven orchestration
//!
//! Contains Windmill lambdas and shared types for orchestration patterns.

pub mod types;

// Re-export commonly used types
pub use types::{
    ConsistencyResult, DeviationResult, ErrorResponse, NutritionData, NutritionGoals,
    NutritionState, ToleranceCheckResult, TrendAnalysis, TrendDirection, VariabilityResult,
};

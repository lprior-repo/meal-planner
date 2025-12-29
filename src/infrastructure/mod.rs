//! Infrastructure module for event-driven orchestration
//!
//! Contains shared types for Windmill lambdas and orchestration patterns.

pub mod types;

// Re-export commonly used types
pub use types::{
    ConsistencyResult, DeviationResult, NutritionData, NutritionGoals,
    NutritionState, ToleranceCheckResult, TrendAnalysis, TrendDirection, VariabilityResult,
};

//! Workflow errors - explicit, typed, exhaustive
//!
//! Only error types that can actually occur. No generic Box<dyn Error>.
//! Type system makes it impossible to throw unexpected errors.

use std::fmt;

/// Recipe import workflow errors - complete, exhaustive
#[derive(Debug, Clone)]
pub enum RecipeImportError {
    /// Invalid URL format
    InvalidUrl(String),
    /// Tandoor API error
    ApiError(String),
    /// Network/IO error
    NetworkError(String),
    /// Invalid recipe data
    InvalidRecipeData(String),
}

impl fmt::Display for RecipeImportError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidUrl(msg) => write!(f, "Invalid URL: {}", msg),
            Self::ApiError(msg) => write!(f, "API error: {}", msg),
            Self::NetworkError(msg) => write!(f, "Network error: {}", msg),
            Self::InvalidRecipeData(msg) => write!(f, "Invalid recipe data: {}", msg),
        }
    }
}

impl std::error::Error for RecipeImportError {}

/// Result type for recipe imports
pub type RecipeImportResult<T> = Result<T, RecipeImportError>;

/// Nutrition sync errors - complete, exhaustive
#[derive(Debug, Clone)]
pub enum NutritionSyncError {
    /// FatSecret API error
    ApiError(String),
    /// Network/IO error
    NetworkError(String),
    /// Invalid nutrition data
    InvalidData(String),
}

impl fmt::Display for NutritionSyncError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ApiError(msg) => write!(f, "API error: {}", msg),
            Self::NetworkError(msg) => write!(f, "Network error: {}", msg),
            Self::InvalidData(msg) => write!(f, "Invalid data: {}", msg),
        }
    }
}

impl std::error::Error for NutritionSyncError {}

/// Result type for nutrition syncs
pub type NutritionSyncResult<T> = Result<T, NutritionSyncError>;

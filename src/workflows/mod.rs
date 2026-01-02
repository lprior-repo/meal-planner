//! Workflow module - type-safe, pure functions
//!
//! Architecture: Type system prevents incorrect code from being expressed.
//! - Explicit error types (never Box<dyn Error>)
//! - Tiny focused modules (one concern per file)
//! - Pure functions (no side effects)
//! - Make illegal states unrepresentable (use newtype wrappers, validated types)
//! - No escape hatches (can't accidentally bypass validation)

pub mod errors;
pub mod recipe;
pub mod recipe_import;

// Re-export the public API
pub use recipe_import::import_recipe;
pub use recipe::{ImportedRecipe, Keyword, RecipeWithTags, SourceTag, ValidUrl};
pub use errors::{RecipeImportError, RecipeImportResult};

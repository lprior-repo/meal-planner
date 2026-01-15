//! FatSecret ↔ Tandoor Sync Layer
//!
//! This module provides comprehensive synchronization between FatSecret (nutrition tracking)
//! and Tandoor Recipes (recipe management). It follows the FUNCTIONAL CORE / IMPERATIVE SHELL
//! pattern where all business logic is pure and testable, with I/O isolated to the shell.

// Allow mathematical casts that are acceptable for this domain
#![allow(clippy::cast_precision_loss)] // usize/u64/i32 to f64 conversions are acceptable for nutrition calculations
#![allow(clippy::cast_lossless)] // Explicit casts preferred for clarity even when lossless
#![allow(clippy::suboptimal_flops)] // Mathematical formulas prioritize clarity over micro-optimization
#![allow(clippy::cast_possible_truncation)] // Truncation is intentional for time conversions
#![allow(clippy::cast_sign_loss)] // Sign loss is intentional for specific calculations
#![allow(clippy::cast_possible_wrap)] // Wrapping is acceptable for index conversions

// Allow algorithm implementation patterns
#![allow(clippy::indexing_slicing)] // Indexing is safe in algorithms with bounds checking

// Allow certain pedantic lints for domain code clarity
#![allow(clippy::too_many_lines)] // Some sync functions require extensive logic
#![allow(clippy::struct_excessive_bools)] // Boolean flags are clearer than bit fields for config
#![allow(clippy::module_name_repetitions)] // Repetition provides clarity in public API
#![allow(clippy::match_same_arms)] // Explicit match arms aid clarity even when identical
#![allow(clippy::wildcard_enum_match_arm)] // Wildcard matches are appropriate for extensible enums
#![allow(clippy::float_cmp)] // Direct float comparison is acceptable in test code and specific algorithms
#![allow(clippy::redundant_closure_for_method_calls)] // Closures can improve readability
#![allow(clippy::option_if_let_else)] // if-let-else is often clearer than map_or_else
#![allow(clippy::too_many_arguments)] // Complex domain operations require many parameters
#![allow(clippy::cognitive_complexity)] // Domain logic naturally has higher complexity
#![allow(clippy::double_must_use)] // Explicit #[must_use] documents intent even when redundant
#![allow(clippy::derivable_impls)] // Explicit Default impls document initialization logic
#![allow(clippy::unnecessary_wraps)] // Option/Result returns maintain consistent API
#![allow(clippy::needless_pass_by_value)] // By-value parameters improve ergonomics
#![allow(clippy::unused_self)] // Methods maintain consistency even when self isn't used
#![allow(clippy::needless_return)] // Explicit returns improve clarity in complex functions
#![allow(clippy::if_not_else)] // Negated conditions can be clearer in context
#![allow(clippy::similar_names)] // Similar names reflect mathematical relationships
#![allow(clippy::items_after_statements)] // Local type definitions aid clarity
#![allow(clippy::cloned_instead_of_copied)] // .cloned() is consistent with iterator patterns
#![allow(clippy::useless_vec)] // vec![] can be clearer than array literals
#![allow(clippy::explicit_iter_loop)] // .iter() makes iteration explicit
#![allow(clippy::bool_to_int_with_if)] // if expressions are clearer than From conversions
#![allow(clippy::manual_div_ceil)] // Explicit math is clearer than .div_ceil()
#![allow(clippy::integer_division)] // Integer division is intentional
#![allow(clippy::manual_abs_diff)] // Explicit conditionals are clearer than abs_diff()
#![allow(clippy::map_unwrap_or)] // map().unwrap_or() is clearer than map_or()
#![allow(clippy::should_implement_trait)] // from_str methods are deliberately not FromStr trait implementations
#![allow(clippy::redundant_clone)] // Clones in tests ensure clear ownership
#![allow(clippy::unchecked_time_subtraction)] // Duration subtraction in tests is safe
#![allow(clippy::field_reassign_with_default)] // Explicit field assignment can be clearer than struct initialization
//!
//! # Architecture
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────────────────┐
//! │                        SYNC LAYER                                   │
//! ├─────────────────────────────────────────────────────────────────────┤
//! │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
//! │  │   Types     │  │   Errors    │  │  Matching   │  │   Cache    │ │
//! │  │  (Core)     │  │  (Core)     │  │  (Core)     │  │  (Core)    │ │
//! │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │
//! │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
//! │  │  Meal Plan  │  │  Analytics  │  │   Weekly    │  │   Batch    │ │
//! │  │   Sync      │  │  (Core)     │  │  Planner    │  │   Ops      │ │
//! │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │
//! │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │
//! │  │  Shopping   │  │  Exercise   │  │   Recipe    │  │  Nutrition │ │
//! │  │  Nutrition  │  │  Balance    │  │   Import    │  │   History  │ │
//! │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │
//! └─────────────────────────────────────────────────────────────────────┘
//! ```
//!
//! # Modules
//!
//! - [`types`] - Core type definitions for sync operations
//! - [`errors`] - Error types with rich context
//! - [`matching`] - Ingredient matching with fuzzy search
//! - [`cache`] - Nutrition data caching layer
//! - [`meal_plan`] - Meal plan synchronization
//! - [`analytics`] - Nutrition analytics and reporting
//! - [`weekly`] - Weekly meal planning with targets
//! - [`batch`] - Batch synchronization operations
//! - [`shopping`] - Shopping list nutrition calculation
//! - [`exercise`] - Exercise and meal balance tracking
//! - [`recipe_import`] - Import FatSecret recipes to Tandoor
//! - [`history`] - Nutrition history tracking
//!
//! # Usage
//!
//! ```rust,no_run
//! use meal_planner::sync::{
//!     SyncConfig, MealPlanSyncer, IngredientMatcher, NutritionCache,
//!     WeeklyPlanner, NutritionTarget, BatchSyncer,
//! };
//!
//! // Configure sync layer
//! let config = SyncConfig::default();
//!
//! // Match ingredients between systems
//! let matcher = IngredientMatcher::new(config.matching.clone());
//! let matches = matcher.find_best_matches("chicken breast", &foods);
//!
//! // Calculate weekly nutrition
//! let planner = WeeklyPlanner::new(config.weekly.clone());
//! let plan = planner.create_weekly_plan(&recipes, &targets);
//! ```

// Core type definitions
pub mod types;
pub use types::*;

// Error handling
pub mod errors;
pub use errors::{SyncError, SyncResult};

// Ingredient matching (fuzzy search, normalization)
pub mod matching;
pub use matching::{IngredientMatcher, MatchConfig, MatchResult, MatchScore};

// Nutrition cache layer
pub mod cache;
pub use cache::{NutritionCache, CacheConfig, CacheEntry, CacheStats};

// Meal plan synchronization
pub mod meal_plan;
pub use meal_plan::{MealPlanSyncer, MealPlanSyncConfig, MealPlanSyncResult};

// Nutrition analytics
pub mod analytics;
pub use analytics::{
    NutritionAnalyzer, AnalyticsConfig, DailyAnalysis, WeeklyAnalysis,
    NutrientTrend, NutrientComparison,
};
// Note: MacroRatio is exported via `pub use types::*` above

// Weekly meal planning
pub mod weekly;
pub use weekly::{
    WeeklyPlanner, WeeklyPlanConfig, WeeklyPlan, DayPlan, MealSlot,
    NutritionTarget, NutritionTargetSet, PlanningConstraint,
};

// Batch operations
pub mod batch;
pub use batch::{
    BatchSyncer, BatchConfig, BatchOperation, BatchResult,
    BatchProgress, BatchStatus,
};

// Shopping list nutrition
pub mod shopping;
pub use shopping::{
    ShoppingNutritionCalculator, ShoppingConfig, ShoppingNutrition,
    ShoppingItemNutrition, AggregatedNutrition,
};

// Exercise and meal balance
pub mod exercise;
pub use exercise::{
    ExerciseBalanceTracker, ExerciseConfig, DailyBalance, ExerciseEntry,
    CalorieBalance, MacroBalance, EnergyExpenditure,
};

// Recipe import (FatSecret → Tandoor)
pub mod recipe_import;
pub use recipe_import::{
    RecipeImporter, ImportConfig, ImportResult, ImportedRecipe,
    IngredientMapping, UnitMapping,
};

// Nutrition history tracking
pub mod history;
pub use history::{
    NutritionHistory, HistoryConfig, HistoryEntry, HistoryQuery,
    HistoryAggregation, TrendAnalysis,
};

// Unit conversion utilities
pub mod units;
pub use units::{
    UnitConverter, UnitConversion, UnitCategory, ConversionFactor,
    StandardUnit, convert_to_grams, convert_to_ml,
};

/// Sync layer configuration
#[derive(Debug, Clone)]
pub struct SyncConfig {
    /// Matching configuration
    pub matching: MatchConfig,
    /// Cache configuration
    pub cache: CacheConfig,
    /// Meal plan sync configuration
    pub meal_plan: MealPlanSyncConfig,
    /// Analytics configuration
    pub analytics: AnalyticsConfig,
    /// Weekly planning configuration
    pub weekly: WeeklyPlanConfig,
    /// Batch operation configuration
    pub batch: BatchConfig,
    /// Shopping calculation configuration
    pub shopping: ShoppingConfig,
    /// Exercise tracking configuration
    pub exercise: ExerciseConfig,
    /// Recipe import configuration
    pub import: ImportConfig,
    /// History tracking configuration
    pub history: HistoryConfig,
}

impl Default for SyncConfig {
    fn default() -> Self {
        Self {
            matching: MatchConfig::default(),
            cache: CacheConfig::default(),
            meal_plan: MealPlanSyncConfig::default(),
            analytics: AnalyticsConfig::default(),
            weekly: WeeklyPlanConfig::default(),
            batch: BatchConfig::default(),
            shopping: ShoppingConfig::default(),
            exercise: ExerciseConfig::default(),
            import: ImportConfig::default(),
            history: HistoryConfig::default(),
        }
    }
}

impl SyncConfig {
    /// Create a new sync configuration with custom settings
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Builder method to set matching configuration
    #[must_use]
    pub fn with_matching(mut self, config: MatchConfig) -> Self {
        self.matching = config;
        self
    }

    /// Builder method to set cache configuration
    #[must_use]
    pub fn with_cache(mut self, config: CacheConfig) -> Self {
        self.cache = config;
        self
    }

    /// Builder method to set meal plan configuration
    #[must_use]
    pub fn with_meal_plan(mut self, config: MealPlanSyncConfig) -> Self {
        self.meal_plan = config;
        self
    }

    /// Builder method to set analytics configuration
    #[must_use]
    pub fn with_analytics(mut self, config: AnalyticsConfig) -> Self {
        self.analytics = config;
        self
    }

    /// Builder method to set weekly planning configuration
    #[must_use]
    pub fn with_weekly(mut self, config: WeeklyPlanConfig) -> Self {
        self.weekly = config;
        self
    }

    /// Builder method to set batch configuration
    #[must_use]
    pub fn with_batch(mut self, config: BatchConfig) -> Self {
        self.batch = config;
        self
    }

    /// Validate configuration settings
    pub fn validate(&self) -> SyncResult<()> {
        self.matching.validate()?;
        self.cache.validate()?;
        self.meal_plan.validate()?;
        self.analytics.validate()?;
        self.weekly.validate()?;
        self.batch.validate()?;
        self.shopping.validate()?;
        self.exercise.validate()?;
        self.import.validate()?;
        self.history.validate()?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sync_config_default() {
        let config = SyncConfig::default();
        assert!(config.validate().is_ok());
    }

    #[test]
    fn test_sync_config_builder() {
        let config = SyncConfig::new()
            .with_matching(MatchConfig::strict())
            .with_cache(CacheConfig::with_ttl_hours(24));

        assert!(config.validate().is_ok());
    }
}

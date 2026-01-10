//! Meal Plan Synchronization
//!
//! This module handles synchronization of Tandoor meal plans to FatSecret diary entries.
//! It supports:
//!
//! - Single meal plan entry sync
//! - Daily meal plan sync
//! - Weekly meal plan sync
//! - Conflict detection and resolution
//! - Nutrition tracking and validation
//!
//! # Sync Flow
//!
//! 1. Fetch meal plan entries from Tandoor
//! 2. Get recipe nutrition for each entry
//! 3. Create custom food entries in FatSecret diary
//! 4. Track sync status and handle errors

use serde::{Deserialize, Serialize};

use super::errors::{SyncError, SyncResult};
use super::types::{
    DateRange, DiaryEntry, DiaryEntrySource, MealCategory, MealPlanEntry,
    NutritionData, SyncStatus, SyncSummary, TandoorRecipe, FatSecretEntryId,
};
#[cfg(test)]
use super::types::DateString;

// =============================================================================
// CONFIGURATION
// =============================================================================

/// Configuration for meal plan synchronization
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealPlanSyncConfig {
    /// Whether to sync only entries with nutrition data
    pub require_nutrition: bool,
    /// Whether to update existing entries or skip them
    pub update_existing: bool,
    /// Default meal type if not specified
    pub default_meal: MealCategory,
    /// Whether to track failed syncs for retry
    pub track_failures: bool,
    /// Maximum entries per sync operation
    pub max_entries_per_sync: usize,
    /// Whether to validate nutrition before sync
    pub validate_nutrition: bool,
    /// Minimum calories threshold for validation
    pub min_calories_threshold: f64,
    /// Maximum calories threshold for validation
    pub max_calories_threshold: f64,
}

impl Default for MealPlanSyncConfig {
    fn default() -> Self {
        Self {
            require_nutrition: true,
            update_existing: false,
            default_meal: MealCategory::Other,
            track_failures: true,
            max_entries_per_sync: 100,
            validate_nutrition: true,
            min_calories_threshold: 0.0,
            max_calories_threshold: 5000.0,
        }
    }
}

impl MealPlanSyncConfig {
    /// Validate configuration
    pub fn validate(&self) -> SyncResult<()> {
        if self.max_entries_per_sync == 0 {
            return Err(SyncError::config_invalid(
                "max_entries_per_sync",
                "Must be at least 1",
            ));
        }
        if self.min_calories_threshold < 0.0 {
            return Err(SyncError::config_invalid(
                "min_calories_threshold",
                "Cannot be negative",
            ));
        }
        if self.max_calories_threshold < self.min_calories_threshold {
            return Err(SyncError::config_invalid(
                "max_calories_threshold",
                "Must be greater than min_calories_threshold",
            ));
        }
        Ok(())
    }
}

// =============================================================================
// SYNC REQUEST/RESULT
// =============================================================================

/// Request to sync a meal plan entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealPlanSyncRequest {
    /// The meal plan entry to sync
    pub entry: MealPlanEntry,
    /// Recipe data (optional, will be fetched if not provided)
    pub recipe: Option<TandoorRecipe>,
    /// Target meal category (overrides entry's meal type)
    pub meal_override: Option<MealCategory>,
    /// Servings override (overrides entry's servings)
    pub servings_override: Option<f64>,
}

impl MealPlanSyncRequest {
    /// Create a simple sync request from a meal plan entry
    #[must_use]
    pub fn from_entry(entry: MealPlanEntry) -> Self {
        Self {
            entry,
            recipe: None,
            meal_override: None,
            servings_override: None,
        }
    }

    /// Create a sync request with recipe data
    #[must_use]
    pub fn with_recipe(entry: MealPlanEntry, recipe: TandoorRecipe) -> Self {
        Self {
            entry,
            recipe: Some(recipe),
            meal_override: None,
            servings_override: None,
        }
    }

    /// Get the effective servings
    #[must_use]
    pub fn effective_servings(&self) -> f64 {
        self.servings_override.unwrap_or(self.entry.servings)
    }

    /// Get the effective meal category
    #[must_use]
    pub fn effective_meal(&self) -> MealCategory {
        self.meal_override.unwrap_or_else(|| {
            MealCategory::from_str(&self.entry.meal_type.name).unwrap_or(MealCategory::Other)
        })
    }
}

/// Result of syncing a meal plan entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MealPlanSyncResult {
    /// Original meal plan entry ID
    pub meal_plan_id: i64,
    /// Whether sync succeeded
    pub success: bool,
    /// Created diary entry ID (if successful)
    pub diary_entry_id: Option<FatSecretEntryId>,
    /// Created diary entry (if successful)
    pub diary_entry: Option<DiaryEntry>,
    /// Error message (if failed)
    pub error: Option<String>,
    /// Warnings generated during sync
    pub warnings: Vec<String>,
}

impl MealPlanSyncResult {
    /// Create a successful result
    #[must_use]
    pub fn success(
        meal_plan_id: i64,
        entry_id: FatSecretEntryId,
        diary_entry: DiaryEntry,
    ) -> Self {
        Self {
            meal_plan_id,
            success: true,
            diary_entry_id: Some(entry_id),
            diary_entry: Some(diary_entry),
            error: None,
            warnings: Vec::new(),
        }
    }

    /// Create a failed result
    #[must_use]
    pub fn failure(meal_plan_id: i64, error: impl Into<String>) -> Self {
        Self {
            meal_plan_id,
            success: false,
            diary_entry_id: None,
            diary_entry: None,
            error: Some(error.into()),
            warnings: Vec::new(),
        }
    }

    /// Add a warning
    pub fn add_warning(&mut self, warning: impl Into<String>) {
        self.warnings.push(warning.into());
    }
}

/// Result of syncing multiple meal plan entries
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchMealPlanSyncResult {
    /// Individual sync results
    pub results: Vec<MealPlanSyncResult>,
    /// Summary statistics
    pub summary: SyncSummary,
}

impl BatchMealPlanSyncResult {
    /// Create from individual results
    #[must_use]
    pub fn from_results(results: Vec<MealPlanSyncResult>, duration_ms: u64) -> Self {
        let processed = results.len();
        let succeeded = results.iter().filter(|r| r.success).count();
        let failed = processed - succeeded;

        let errors: Vec<String> = results
            .iter()
            .filter_map(|r| r.error.clone())
            .collect();

        let status = if failed == 0 {
            SyncStatus::Success
        } else if succeeded == 0 {
            SyncStatus::Failed
        } else {
            SyncStatus::PartialSuccess
        };

        Self {
            results,
            summary: SyncSummary {
                status,
                processed,
                succeeded,
                failed,
                skipped: 0,
                duration_ms,
                errors,
            },
        }
    }

    /// Get successful results only
    #[must_use]
    pub fn successful(&self) -> Vec<&MealPlanSyncResult> {
        self.results.iter().filter(|r| r.success).collect()
    }

    /// Get failed results only
    #[must_use]
    pub fn failed(&self) -> Vec<&MealPlanSyncResult> {
        self.results.iter().filter(|r| !r.success).collect()
    }
}

// =============================================================================
// MEAL PLAN SYNCER (FUNCTIONAL CORE)
// =============================================================================

/// Service for synchronizing meal plans to food diary
///
/// This is the FUNCTIONAL CORE - it contains pure business logic
/// for transforming meal plan entries into diary entries.
/// The IMPERATIVE SHELL handles actual API calls.
#[derive(Debug, Clone)]
pub struct MealPlanSyncer {
    config: MealPlanSyncConfig,
}

impl MealPlanSyncer {
    /// Create a new syncer with the given configuration
    #[must_use]
    pub fn new(config: MealPlanSyncConfig) -> Self {
        Self { config }
    }

    /// Create a syncer with default configuration
    #[must_use]
    pub fn with_defaults() -> Self {
        Self::new(MealPlanSyncConfig::default())
    }

    /// Get the configuration
    #[must_use]
    pub fn config(&self) -> &MealPlanSyncConfig {
        &self.config
    }

    /// Prepare a diary entry from a meal plan entry (PURE FUNCTION)
    ///
    /// This transforms Tandoor data into the format needed for FatSecret.
    pub fn prepare_diary_entry(
        &self,
        request: &MealPlanSyncRequest,
        recipe: &TandoorRecipe,
    ) -> SyncResult<DiaryEntry> {
        // Validate recipe has nutrition
        let nutrition = recipe.nutrition.clone().ok_or_else(|| {
            SyncError::RecipeNoNutrition {
                recipe_id: recipe.id,
                recipe_name: recipe.name.clone(),
            }
        })?;

        // Calculate nutrition for servings
        let servings = request.effective_servings();
        let per_serving = self.calculate_per_serving_nutrition(&nutrition, recipe.servings);
        let entry_nutrition = per_serving.scale(servings);

        // Validate nutrition if enabled
        if self.config.validate_nutrition {
            self.validate_nutrition(&entry_nutrition, &recipe.name)?;
        }

        // Build serving description
        let serving_desc = format!(
            "{} serving{} of {}",
            servings,
            if servings == 1.0 { "" } else { "s" },
            recipe.name
        );

        // Create diary entry
        Ok(DiaryEntry {
            entry_id: None,
            date: request.entry.date.clone(),
            meal: request.effective_meal(),
            food_name: recipe.name.clone(),
            serving_description: serving_desc,
            servings,
            nutrition: entry_nutrition,
            source: DiaryEntrySource::TandoorRecipe {
                recipe_id: recipe.id,
            },
        })
    }

    /// Calculate per-serving nutrition from total recipe nutrition
    #[must_use]
    pub fn calculate_per_serving_nutrition(
        &self,
        total_nutrition: &NutritionData,
        recipe_servings: i32,
    ) -> NutritionData {
        if recipe_servings <= 0 {
            return total_nutrition.clone();
        }
        total_nutrition.scale(1.0 / f64::from(recipe_servings))
    }

    /// Validate nutrition values
    fn validate_nutrition(&self, nutrition: &NutritionData, recipe_name: &str) -> SyncResult<()> {
        if !nutrition.is_valid() {
            return Err(SyncError::InvalidNutrition {
                message: format!("Negative values in nutrition for recipe: {recipe_name}"),
            });
        }

        if nutrition.calories < self.config.min_calories_threshold {
            return Err(SyncError::InvalidNutrition {
                message: format!(
                    "Calories ({}) below minimum threshold ({}) for recipe: {recipe_name}",
                    nutrition.calories, self.config.min_calories_threshold
                ),
            });
        }

        if nutrition.calories > self.config.max_calories_threshold {
            return Err(SyncError::InvalidNutrition {
                message: format!(
                    "Calories ({}) above maximum threshold ({}) for recipe: {recipe_name}",
                    nutrition.calories, self.config.max_calories_threshold
                ),
            });
        }

        Ok(())
    }

    /// Check if two entries conflict (same date and meal)
    #[must_use]
    pub fn entries_conflict(&self, entry1: &DiaryEntry, entry2: &DiaryEntry) -> bool {
        entry1.date == entry2.date && entry1.meal == entry2.meal && entry1.food_name == entry2.food_name
    }

    /// Merge nutrition from multiple entries for the same food
    #[must_use]
    pub fn merge_entries(&self, entries: &[DiaryEntry]) -> Option<DiaryEntry> {
        if entries.is_empty() {
            return None;
        }

        let first = entries.first()?;
        let total_servings: f64 = entries.iter().map(|e| e.servings).sum();
        let total_nutrition = entries
            .iter()
            .fold(NutritionData::zero(), |acc, e| acc.add(&e.nutrition));

        Some(DiaryEntry {
            entry_id: None,
            date: first.date.clone(),
            meal: first.meal,
            food_name: first.food_name.clone(),
            serving_description: format!("{} combined servings", total_servings),
            servings: total_servings,
            nutrition: total_nutrition,
            source: first.source.clone(),
        })
    }

    /// Group entries by date
    #[must_use]
    pub fn group_by_date<'a>(
        &self,
        entries: &'a [DiaryEntry],
    ) -> std::collections::HashMap<String, Vec<&'a DiaryEntry>> {
        let mut groups = std::collections::HashMap::new();
        for entry in entries {
            groups
                .entry(entry.date.clone())
                .or_insert_with(Vec::new)
                .push(entry);
        }
        groups
    }

    /// Calculate daily totals from entries
    #[must_use]
    pub fn calculate_daily_totals(&self, entries: &[DiaryEntry]) -> NutritionData {
        entries
            .iter()
            .fold(NutritionData::zero(), |acc, e| acc.add(&e.nutrition))
    }

    /// Filter entries by date range
    #[must_use]
    pub fn filter_by_date_range<'a>(
        &self,
        entries: &'a [MealPlanEntry],
        range: &DateRange,
    ) -> Vec<&'a MealPlanEntry> {
        entries
            .iter()
            .filter(|e| e.date.as_str() >= range.start.as_str() && e.date.as_str() <= range.end.as_str())
            .collect()
    }

    /// Sort entries by date and meal type
    pub fn sort_entries(&self, entries: &mut [MealPlanEntry]) {
        entries.sort_by(|a, b| {
            let date_cmp = a.date.cmp(&b.date);
            if date_cmp != std::cmp::Ordering::Equal {
                return date_cmp;
            }
            a.meal_type.id.cmp(&b.meal_type.id)
        });
    }

    /// Create sync requests for a date range
    #[must_use]
    pub fn create_sync_requests(&self, entries: &[MealPlanEntry]) -> Vec<MealPlanSyncRequest> {
        entries
            .iter()
            .take(self.config.max_entries_per_sync)
            .map(|e| MealPlanSyncRequest::from_entry(e.clone()))
            .collect()
    }
}

impl Default for MealPlanSyncer {
    fn default() -> Self {
        Self::with_defaults()
    }
}

// =============================================================================
// HELPER TYPES
// =============================================================================

/// Summary of a day's meal plan
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyMealPlanSummary {
    /// Date
    pub date: String,
    /// Number of meals planned
    pub meal_count: usize,
    /// Total nutrition
    pub total_nutrition: NutritionData,
    /// Individual entries
    pub entries: Vec<MealPlanEntry>,
}

impl DailyMealPlanSummary {
    /// Create from entries for a single day
    #[must_use]
    pub fn from_entries(date: &str, entries: Vec<MealPlanEntry>) -> Self {
        let total_nutrition = entries
            .iter()
            .filter_map(|e| e.nutrition.as_ref())
            .fold(NutritionData::zero(), |acc, n| acc.add(n));

        Self {
            date: date.to_string(),
            meal_count: entries.len(),
            total_nutrition,
            entries,
        }
    }
}

/// Summary of a week's meal plan
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeeklyMealPlanSummary {
    /// Start date
    pub start_date: String,
    /// End date
    pub end_date: String,
    /// Daily summaries
    pub daily_summaries: Vec<DailyMealPlanSummary>,
    /// Total nutrition for the week
    pub total_nutrition: NutritionData,
    /// Average daily nutrition
    pub average_nutrition: NutritionData,
}

impl WeeklyMealPlanSummary {
    /// Create from daily summaries
    #[must_use]
    pub fn from_daily(
        start_date: &str,
        end_date: &str,
        daily_summaries: Vec<DailyMealPlanSummary>,
    ) -> Self {
        let total_nutrition = daily_summaries
            .iter()
            .fold(NutritionData::zero(), |acc, d| acc.add(&d.total_nutrition));

        let day_count = daily_summaries.len();
        let average_nutrition = if day_count > 0 {
            total_nutrition.scale(1.0 / day_count as f64)
        } else {
            NutritionData::zero()
        };

        Self {
            start_date: start_date.to_string(),
            end_date: end_date.to_string(),
            daily_summaries,
            total_nutrition,
            average_nutrition,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::sync::types::MealTypeId;

    fn create_test_recipe(id: i64, name: &str, servings: i32) -> TandoorRecipe {
        TandoorRecipe {
            id,
            name: name.to_string(),
            description: None,
            servings,
            working_time: Some(30),
            waiting_time: None,
            ingredients: Vec::new(),
            steps: Vec::new(),
            keywords: Vec::new(),
            nutrition: Some(NutritionData::macros_only(400.0, 30.0, 15.0, 45.0)),
            source_url: None,
            image_url: None,
        }
    }

    fn create_test_entry(id: i64, recipe_id: i64, date: &str, servings: f64) -> MealPlanEntry {
        MealPlanEntry {
            id,
            date: date.to_string(),
            meal_type: MealTypeId::dinner(),
            recipe_id,
            recipe_name: "Test Recipe".to_string(),
            servings,
            nutrition: Some(NutritionData::macros_only(400.0, 30.0, 15.0, 45.0)),
            note: None,
        }
    }

    #[test]
    fn test_prepare_diary_entry() {
        let syncer = MealPlanSyncer::with_defaults();
        let recipe = create_test_recipe(1, "Grilled Chicken", 4);
        let entry = create_test_entry(1, 1, "2025-01-15", 2.0);
        let request = MealPlanSyncRequest::from_entry(entry);

        let diary_entry = syncer.prepare_diary_entry(&request, &recipe).unwrap();

        assert_eq!(diary_entry.date, "2025-01-15");
        assert_eq!(diary_entry.food_name, "Grilled Chicken");
        assert_eq!(diary_entry.servings, 2.0);

        // 2 servings out of 4, so half the total nutrition
        assert!((diary_entry.nutrition.calories - 200.0).abs() < 0.01);
        assert!((diary_entry.nutrition.protein - 15.0).abs() < 0.01);
    }

    #[test]
    fn test_prepare_diary_entry_no_nutrition() {
        let syncer = MealPlanSyncer::with_defaults();
        let mut recipe = create_test_recipe(1, "No Nutrition Recipe", 4);
        recipe.nutrition = None;

        let entry = create_test_entry(1, 1, "2025-01-15", 2.0);
        let request = MealPlanSyncRequest::from_entry(entry);

        let result = syncer.prepare_diary_entry(&request, &recipe);
        assert!(result.is_err());

        match result {
            Err(SyncError::RecipeNoNutrition { recipe_id, .. }) => {
                assert_eq!(recipe_id, 1);
            }
            _ => panic!("Expected RecipeNoNutrition error"),
        }
    }

    #[test]
    fn test_calculate_per_serving_nutrition() {
        let syncer = MealPlanSyncer::with_defaults();
        let total = NutritionData::macros_only(400.0, 40.0, 20.0, 50.0);

        let per_serving = syncer.calculate_per_serving_nutrition(&total, 4);

        assert!((per_serving.calories - 100.0).abs() < 0.01);
        assert!((per_serving.protein - 10.0).abs() < 0.01);
        assert!((per_serving.fat - 5.0).abs() < 0.01);
        assert!((per_serving.carbohydrate - 12.5).abs() < 0.01);
    }

    #[test]
    fn test_entries_conflict() {
        let syncer = MealPlanSyncer::with_defaults();

        let entry1 = DiaryEntry {
            entry_id: None,
            date: "2025-01-15".to_string(),
            meal: MealCategory::Dinner,
            food_name: "Chicken".to_string(),
            serving_description: "1 serving".to_string(),
            servings: 1.0,
            nutrition: NutritionData::zero(),
            source: DiaryEntrySource::Manual,
        };

        let entry2 = entry1.clone();
        assert!(syncer.entries_conflict(&entry1, &entry2));

        let mut entry3 = entry1.clone();
        entry3.date = "2025-01-16".to_string();
        assert!(!syncer.entries_conflict(&entry1, &entry3));

        let mut entry4 = entry1.clone();
        entry4.meal = MealCategory::Lunch;
        assert!(!syncer.entries_conflict(&entry1, &entry4));
    }

    #[test]
    fn test_merge_entries() {
        let syncer = MealPlanSyncer::with_defaults();

        let entries = vec![
            DiaryEntry {
                entry_id: None,
                date: "2025-01-15".to_string(),
                meal: MealCategory::Dinner,
                food_name: "Chicken".to_string(),
                serving_description: "1 serving".to_string(),
                servings: 1.0,
                nutrition: NutritionData::macros_only(200.0, 20.0, 10.0, 15.0),
                source: DiaryEntrySource::Manual,
            },
            DiaryEntry {
                entry_id: None,
                date: "2025-01-15".to_string(),
                meal: MealCategory::Dinner,
                food_name: "Chicken".to_string(),
                serving_description: "1 serving".to_string(),
                servings: 1.0,
                nutrition: NutritionData::macros_only(200.0, 20.0, 10.0, 15.0),
                source: DiaryEntrySource::Manual,
            },
        ];

        let merged = syncer.merge_entries(&entries).unwrap();

        assert_eq!(merged.servings, 2.0);
        assert!((merged.nutrition.calories - 400.0).abs() < 0.01);
        assert!((merged.nutrition.protein - 40.0).abs() < 0.01);
    }

    #[test]
    fn test_group_by_date() {
        let syncer = MealPlanSyncer::with_defaults();

        let entries = vec![
            DiaryEntry {
                entry_id: None,
                date: "2025-01-15".to_string(),
                meal: MealCategory::Breakfast,
                food_name: "Eggs".to_string(),
                serving_description: "2 eggs".to_string(),
                servings: 2.0,
                nutrition: NutritionData::zero(),
                source: DiaryEntrySource::Manual,
            },
            DiaryEntry {
                entry_id: None,
                date: "2025-01-15".to_string(),
                meal: MealCategory::Lunch,
                food_name: "Salad".to_string(),
                serving_description: "1 salad".to_string(),
                servings: 1.0,
                nutrition: NutritionData::zero(),
                source: DiaryEntrySource::Manual,
            },
            DiaryEntry {
                entry_id: None,
                date: "2025-01-16".to_string(),
                meal: MealCategory::Dinner,
                food_name: "Steak".to_string(),
                serving_description: "1 steak".to_string(),
                servings: 1.0,
                nutrition: NutritionData::zero(),
                source: DiaryEntrySource::Manual,
            },
        ];

        let groups = syncer.group_by_date(&entries);

        assert_eq!(groups.len(), 2);
        assert_eq!(groups.get("2025-01-15").unwrap().len(), 2);
        assert_eq!(groups.get("2025-01-16").unwrap().len(), 1);
    }

    #[test]
    fn test_calculate_daily_totals() {
        let syncer = MealPlanSyncer::with_defaults();

        let entries = vec![
            DiaryEntry {
                entry_id: None,
                date: "2025-01-15".to_string(),
                meal: MealCategory::Breakfast,
                food_name: "Eggs".to_string(),
                serving_description: "2 eggs".to_string(),
                servings: 2.0,
                nutrition: NutritionData::macros_only(200.0, 15.0, 12.0, 2.0),
                source: DiaryEntrySource::Manual,
            },
            DiaryEntry {
                entry_id: None,
                date: "2025-01-15".to_string(),
                meal: MealCategory::Lunch,
                food_name: "Salad".to_string(),
                serving_description: "1 salad".to_string(),
                servings: 1.0,
                nutrition: NutritionData::macros_only(150.0, 5.0, 8.0, 15.0),
                source: DiaryEntrySource::Manual,
            },
        ];

        let totals = syncer.calculate_daily_totals(&entries);

        assert!((totals.calories - 350.0).abs() < 0.01);
        assert!((totals.protein - 20.0).abs() < 0.01);
        assert!((totals.fat - 20.0).abs() < 0.01);
        assert!((totals.carbohydrate - 17.0).abs() < 0.01);
    }

    #[test]
    fn test_filter_by_date_range() {
        let syncer = MealPlanSyncer::with_defaults();

        let entries = vec![
            create_test_entry(1, 1, "2025-01-14", 1.0),
            create_test_entry(2, 1, "2025-01-15", 1.0),
            create_test_entry(3, 1, "2025-01-16", 1.0),
            create_test_entry(4, 1, "2025-01-17", 1.0),
        ];

        let start = DateString::new("2025-01-15").unwrap();
        let end = DateString::new("2025-01-16").unwrap();
        let range = DateRange::new(start, end).unwrap();

        let filtered = syncer.filter_by_date_range(&entries, &range);

        assert_eq!(filtered.len(), 2);
        assert_eq!(filtered[0].date, "2025-01-15");
        assert_eq!(filtered[1].date, "2025-01-16");
    }

    #[test]
    fn test_batch_result_from_results() {
        let results = vec![
            MealPlanSyncResult::success(
                1,
                FatSecretEntryId::new("123"),
                DiaryEntry {
                    entry_id: Some("123".to_string()),
                    date: "2025-01-15".to_string(),
                    meal: MealCategory::Dinner,
                    food_name: "Test".to_string(),
                    serving_description: "1 serving".to_string(),
                    servings: 1.0,
                    nutrition: NutritionData::zero(),
                    source: DiaryEntrySource::Manual,
                },
            ),
            MealPlanSyncResult::failure(2, "Recipe not found"),
        ];

        let batch_result = BatchMealPlanSyncResult::from_results(results, 1000);

        assert_eq!(batch_result.summary.processed, 2);
        assert_eq!(batch_result.summary.succeeded, 1);
        assert_eq!(batch_result.summary.failed, 1);
        assert_eq!(batch_result.summary.status, SyncStatus::PartialSuccess);
    }

    #[test]
    fn test_config_validation() {
        let valid = MealPlanSyncConfig::default();
        assert!(valid.validate().is_ok());

        let invalid = MealPlanSyncConfig {
            max_entries_per_sync: 0,
            ..MealPlanSyncConfig::default()
        };
        assert!(invalid.validate().is_err());

        let invalid = MealPlanSyncConfig {
            min_calories_threshold: -1.0,
            ..MealPlanSyncConfig::default()
        };
        assert!(invalid.validate().is_err());

        let invalid = MealPlanSyncConfig {
            min_calories_threshold: 100.0,
            max_calories_threshold: 50.0,
            ..MealPlanSyncConfig::default()
        };
        assert!(invalid.validate().is_err());
    }
}

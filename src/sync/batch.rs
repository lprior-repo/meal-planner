//! Batch Operations for Bulk Syncing
//!
//! This module provides batch processing capabilities for syncing large amounts
//! of data between FatSecret and Tandoor. It supports:
//!
//! - Batch recipe nutrition calculation
//! - Batch diary entry creation
//! - Batch ingredient matching
//! - Progress tracking and reporting
//! - Error handling and retry logic
//! - Rate limiting awareness
//!
//! # Batch Flow
//!
//! 1. Create batch operation with items
//! 2. Configure parallelism and rate limits
//! 3. Execute batch with progress callbacks
//! 4. Handle results (successes and failures)

use serde::{Deserialize, Serialize};

use super::errors::{SyncError, SyncResult};
use super::types::{
    DiaryEntry, FatSecretEntryId, FatSecretFoodId, NutritionData,
    SyncStatus, SyncSummary, TandoorRecipeId,
};

// =============================================================================
// CONFIGURATION
// =============================================================================

/// Batch operation configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchConfig {
    /// Maximum items per batch
    pub max_batch_size: usize,
    /// Maximum concurrent operations
    pub max_concurrent: usize,
    /// Delay between batches (ms)
    pub batch_delay_ms: u64,
    /// Maximum retries per item
    pub max_retries: u32,
    /// Retry delay (ms)
    pub retry_delay_ms: u64,
    /// Whether to stop on first error
    pub fail_fast: bool,
    /// Whether to track detailed progress
    pub track_progress: bool,
    /// Rate limit (operations per minute, 0 = unlimited)
    pub rate_limit_per_minute: u32,
}

impl Default for BatchConfig {
    fn default() -> Self {
        Self {
            max_batch_size: 50,
            max_concurrent: 5,
            batch_delay_ms: 100,
            max_retries: 3,
            retry_delay_ms: 1000,
            fail_fast: false,
            track_progress: true,
            rate_limit_per_minute: 60,
        }
    }
}

impl BatchConfig {
    /// Create for testing (fast, no delays)
    #[must_use]
    pub fn for_testing() -> Self {
        Self {
            max_batch_size: 10,
            max_concurrent: 2,
            batch_delay_ms: 0,
            max_retries: 1,
            retry_delay_ms: 0,
            fail_fast: true,
            track_progress: false,
            rate_limit_per_minute: 0,
        }
    }

    /// Create for production (conservative)
    #[must_use]
    pub fn production() -> Self {
        Self {
            max_batch_size: 25,
            max_concurrent: 3,
            batch_delay_ms: 200,
            max_retries: 3,
            retry_delay_ms: 2000,
            fail_fast: false,
            track_progress: true,
            rate_limit_per_minute: 30,
        }
    }

    /// Validate configuration
    pub fn validate(&self) -> SyncResult<()> {
        if self.max_batch_size == 0 {
            return Err(SyncError::config_invalid(
                "max_batch_size",
                "Must be at least 1",
            ));
        }
        if self.max_concurrent == 0 {
            return Err(SyncError::config_invalid(
                "max_concurrent",
                "Must be at least 1",
            ));
        }
        Ok(())
    }
}

// =============================================================================
// BATCH OPERATIONS
// =============================================================================

/// Type of batch operation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BatchOperationType {
    /// Calculate nutrition for recipes
    CalculateNutrition,
    /// Sync meal plans to diary
    SyncMealPlan,
    /// Match ingredients to foods
    MatchIngredients,
    /// Create diary entries
    CreateDiaryEntries,
    /// Update recipes with nutrition
    UpdateRecipeNutrition,
    /// Import recipes from FatSecret
    ImportRecipes,
}

/// A batch operation to execute
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchOperation<T> {
    /// Operation ID
    pub id: String,
    /// Operation type
    pub operation_type: BatchOperationType,
    /// Items to process
    pub items: Vec<T>,
    /// Current status
    pub status: BatchStatus,
    /// Configuration
    pub config: BatchConfig,
}

impl<T: Clone> BatchOperation<T> {
    /// Create a new batch operation
    #[must_use]
    pub fn new(operation_type: BatchOperationType, items: Vec<T>) -> Self {
        Self {
            id: generate_batch_id(),
            operation_type,
            items,
            status: BatchStatus::Pending,
            config: BatchConfig::default(),
        }
    }

    /// Create with custom config
    #[must_use]
    pub fn with_config(
        operation_type: BatchOperationType,
        items: Vec<T>,
        config: BatchConfig,
    ) -> Self {
        Self {
            id: generate_batch_id(),
            operation_type,
            items,
            status: BatchStatus::Pending,
            config,
        }
    }

    /// Get number of items
    #[must_use]
    pub fn len(&self) -> usize {
        self.items.len()
    }

    /// Check if empty
    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    /// Split into sub-batches
    #[must_use]
    pub fn split(&self) -> Vec<Vec<T>> {
        self.items
            .chunks(self.config.max_batch_size)
            .map(|chunk| chunk.to_vec())
            .collect()
    }
}

/// Generate a unique batch ID
fn generate_batch_id() -> String {
    use std::time::{SystemTime, UNIX_EPOCH};
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |d| d.as_millis());
    format!("batch_{now}")
}

// =============================================================================
// BATCH STATUS
// =============================================================================

/// Status of a batch operation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BatchStatus {
    /// Not yet started
    Pending,
    /// Currently running
    Running,
    /// Completed successfully
    Completed,
    /// Completed with some failures
    PartiallyCompleted,
    /// Failed completely
    Failed,
    /// Cancelled by user
    Cancelled,
    /// Paused
    Paused,
}

impl Default for BatchStatus {
    fn default() -> Self {
        Self::Pending
    }
}

impl BatchStatus {
    /// Check if terminal state
    #[must_use]
    pub fn is_terminal(self) -> bool {
        matches!(
            self,
            Self::Completed | Self::PartiallyCompleted | Self::Failed | Self::Cancelled
        )
    }

    /// Check if running
    #[must_use]
    pub fn is_running(self) -> bool {
        matches!(self, Self::Running | Self::Paused)
    }
}

// =============================================================================
// BATCH PROGRESS
// =============================================================================

/// Progress tracking for batch operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchProgress {
    /// Total items
    pub total: usize,
    /// Items processed
    pub processed: usize,
    /// Items succeeded
    pub succeeded: usize,
    /// Items failed
    pub failed: usize,
    /// Items skipped
    pub skipped: usize,
    /// Current batch number
    pub current_batch: usize,
    /// Total batches
    pub total_batches: usize,
    /// Estimated time remaining (ms)
    pub eta_ms: Option<u64>,
    /// Items per second
    pub items_per_second: f64,
    /// Current status
    pub status: BatchStatus,
    /// Error messages
    pub errors: Vec<BatchError>,
}

impl BatchProgress {
    /// Create initial progress
    #[must_use]
    pub fn new(total: usize, batch_size: usize) -> Self {
        let total_batches = (total + batch_size - 1) / batch_size;
        Self {
            total,
            processed: 0,
            succeeded: 0,
            failed: 0,
            skipped: 0,
            current_batch: 0,
            total_batches,
            eta_ms: None,
            items_per_second: 0.0,
            status: BatchStatus::Pending,
            errors: Vec::new(),
        }
    }

    /// Calculate completion percentage
    #[must_use]
    pub fn completion_percent(&self) -> f64 {
        if self.total == 0 {
            return 100.0;
        }
        (self.processed as f64 / self.total as f64) * 100.0
    }

    /// Calculate success rate
    #[must_use]
    pub fn success_rate(&self) -> f64 {
        if self.processed == 0 {
            return 0.0;
        }
        (self.succeeded as f64 / self.processed as f64) * 100.0
    }

    /// Record a success
    pub fn record_success(&mut self) {
        self.processed += 1;
        self.succeeded += 1;
    }

    /// Record a failure
    pub fn record_failure(&mut self, error: BatchError) {
        self.processed += 1;
        self.failed += 1;
        self.errors.push(error);
    }

    /// Record a skip
    pub fn record_skip(&mut self) {
        self.processed += 1;
        self.skipped += 1;
    }

    /// Update ETA based on elapsed time
    pub fn update_eta(&mut self, elapsed_ms: u64) {
        if self.processed == 0 || elapsed_ms == 0 {
            self.eta_ms = None;
            self.items_per_second = 0.0;
            return;
        }

        let remaining = self.total - self.processed;
        let ms_per_item = elapsed_ms as f64 / self.processed as f64;
        self.eta_ms = Some((remaining as f64 * ms_per_item) as u64);
        self.items_per_second = self.processed as f64 / (elapsed_ms as f64 / 1000.0);
    }

    /// Check if complete
    #[must_use]
    pub fn is_complete(&self) -> bool {
        self.processed >= self.total
    }
}

impl Default for BatchProgress {
    fn default() -> Self {
        Self::new(0, 1)
    }
}

/// An error from a batch item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchError {
    /// Item index
    pub index: usize,
    /// Item identifier (if available)
    pub item_id: Option<String>,
    /// Error message
    pub message: String,
    /// Whether error is retryable
    pub retryable: bool,
    /// Retry count
    pub retry_count: u32,
}

impl BatchError {
    /// Create a new batch error
    #[must_use]
    pub fn new(index: usize, message: impl Into<String>) -> Self {
        Self {
            index,
            item_id: None,
            message: message.into(),
            retryable: false,
            retry_count: 0,
        }
    }

    /// Create with item ID
    #[must_use]
    pub fn with_id(index: usize, item_id: impl Into<String>, message: impl Into<String>) -> Self {
        Self {
            index,
            item_id: Some(item_id.into()),
            message: message.into(),
            retryable: false,
            retry_count: 0,
        }
    }

    /// Mark as retryable
    #[must_use]
    pub fn retryable(mut self) -> Self {
        self.retryable = true;
        self
    }
}

// =============================================================================
// BATCH RESULTS
// =============================================================================

/// Result of a batch operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchResult<T> {
    /// Batch ID
    pub batch_id: String,
    /// Operation type
    pub operation_type: BatchOperationType,
    /// Final status
    pub status: BatchStatus,
    /// Final progress
    pub progress: BatchProgress,
    /// Successful results
    pub successes: Vec<BatchItemResult<T>>,
    /// Failed items
    pub failures: Vec<BatchItemResult<T>>,
    /// Summary
    pub summary: SyncSummary,
}

impl<T> BatchResult<T> {
    /// Create a successful result
    #[must_use]
    pub fn success(
        batch_id: String,
        operation_type: BatchOperationType,
        successes: Vec<BatchItemResult<T>>,
        duration_ms: u64,
    ) -> Self {
        let count = successes.len();
        Self {
            batch_id,
            operation_type,
            status: BatchStatus::Completed,
            progress: BatchProgress {
                total: count,
                processed: count,
                succeeded: count,
                failed: 0,
                skipped: 0,
                current_batch: 1,
                total_batches: 1,
                eta_ms: Some(0),
                items_per_second: count as f64 / (duration_ms as f64 / 1000.0),
                status: BatchStatus::Completed,
                errors: Vec::new(),
            },
            successes,
            failures: Vec::new(),
            summary: SyncSummary::success(count, duration_ms),
        }
    }

    /// Check if completely successful
    #[must_use]
    pub fn is_success(&self) -> bool {
        self.failures.is_empty()
    }

    /// Get all results (successes and failures)
    #[must_use]
    pub fn all_results(&self) -> Vec<&BatchItemResult<T>> {
        self.successes.iter().chain(self.failures.iter()).collect()
    }
}

/// Result for a single batch item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchItemResult<T> {
    /// Item index in original batch
    pub index: usize,
    /// Item identifier
    pub item_id: Option<String>,
    /// Whether successful
    pub success: bool,
    /// Result value (if successful)
    pub result: Option<T>,
    /// Error (if failed)
    pub error: Option<String>,
    /// Processing duration (ms)
    pub duration_ms: u64,
}

impl<T> BatchItemResult<T> {
    /// Create a successful result
    #[must_use]
    pub fn ok(index: usize, result: T, duration_ms: u64) -> Self {
        Self {
            index,
            item_id: None,
            success: true,
            result: Some(result),
            error: None,
            duration_ms,
        }
    }

    /// Create a failed result
    #[must_use]
    pub fn err(index: usize, error: impl Into<String>, duration_ms: u64) -> Self {
        Self {
            index,
            item_id: None,
            success: false,
            result: None,
            error: Some(error.into()),
            duration_ms,
        }
    }

    /// Set item ID
    #[must_use]
    pub fn with_id(mut self, id: impl Into<String>) -> Self {
        self.item_id = Some(id.into());
        self
    }
}

// =============================================================================
// BATCH SYNCER
// =============================================================================

/// Service for executing batch operations
///
/// This is the FUNCTIONAL CORE - it provides pure batch processing logic.
/// The IMPERATIVE SHELL handles actual API calls.
#[derive(Debug, Clone)]
pub struct BatchSyncer {
    config: BatchConfig,
}

impl BatchSyncer {
    /// Create a new batch syncer
    #[must_use]
    pub fn new(config: BatchConfig) -> Self {
        Self { config }
    }

    /// Create with default config
    #[must_use]
    pub fn with_defaults() -> Self {
        Self::new(BatchConfig::default())
    }

    /// Get configuration
    #[must_use]
    pub fn config(&self) -> &BatchConfig {
        &self.config
    }

    /// Create a batch operation for nutrition calculation
    #[must_use]
    pub fn create_nutrition_batch(&self, recipe_ids: Vec<TandoorRecipeId>) -> BatchOperation<TandoorRecipeId> {
        BatchOperation::with_config(
            BatchOperationType::CalculateNutrition,
            recipe_ids,
            self.config.clone(),
        )
    }

    /// Create a batch operation for diary entries
    #[must_use]
    pub fn create_diary_batch(&self, entries: Vec<DiaryEntry>) -> BatchOperation<DiaryEntry> {
        BatchOperation::with_config(
            BatchOperationType::CreateDiaryEntries,
            entries,
            self.config.clone(),
        )
    }

    /// Create a batch operation for ingredient matching
    #[must_use]
    pub fn create_matching_batch(&self, ingredients: Vec<String>) -> BatchOperation<String> {
        BatchOperation::with_config(
            BatchOperationType::MatchIngredients,
            ingredients,
            self.config.clone(),
        )
    }

    /// Process a batch with a function (pure implementation)
    pub fn process_batch<T, R, F>(&self, items: &[T], processor: F) -> Vec<BatchItemResult<R>>
    where
        T: Clone,
        F: Fn(usize, &T) -> Result<R, String>,
    {
        items
            .iter()
            .enumerate()
            .map(|(idx, item)| {
                let start = std::time::Instant::now();
                match processor(idx, item) {
                    Ok(result) => BatchItemResult::ok(idx, result, start.elapsed().as_millis() as u64),
                    Err(error) => BatchItemResult::err(idx, error, start.elapsed().as_millis() as u64),
                }
            })
            .collect()
    }

    /// Calculate required batches
    #[must_use]
    pub fn calculate_batches(&self, total_items: usize) -> usize {
        (total_items + self.config.max_batch_size - 1) / self.config.max_batch_size
    }

    /// Estimate time for batch (ms)
    #[must_use]
    pub fn estimate_time_ms(&self, total_items: usize, avg_item_time_ms: u64) -> u64 {
        let batches = self.calculate_batches(total_items);
        let item_time = total_items as u64 * avg_item_time_ms;
        let delay_time = (batches.saturating_sub(1) as u64) * self.config.batch_delay_ms;
        item_time + delay_time
    }

    /// Should retry based on error
    #[must_use]
    pub fn should_retry(&self, error: &BatchError) -> bool {
        error.retryable && error.retry_count < self.config.max_retries
    }

    /// Calculate retry delay with exponential backoff
    #[must_use]
    pub fn retry_delay_ms(&self, retry_count: u32) -> u64 {
        let base = self.config.retry_delay_ms;
        let multiplier = 2_u64.saturating_pow(retry_count);
        base.saturating_mul(multiplier)
    }

    /// Aggregate batch results into summary
    #[must_use]
    pub fn aggregate_results<T>(&self, results: &[BatchItemResult<T>], duration_ms: u64) -> SyncSummary {
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

        SyncSummary {
            status,
            processed,
            succeeded,
            failed,
            skipped: 0,
            duration_ms,
            errors,
        }
    }

    /// Group items into batches
    #[must_use]
    pub fn chunk_items<T: Clone>(&self, items: &[T]) -> Vec<Vec<T>> {
        items
            .chunks(self.config.max_batch_size)
            .map(|chunk| chunk.to_vec())
            .collect()
    }
}

impl Default for BatchSyncer {
    fn default() -> Self {
        Self::with_defaults()
    }
}

// =============================================================================
// BATCH ITEM TYPES
// =============================================================================

/// A recipe for batch nutrition calculation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchNutritionItem {
    /// Recipe ID
    pub recipe_id: TandoorRecipeId,
    /// Recipe name
    pub name: String,
    /// Calculated nutrition (output)
    pub nutrition: Option<NutritionData>,
    /// Failed ingredients
    pub failed_ingredients: Vec<String>,
}

/// A diary entry for batch creation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchDiaryItem {
    /// Input entry
    pub entry: DiaryEntry,
    /// Created entry ID (output)
    pub entry_id: Option<FatSecretEntryId>,
}

/// An ingredient for batch matching
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BatchMatchItem {
    /// Ingredient name
    pub ingredient: String,
    /// Matched food ID (output)
    pub food_id: Option<FatSecretFoodId>,
    /// Match confidence
    pub confidence: f64,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_batch_config_validation() {
        let valid = BatchConfig::default();
        assert!(valid.validate().is_ok());

        let invalid = BatchConfig {
            max_batch_size: 0,
            ..BatchConfig::default()
        };
        assert!(invalid.validate().is_err());

        let invalid = BatchConfig {
            max_concurrent: 0,
            ..BatchConfig::default()
        };
        assert!(invalid.validate().is_err());
    }

    #[test]
    fn test_batch_operation_split() {
        let config = BatchConfig {
            max_batch_size: 3,
            ..BatchConfig::default()
        };
        let items: Vec<i32> = (1..=10).collect();
        let batch = BatchOperation::with_config(BatchOperationType::CalculateNutrition, items, config);

        let chunks = batch.split();
        assert_eq!(chunks.len(), 4); // 3 + 3 + 3 + 1
        assert_eq!(chunks[0], vec![1, 2, 3]);
        assert_eq!(chunks[3], vec![10]);
    }

    #[test]
    fn test_batch_progress() {
        let mut progress = BatchProgress::new(100, 10);
        assert_eq!(progress.total, 100);
        assert_eq!(progress.total_batches, 10);
        assert!((progress.completion_percent() - 0.0).abs() < 1e-10);

        progress.record_success();
        progress.record_success();
        progress.record_failure(BatchError::new(2, "test error"));

        assert_eq!(progress.processed, 3);
        assert_eq!(progress.succeeded, 2);
        assert_eq!(progress.failed, 1);
        assert_eq!(progress.errors.len(), 1);
        assert!((progress.completion_percent() - 3.0).abs() < 0.01);
        assert!((progress.success_rate() - 66.67).abs() < 0.1);
    }

    #[test]
    fn test_batch_progress_eta() {
        let mut progress = BatchProgress::new(100, 10);
        progress.processed = 25;
        progress.update_eta(1000); // 1 second for 25 items

        assert!(progress.eta_ms.is_some());
        // 75 remaining items at 40ms each = ~3000ms
        assert!((progress.eta_ms.unwrap() as f64 - 3000.0).abs() < 100.0);
        assert!((progress.items_per_second - 25.0).abs() < 0.1);
    }

    #[test]
    fn test_batch_syncer_process() {
        let syncer = BatchSyncer::with_defaults();
        let items = vec![1, 2, 3, 4, 5];

        let results = syncer.process_batch(&items, |_idx, item| {
            if *item % 2 == 0 {
                Ok(item * 2)
            } else {
                Err(format!("Odd number: {item}"))
            }
        });

        assert_eq!(results.len(), 5);
        assert!(results[1].success); // 2 -> 4
        assert!(results[3].success); // 4 -> 8
        assert!(!results[0].success); // 1 is odd
        assert!(!results[2].success); // 3 is odd
    }

    #[test]
    fn test_batch_syncer_calculate_batches() {
        let syncer = BatchSyncer::new(BatchConfig {
            max_batch_size: 10,
            ..BatchConfig::default()
        });

        assert_eq!(syncer.calculate_batches(0), 0);
        assert_eq!(syncer.calculate_batches(5), 1);
        assert_eq!(syncer.calculate_batches(10), 1);
        assert_eq!(syncer.calculate_batches(11), 2);
        assert_eq!(syncer.calculate_batches(100), 10);
    }

    #[test]
    fn test_batch_syncer_retry_delay() {
        let syncer = BatchSyncer::new(BatchConfig {
            retry_delay_ms: 1000,
            ..BatchConfig::default()
        });

        assert_eq!(syncer.retry_delay_ms(0), 1000);
        assert_eq!(syncer.retry_delay_ms(1), 2000);
        assert_eq!(syncer.retry_delay_ms(2), 4000);
        assert_eq!(syncer.retry_delay_ms(3), 8000);
    }

    #[test]
    fn test_batch_syncer_aggregate_results() {
        let syncer = BatchSyncer::with_defaults();
        let results = vec![
            BatchItemResult::ok(0, "a", 100),
            BatchItemResult::ok(1, "b", 100),
            BatchItemResult::err(2, "error", 100),
        ];

        let summary = syncer.aggregate_results(&results, 300);
        assert_eq!(summary.processed, 3);
        assert_eq!(summary.succeeded, 2);
        assert_eq!(summary.failed, 1);
        assert_eq!(summary.status, SyncStatus::PartialSuccess);
    }

    #[test]
    fn test_batch_status() {
        assert!(!BatchStatus::Pending.is_terminal());
        assert!(!BatchStatus::Running.is_terminal());
        assert!(BatchStatus::Completed.is_terminal());
        assert!(BatchStatus::Failed.is_terminal());
        assert!(BatchStatus::Cancelled.is_terminal());

        assert!(!BatchStatus::Pending.is_running());
        assert!(BatchStatus::Running.is_running());
        assert!(BatchStatus::Paused.is_running());
    }

    #[test]
    fn test_batch_error() {
        let error = BatchError::new(5, "test error")
            .retryable();

        assert_eq!(error.index, 5);
        assert_eq!(error.message, "test error");
        assert!(error.retryable);
        assert_eq!(error.retry_count, 0);
    }

    #[test]
    fn test_batch_item_result() {
        let success: BatchItemResult<i32> = BatchItemResult::ok(0, 42, 100).with_id("item_1");
        assert!(success.success);
        assert_eq!(success.result, Some(42));
        assert_eq!(success.item_id, Some("item_1".to_string()));

        let failure: BatchItemResult<i32> = BatchItemResult::err(1, "failed", 50);
        assert!(!failure.success);
        assert_eq!(failure.error, Some("failed".to_string()));
    }
}

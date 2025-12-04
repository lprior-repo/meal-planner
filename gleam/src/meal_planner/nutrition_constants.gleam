/// Nutrition and macro constants for meal planning
///
/// This module centralizes all nutritional targets, thresholds, and calculation
/// constants to eliminate magic numbers throughout the codebase.
///
/// Constants are organized by category:
/// - Daily macro targets
/// - Percentage thresholds for target evaluation
/// - Code analysis thresholds
/// - UI/UX dimension constants
/// - Database/processing constants
// ===================================================================
// DAILY MACRO TARGETS
// ===================================================================

/// Daily protein target in grams
/// Vertical Diet recommendation: ~150g for optimal muscle recovery
pub const daily_protein_target = 150.0

/// Daily fat target in grams
/// Vertical Diet recommendation: ~60g for hormone production
pub const daily_fat_target = 60.0

/// Daily carbohydrate target in grams
/// Vertical Diet recommendation: ~200g for glycogen and energy
pub const daily_carbs_target = 200.0

/// Daily calorie target in kilocalories
/// Standard baseline for meal planning (adjustable per user)
pub const daily_calorie_target = 2000.0

// ===================================================================
// TARGET PERCENTAGE THRESHOLDS
// ===================================================================

/// Lower threshold for macro targets (percentage)
/// Below 90%: indicates macro deficiency (shows yellow warning)
pub const target_lower_threshold = 90.0

/// Upper threshold for macro targets (percentage)
/// Above 110%: indicates macro excess (shows orange/red warning)
pub const target_upper_threshold = 110.0

/// Additional threshold for excess detection (percentage)
/// Above 130%: indicates significant macro excess
pub const target_excess_threshold = 130.0

/// Maximum display percentage for progress bars
/// Caps at 150% for visual consistency in UI
pub const maximum_display_percentage = 150.0

// ===================================================================
// CODE ANALYSIS THRESHOLDS
// ===================================================================

/// Maximum recommended function line count
/// Functions exceeding 50 lines are flagged as too long for maintenance
pub const max_function_lines = 50.0

/// Minimum functions for meaningful coverage analysis
/// If 0 functions, coverage is considered complete (100%)
pub const minimum_coverage_functions = 0

// ===================================================================
// DATABASE AND PROCESSING CONSTANTS
// ===================================================================

/// Batch size for database inserts in import operations
/// Processes 5000 records per batch for optimal performance
pub const import_batch_size = 5000

/// Progress reporting interval for parallel processing
/// Reports progress every 50,000 inserted records
pub const progress_report_interval = 50_000

/// PostgreSQL connection pool size
/// Maximum 50 concurrent connections to database
pub const pg_pool_size = 50

/// Number of parallel workers for nutrient import
/// Uses 4 workers for fast nutrient data processing
pub const nutrient_import_workers = 4

/// Number of parallel workers for food import
/// Uses 16 workers for efficient food data processing
pub const food_import_workers = 16

/// Number of parallel workers for food nutrient mappings
/// Uses 32 workers for maximum parallelism on mappings
pub const food_nutrient_import_workers = 32

/// Timeout for worker processes in milliseconds
/// 10 minute timeout (600,000 ms) for completion
pub const worker_timeout_ms = 600_000

// ===================================================================
// UI/UX DIMENSION CONSTANTS
// ===================================================================

/// Skeleton loader width for text labels (pixels)
pub const skeleton_label_width = 150

/// Skeleton loader width for calorie card display (pixels)
pub const skeleton_calorie_width = 200

/// Default skeleton loader height for large blocks (pixels)
pub const skeleton_large_height = 200

/// Percentage display values in lazy loader
/// "70%" width for main text in search results
pub const skeleton_main_text_width_percent = 70

/// Percentage display values in lazy loader
/// "40%" width for secondary text in search results
pub const skeleton_secondary_text_width_percent = 40

// ===================================================================
// API RATE LIMITING AND BATCH PROCESSING
// ===================================================================

/// Maximum tasks per Todoist API batch request
/// Todoist API limit: 200 tasks per request
pub const todoist_batch_size = 200

/// Todoist API rate limit: requests per minute
pub const todoist_requests_per_minute = 120

// ===================================================================
// UI FORM FIELD CONSTRAINTS
// ===================================================================

/// Maximum recipe name length in characters
pub const max_recipe_name_length = 100

/// Minimum recipe name length in characters
pub const min_recipe_name_length = 3

/// Maximum prep/cook time in minutes
pub const max_cooking_time = 999

/// Maximum number of servings
pub const max_servings = 100

/// Maximum calories per serving
pub const max_calories_per_serving = 9999

/// Maximum grams for macronutrients (protein, carbs, fat, fiber, sugar)
pub const max_macronutrient_grams = 999

/// Default number of servings
pub const default_servings = 4

/// Default placeholder amount for ingredients (grams)
pub const default_ingredient_amount = 200

// ===================================================================
// EMAIL DISPLAY CONSTANTS
// ===================================================================

/// Days in a week (for weekly summary emails)
pub const days_in_week = 7

/// Email example: default avg daily protein in grams
pub const email_default_protein_g = 150

/// Email example: default avg daily fat in grams
pub const email_default_fat_g = 50

/// Email example: default avg daily carbs in grams
pub const email_default_carbs_g = 200

/// Scaling efficiency threshold
pub const scaling_efficiency_factor = 0.95

// ===================================================================
// SEARCH AND QUERY CONSTRAINTS
// ===================================================================

/// Maximum search query length in characters
/// Prevents overly long search strings (e.g., SQL injection attempts)
pub const max_query_length = 200

/// Default search result limit for queries
/// Balances result relevance with database performance
pub const default_search_limit = 50

// ===================================================================
// MEAL PLANNING AND MEAL DEFAULTS
// ===================================================================

/// Default portion size multiplier for meals
/// 1.0 = single serving, 0.5 = half serving, 2.0 = double serving
pub const default_portion_size = 1.0

/// Total micronutrients tracked in nutritional analysis
/// Used for comprehensive nutrient tracking across meals
pub const micronutrient_count = 21

/// Number of main meals per day in standard plan
/// Breakfast, Lunch, Dinner
pub const meals_per_day = 3

/// Days in a standard meal planning week
pub const days_per_week = 7

/// Default user ID for singleton user model
/// Used when no user authentication is implemented
pub const default_user_id = 1

// ===================================================================
// ALIASES FOR TDD COMPATIBILITY
// ===================================================================

/// Recommended daily protein intake in grams (alias for daily_protein_target)
pub const recommended_protein_g = 150.0

/// Recommended daily fat intake in grams (alias for daily_fat_target)
pub const recommended_fat_g = 50.0

/// Recommended daily carbohydrate intake in grams (alias for daily_carbs_target)
pub const recommended_carbs_g = 200.0

/// Quality threshold for meal nutritional composition rating (0.0 to 1.0)
pub const quality_threshold = 0.95

/// Default daily calorie target (alias for daily_calorie_target)
pub const default_calorie_target = 2000.0

// ===================================================================
// UI MACRO SUMMARY THRESHOLDS
// ===================================================================

/// Threshold for "under target" status in macro progress (percentage)
/// Used in macro_summary.gleam for color coding (yellow warning)
pub const macro_under_threshold = 90.0

/// Threshold for "on target" upper bound (percentage)
/// Used in macro_summary.gleam for color coding (green)
pub const macro_on_target_upper = 110.0

/// Threshold for "over" status (percentage)
/// Used in macro_summary.gleam for color coding (orange)
pub const macro_over_threshold = 130.0

/// Percentage divisor for averaging macro percentages
/// Used when calculating average across multiple macros (3.0 for 3 macros)
pub const macro_average_divisor = 3.0

/// Maximum percentage cap for display in progress bars
/// Capped at 100% for visual consistency
pub const progress_bar_visual_cap = 100.0

// ===================================================================
// UI MICRONUTRIENT THRESHOLDS
// ===================================================================

/// Threshold for "low" micronutrient status (percentage)
/// Below 50% of daily value - deficiency warning
pub const micronutrient_low_threshold = 50.0

/// Threshold for "optimal" micronutrient status (percentage)
/// 50-100% of daily value - optimal range
pub const micronutrient_optimal_threshold = 100.0

/// Threshold for "high" micronutrient status (percentage)
/// 100-150% of daily value - elevated but acceptable
pub const micronutrient_high_threshold = 150.0

/// Default daily value limit for sugar (grams)
/// Arbitrary limit used when sugar data available
pub const default_sugar_daily_value = 50.0

/// Precision multiplier for formatting amounts (1 decimal place)
pub const format_precision_multiplier = 10.0

// ===================================================================
// CALORIE PERCENTAGE THRESHOLDS
// ===================================================================

/// Threshold for calorie deficit (percentage)
/// Below 90% of target - shows green
pub const calorie_deficit_threshold = 90.0

/// Threshold for calorie match (percentage)
/// 90-100% of target - shows yellow
pub const calorie_match_threshold = 100.0

/// Animation duration for calorie counter transitions (milliseconds)
pub const calorie_animation_duration = 1000

// ===================================================================
// CACHE AND TIME CONSTANTS
// ===================================================================

/// Default cache size (number of entries)
pub const default_cache_size = 100

/// Default cache TTL in seconds (5 minutes)
pub const default_cache_ttl_seconds = 300

/// Nanoseconds per microsecond for time conversion
pub const nanoseconds_per_microsecond = 1000

// ===================================================================
// RECIPE ID GENERATION CONSTANTS
// ===================================================================

/// Modulo divisor for generating short recipe IDs
/// Takes last 6 digits of milliseconds (modulo 1,000,000) for compact ID generation
pub const recipe_id_modulo_divisor = 1_000_000

// ===================================================================
// TASK-SPECIFIC ALIASES (for TDD compatibility)
// ===================================================================

/// Default daily calorie target (alias for daily_calorie_target)
pub const default_calorie_target = 2000.0

/// Recommended daily protein in grams (alias for daily_protein_target)
pub const recommended_protein_g = 150.0

/// Recommended daily fat in grams (alias for daily_fat_target)
pub const recommended_fat_g = 50.0

/// Recommended daily carbs in grams (alias for daily_carbs_target)
pub const recommended_carbs_g = 200.0

/// Quality/acceptability threshold for scores (0.0 to 1.0)
pub const quality_threshold = 0.95

/// Nutrition and macro constants for meal planning
///
/// This module centralizes all nutritional targets, thresholds, and calculation
/// constants to eliminate magic numbers throughout the codebase.
pub const daily_protein_target = 150.0

pub const daily_fat_target = 60.0

pub const daily_carbs_target = 200.0

pub const daily_calorie_target = 2000.0

pub const target_lower_threshold = 90.0

pub const target_upper_threshold = 110.0

pub const target_excess_threshold = 130.0

pub const maximum_display_percentage = 150.0

pub const max_function_lines = 50.0

pub const minimum_coverage_functions = 0

pub const import_batch_size = 5000

pub const progress_report_interval = 50_000

pub const pg_pool_size = 50

pub const nutrient_import_workers = 4

pub const food_import_workers = 16

pub const food_nutrient_import_workers = 32

// 60 minutes per worker - food_nutrients has ~838K rows/worker
pub const worker_timeout_ms = 3_600_000

pub const skeleton_label_width = 150

pub const skeleton_calorie_width = 200

pub const skeleton_large_height = 200

pub const skeleton_main_text_width_percent = 70

pub const skeleton_secondary_text_width_percent = 40

pub const todoist_batch_size = 200

pub const todoist_requests_per_minute = 120

pub const max_recipe_name_length = 100

pub const min_recipe_name_length = 3

pub const max_cooking_time = 999

pub const max_servings = 100

pub const max_calories_per_serving = 9999

pub const max_macronutrient_grams = 999

pub const default_servings = 4

pub const default_ingredient_amount = 200

pub const max_query_length = 200

pub const default_search_limit = 50

pub const min_query_length = 2

pub const max_search_limit = 100

pub const default_portion_size = 1.0

pub const micronutrient_count = 21

pub const meals_per_day = 3

pub const days_per_week = 7

pub const default_user_id = 1

pub const recommended_protein_g = 150.0

pub const recommended_fat_g = 50.0

pub const recommended_carbs_g = 200.0

pub const default_calorie_target = 2000.0

pub const quality_threshold = 0.95

pub const macro_under_threshold = 90.0

pub const macro_on_target_upper = 110.0

pub const macro_over_threshold = 130.0

pub const macro_average_divisor = 3.0

pub const progress_bar_visual_cap = 100.0

pub const micronutrient_low_threshold = 50.0

pub const micronutrient_optimal_threshold = 100.0

pub const micronutrient_high_threshold = 150.0

pub const default_sugar_daily_value = 50.0

pub const format_precision_multiplier = 10.0

pub const calorie_deficit_threshold = 90.0

pub const calorie_match_threshold = 100.0

pub const calorie_animation_duration = 1000

pub const default_cache_size = 100

pub const default_cache_ttl_seconds = 300

pub const nanoseconds_per_microsecond = 1000

pub const milliseconds_per_second = 1000

pub const recipe_id_modulo_divisor = 1_000_000

pub const days_in_week = 7

pub const email_default_protein_g = 150

pub const email_default_fat_g = 50

pub const email_default_carbs_g = 200

pub const scaling_efficiency_factor = 0.95

pub const percent_multiplier = 100

pub const target_db_load_reduction_percent = 50.0

pub const cached_query_time_ms = 0.5

pub const uncached_search_query_time_ms = 5.0

pub const uncached_filtered_search_query_time_ms = 8.0

pub const min_speedup_factor = 1.0

pub const foundation_food_quality_score = 100

pub const sr_legacy_food_quality_score = 90

pub const survey_fndds_food_quality_score = 80

pub const default_food_quality_score = 50

pub const exact_match_priority = 100

pub const partial_match_priority = 50

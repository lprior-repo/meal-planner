//// Recipe Rotation Tracking
////
//// Tracks 30-day recipe history to prevent repeats and suggest variety.
//// Ensures meal plans have adequate diversity and prevents recipe fatigue.
////
//// Features:
//// - 30-day sliding window history
//// - Repeat prevention with configurable cooldown periods
//// - Variety scoring based on recent usage
//// - Category-aware rotation (breakfast, lunch, dinner)
//// - Last-used tracking per recipe

import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import meal_planner/id.{
  type RecipeId, recipe_id, recipe_id_equal, recipe_id_to_string,
}

// ============================================================================
// Constants
// ============================================================================

/// Number of days to track in rotation history
pub const rotation_window_days: Int = 30

/// Minimum days before a recipe can be repeated
pub const default_cooldown_days: Int = 7

// ============================================================================
// Types
// ============================================================================

/// A timestamp representing days since epoch (for simplicity)
pub type DayTimestamp =
  Int

/// Record of when a recipe was used
pub type RecipeUsage {
  RecipeUsage(recipe_id: RecipeId, day: DayTimestamp, category: String)
}

/// Recipe rotation tracker with 30-day history
pub opaque type RotationTracker {
  RotationTracker(
    /// All usage records within the rotation window
    history: List(RecipeUsage),
    /// Current day timestamp
    current_day: DayTimestamp,
    /// Cooldown period in days (default: 7)
    cooldown_days: Int,
  )
}

/// Variety score for a recipe (higher = more variety, use this recipe)
pub type VarietyScore {
  VarietyScore(
    recipe_id: RecipeId,
    /// Overall variety score (0.0 to 1.0, higher means more variety)
    score: Float,
    /// Days since last use (None if never used)
    days_since_last_use: Option(Int),
    /// Number of times used in rotation window
    usage_count: Int,
    /// Whether recipe is on cooldown
    on_cooldown: Bool,
  )
}

// ============================================================================
// Constructor
// ============================================================================

/// Create a new rotation tracker
pub fn new(current_day: DayTimestamp) -> RotationTracker {
  RotationTracker(history: [], current_day: current_day, cooldown_days: 7)
}

/// Create a rotation tracker with custom cooldown period
pub fn new_with_cooldown(
  current_day: DayTimestamp,
  cooldown_days: Int,
) -> RotationTracker {
  RotationTracker(
    history: [],
    current_day: current_day,
    cooldown_days: cooldown_days,
  )
}

/// Create a rotation tracker from existing history
pub fn from_history(
  history: List(RecipeUsage),
  current_day: DayTimestamp,
) -> RotationTracker {
  let history = prune_old_history(history, current_day)
  RotationTracker(history: history, current_day: current_day, cooldown_days: 7)
}

// ============================================================================
// History Management
// ============================================================================

/// Add a recipe usage to the tracker
pub fn record_usage(
  tracker: RotationTracker,
  recipe_id: RecipeId,
  category: String,
) -> RotationTracker {
  let usage =
    RecipeUsage(
      recipe_id: recipe_id,
      day: tracker.current_day,
      category: category,
    )
  let history = [usage, ..tracker.history]
  RotationTracker(..tracker, history: history)
}

/// Advance to a new day and prune old history
pub fn advance_day(
  tracker: RotationTracker,
  new_day: DayTimestamp,
) -> RotationTracker {
  let history = prune_old_history(tracker.history, new_day)
  RotationTracker(..tracker, current_day: new_day, history: history)
}

/// Remove history entries older than the rotation window
fn prune_old_history(
  history: List(RecipeUsage),
  current_day: DayTimestamp,
) -> List(RecipeUsage) {
  let cutoff_day = current_day - rotation_window_days
  list.filter(history, fn(usage) { usage.day > cutoff_day })
}

// ============================================================================
// Repeat Prevention
// ============================================================================

/// Check if a recipe is on cooldown (too recently used)
pub fn is_on_cooldown(tracker: RotationTracker, recipe_id: RecipeId) -> Bool {
  case find_last_usage(tracker, recipe_id) {
    None -> False
    Some(usage) -> {
      let days_since = tracker.current_day - usage.day
      days_since < tracker.cooldown_days
    }
  }
}

/// Find the most recent usage of a recipe
pub fn find_last_usage(
  tracker: RotationTracker,
  recipe_id: RecipeId,
) -> Option(RecipeUsage) {
  tracker.history
  |> list.filter(fn(usage) { recipe_id_equal(usage.recipe_id, recipe_id) })
  |> list.sort(fn(a, b) { int.compare(b.day, a.day) })
  |> list.first
  |> result.map(Some)
  |> result.unwrap(None)
}

/// Get days since a recipe was last used
pub fn days_since_last_use(
  tracker: RotationTracker,
  recipe_id: RecipeId,
) -> Option(Int) {
  case find_last_usage(tracker, recipe_id) {
    None -> None
    Some(usage) -> Some(tracker.current_day - usage.day)
  }
}

/// Count how many times a recipe has been used in the window
pub fn usage_count(tracker: RotationTracker, recipe_id: RecipeId) -> Int {
  tracker.history
  |> list.filter(fn(usage) { recipe_id_equal(usage.recipe_id, recipe_id) })
  |> list.length
}

// ============================================================================
// Variety Scoring
// ============================================================================

/// Calculate variety score for a recipe (higher = more variety)
pub fn calculate_variety_score(
  tracker: RotationTracker,
  recipe_id: RecipeId,
) -> VarietyScore {
  let count = usage_count(tracker, recipe_id)
  let days_since = days_since_last_use(tracker, recipe_id)
  let on_cooldown = is_on_cooldown(tracker, recipe_id)

  // Base score calculation
  let recency_score = case days_since {
    None -> 1.0
    Some(days) -> {
      let days_float = int.to_float(days)
      let window_float = int.to_float(rotation_window_days)
      // Linear scale: more days since last use = higher score
      float_min(days_float /. window_float, 1.0)
    }
  }

  // Frequency penalty: more usage = lower score
  let frequency_score = case count {
    0 -> 1.0
    _ -> {
      let count_float = int.to_float(count)
      // Exponential decay: each use reduces score
      float_exp(-0.2 *. count_float)
    }
  }

  // Cooldown penalty: recipes on cooldown get zero score
  let cooldown_multiplier = case on_cooldown {
    True -> 0.0
    False -> 1.0
  }

  // Combine scores: 60% recency, 40% frequency
  let score =
    { recency_score *. 0.6 +. frequency_score *. 0.4 } *. cooldown_multiplier

  VarietyScore(
    recipe_id: recipe_id,
    score: score,
    days_since_last_use: days_since,
    usage_count: count,
    on_cooldown: on_cooldown,
  )
}

/// Calculate variety scores for multiple recipes
pub fn score_recipes(
  tracker: RotationTracker,
  recipe_ids: List(RecipeId),
) -> List(VarietyScore) {
  list.map(recipe_ids, fn(recipe_id) {
    calculate_variety_score(tracker, recipe_id)
  })
}

/// Filter recipes that are not on cooldown
pub fn filter_available(
  tracker: RotationTracker,
  recipe_ids: List(RecipeId),
) -> List(RecipeId) {
  list.filter(recipe_ids, fn(recipe_id) { !is_on_cooldown(tracker, recipe_id) })
}

/// Sort recipes by variety score (highest first)
pub fn sort_by_variety(scores: List(VarietyScore)) -> List(VarietyScore) {
  list.sort(scores, fn(a, b) {
    case float_compare(b.score, a.score) {
      order.Lt -> order.Lt
      order.Gt -> order.Gt
      order.Eq -> order.Eq
    }
  })
}

/// Get the top N recipes with most variety
pub fn suggest_variety(
  tracker: RotationTracker,
  recipe_ids: List(RecipeId),
  count: Int,
) -> List(RecipeId) {
  score_recipes(tracker, recipe_ids)
  |> sort_by_variety
  |> list.take(count)
  |> list.map(fn(score) { score.recipe_id })
}

// ============================================================================
// Category-Aware Rotation
// ============================================================================

/// Get usage history for a specific category
pub fn category_history(
  tracker: RotationTracker,
  category: String,
) -> List(RecipeUsage) {
  list.filter(tracker.history, fn(usage) { usage.category == category })
}

/// Get variety score within a specific category
pub fn category_variety_score(
  tracker: RotationTracker,
  recipe_id: RecipeId,
  category: String,
) -> VarietyScore {
  // Create a temporary tracker with only category history
  let category_tracker =
    RotationTracker(
      history: category_history(tracker, category),
      current_day: tracker.current_day,
      cooldown_days: tracker.cooldown_days,
    )

  calculate_variety_score(category_tracker, recipe_id)
}

/// Suggest variety within a specific category
pub fn suggest_category_variety(
  tracker: RotationTracker,
  recipe_ids: List(RecipeId),
  category: String,
  count: Int,
) -> List(RecipeId) {
  recipe_ids
  |> list.map(fn(recipe_id) {
    category_variety_score(tracker, recipe_id, category)
  })
  |> sort_by_variety
  |> list.take(count)
  |> list.map(fn(score) { score.recipe_id })
}

// ============================================================================
// Statistics
// ============================================================================

/// Get statistics about the rotation tracker
pub type RotationStats {
  RotationStats(
    /// Total recipes in history
    total_recipes: Int,
    /// Unique recipes used
    unique_recipes: Int,
    /// Average days between uses
    avg_days_between_uses: Float,
    /// Most used recipe (if any)
    most_used: Option(RecipeId),
    /// Least recently used recipe (if any)
    least_recently_used: Option(RecipeId),
  )
}

/// Calculate rotation statistics
pub fn calculate_stats(tracker: RotationTracker) -> RotationStats {
  let total_recipes = list.length(tracker.history)

  let unique_recipes =
    tracker.history
    |> list.map(fn(usage) { recipe_id_to_string(usage.recipe_id) })
    |> list.unique
    |> list.length

  // Group by recipe ID and count
  let usage_counts =
    tracker.history
    |> list.group(fn(usage) { recipe_id_to_string(usage.recipe_id) })
    |> dict.to_list

  // Find most used recipe
  let most_used =
    usage_counts
    |> list.sort(fn(a, b) { int.compare(list.length(b.1), list.length(a.1)) })
    |> list.first
    |> result.map(fn(pair) { recipe_id(pair.0) })
    |> result.map(Some)
    |> result.unwrap(None)

  // Find least recently used
  let least_recently_used =
    tracker.history
    |> list.sort(fn(a, b) { int.compare(a.day, b.day) })
    |> list.first
    |> result.map(fn(usage) { usage.recipe_id })
    |> result.map(Some)
    |> result.unwrap(None)

  // Calculate average days between uses
  let avg_days = case unique_recipes {
    0 -> 0.0
    _ -> {
      let window_float = int.to_float(rotation_window_days)
      let unique_float = int.to_float(unique_recipes)
      window_float /. unique_float
    }
  }

  RotationStats(
    total_recipes: total_recipes,
    unique_recipes: unique_recipes,
    avg_days_between_uses: avg_days,
    most_used: most_used,
    least_recently_used: least_recently_used,
  )
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Float minimum
fn float_min(a: Float, b: Float) -> Float {
  case a <. b {
    True -> a
    False -> b
  }
}

/// Float comparison for sorting
fn float_compare(a: Float, b: Float) -> order.Order {
  case a <. b, a >. b {
    True, _ -> order.Lt
    _, True -> order.Gt
    _, _ -> order.Eq
  }
}

/// Approximate e^x for variety scoring
fn float_exp(x: Float) -> Float {
  // Simple approximation: e^x ≈ 1 + x + x²/2 + x³/6 + x⁴/24
  // Good enough for x in [-1, 1]
  let x2 = x *. x
  let x3 = x2 *. x
  let x4 = x3 *. x
  1.0 +. x +. x2 /. 2.0 +. x3 /. 6.0 +. x4 /. 24.0
}

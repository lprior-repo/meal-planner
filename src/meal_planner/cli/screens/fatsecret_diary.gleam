/// FatSecret Diary TUI Screen - Type System
///
/// This module defines the complete type architecture for the FatSecret
/// Diary TUI screen following Shore Framework (Elm Architecture).
///
/// ARCHITECTURE PRINCIPLES:
/// 1. IMMUTABILITY: All state updates use record spread syntax
/// 2. NO_NULLS: Option/Result for all nullable/fallible values
/// 3. EXHAUSTIVE_MATCHING: ViewState prevents impossible UI states
/// 4. TYPE_SAFETY: Opaque types for IDs, custom types for domain concepts
///
/// TYPE HIERARCHY:
/// - DiaryModel: Root state container (current_date, entries, search, edit)
/// - ViewState: UI state machine (MainView | SearchPopup | DatePicker | etc)
/// - DiaryMsg: All possible user/system events (15+ variants)
/// - DisplayEntry: Enriched FoodEntry with display formatting
/// - NutritionTarget: Daily macro goals from FatSecret profile
/// - MacroComparison: Current vs target with status (Under/Met/Over)
import gleam/dict.{type Dict}
import gleam/option.{type Option}
import meal_planner/fatsecret/diary/types as diary_types
import meal_planner/fatsecret/foods/types as foods_types
import shore

// ============================================================================
// Core Model - Screen State Container
// ============================================================================

/// Root state for the FatSecret Diary TUI screen
///
/// Follows Elm Architecture pattern: All state is immutable,
/// updates create new DiaryModel instances.
///
/// INVARIANTS:
/// - current_date is always valid (days since epoch)
/// - entries_by_meal is sorted by meal type (Breakfast -> Lunch -> Dinner -> Snack)
/// - search_state and edit_state are mutually exclusive (enforced by ViewState)
/// - food_cache prevents redundant API calls for recently viewed foods
pub type DiaryModel {
  DiaryModel(
    /// Current date being viewed (days since Unix epoch)
    /// Use diary_types.int_to_date() to convert to YYYY-MM-DD
    current_date: Int,
    /// Food entries organized by meal type
    entries_by_meal: List(MealSection),
    /// Daily nutrition targets from FatSecret profile (if available)
    nutrition_targets: Option(NutritionTarget),
    /// Search popup state (when adding/searching for food)
    search_state: SearchState,
    /// Edit state (when modifying serving size of existing entry)
    edit_state: Option(EditState),
    /// Current UI view mode (determines which screen is shown)
    view_state: ViewState,
    /// Recently accessed foods (reduces API calls)
    food_cache: Dict(String, CachedFood),
    /// Current error message to display (if any)
    error_message: Option(String),
  )
}

// ============================================================================
// Meal Organization
// ============================================================================

/// Food entries grouped by meal type with subtotals
///
/// Each MealSection represents one meal category (Breakfast, Lunch, etc)
/// and contains the entries for that meal plus aggregated nutrition totals.
pub type MealSection {
  MealSection(
    /// Which meal this section represents
    meal_type: diary_types.MealType,
    /// All entries for this meal (chronologically ordered)
    entries: List(DisplayEntry),
    /// Aggregated nutrition totals for this meal
    section_totals: MealTotals,
  )
}

/// Aggregated nutrition totals for a meal section
pub type MealTotals {
  MealTotals(calories: Float, carbohydrate: Float, protein: Float, fat: Float)
}

// ============================================================================
// Display Entry - Enriched FoodEntry with UI Formatting
// ============================================================================

/// FoodEntry enriched with display-ready formatting
///
/// Wraps diary_types.FoodEntry and adds precomputed display strings
/// to avoid formatting logic in view layer.
pub type DisplayEntry {
  DisplayEntry(
    /// Original diary entry from FatSecret API
    entry: diary_types.FoodEntry,
    /// Formatted display text (e.g., "1.5 servings - Grilled Chicken")
    display_text: String,
    /// Formatted macro display (e.g., "250 cal | 30g P | 10g C | 5g F")
    macros_display: String,
  )
}

// ============================================================================
// View State - Impossible State Prevention
// ============================================================================

/// UI state machine enforcing mutually exclusive views
///
/// INVARIANT: Only one ViewState is active at a time.
/// This prevents impossible combinations like:
/// - Editing and deleting simultaneously
/// - Searching while date picker is open
/// - Adding entry while confirming deletion
///
/// STATE TRANSITIONS:
/// MainView <-> SearchPopup (press 'a' to add, Esc to cancel)
/// MainView <-> DatePicker (press 'g' to pick date, Esc/Enter to confirm)
/// MainView <-> EditAmount (press 'e' on entry, Esc/Enter to confirm)
/// MainView <-> ConfirmDelete (press 'd' on entry, y/n to confirm)
pub type ViewState {
  /// Normal diary view with date navigation and entry list
  MainView
  /// Food search popup for adding new entry
  SearchPopup
  /// Date picker modal for jumping to specific date
  DatePicker(date_input: String)
  /// Confirmation dialog for deleting an entry
  ConfirmDelete(entry_id: diary_types.FoodEntryId)
  /// Edit dialog for changing serving size
  EditAmount(edit_state: EditState)
}

// ============================================================================
// Search State - Food Search Popup
// ============================================================================

/// State for food search popup component
///
/// Manages search query, results, and selection index.
/// Reuses components/food_search_popup.gleam for rendering.
pub type SearchState {
  SearchState(
    /// Current search query text
    query: String,
    /// Search results from FatSecret API
    results: List(foods_types.FoodSearchResult),
    /// Currently highlighted result (0-based index)
    selected_index: Int,
    /// Whether search API call is in progress
    is_loading: Bool,
    /// Error message from failed search (if any)
    search_error: Option(String),
  )
}

// ============================================================================
// Edit State - Serving Size Modification
// ============================================================================

/// State for editing an existing diary entry
///
/// Preserves original entry for cancellation and tracks new serving size.
pub type EditState {
  EditState(
    /// Entry being edited
    entry: diary_types.FoodEntry,
    /// New number of servings (user input)
    new_number_of_units: Float,
    /// Original number of servings (for cancel/revert)
    original_number_of_units: Float,
  )
}

// ============================================================================
// Nutrition Targets
// ============================================================================

/// Daily nutrition targets from FatSecret profile
///
/// Used to calculate MacroComparison and display progress bars.
/// Retrieved from profile.get_daily_goals API endpoint.
pub type NutritionTarget {
  NutritionTarget(
    /// Daily calorie goal
    calories: Float,
    /// Daily carbohydrate goal (grams)
    carbohydrate: Float,
    /// Daily protein goal (grams)
    protein: Float,
    /// Daily fat goal (grams)
    fat: Float,
  )
}

// ============================================================================
// Macro Comparison - Current vs Target
// ============================================================================

/// Comparison of current intake vs nutrition targets
///
/// STATUS LOGIC:
/// - Under: current < target - 10%
/// - Met: within ±10% of target
/// - Over: current > target + 10%
pub type MacroComparison {
  MacroComparison(
    /// Current intake for the day
    current: Float,
    /// Daily target from profile
    target: Float,
    /// Percentage of target achieved (current / target * 100)
    percentage: Float,
    /// Status relative to target (Under/Met/Over)
    status: MacroStatus,
  )
}

/// Macro status relative to target
pub type MacroStatus {
  /// Below target (< 90% of target)
  Under
  /// Within target range (90% - 110% of target)
  Met
  /// Exceeds target (> 110% of target)
  Over
}

// ============================================================================
// Food Cache - Reduce API Calls
// ============================================================================

/// Cached food details from FatSecret API
///
/// Stores recently accessed foods to prevent redundant API calls
/// when navigating between days or viewing the same food multiple times.
pub type CachedFood {
  CachedFood(
    /// Food search result
    food: foods_types.FoodSearchResult,
    /// Unix timestamp when cached (for TTL expiration)
    cached_at: Int,
  )
}

// ============================================================================
// Message Types - All Possible Events
// ============================================================================

/// All possible messages/events in the Diary screen
///
/// CATEGORIES:
/// - Date: Navigation between days (Previous/Next/Today/Picker)
/// - Add: Adding new food entries (Search -> Select -> Confirm)
/// - Edit: Modifying existing entries (Change servings)
/// - Delete: Removing entries (Confirm dialog)
/// - Copy: Copying meals between days
/// - Server: Results from FatSecret API calls
/// - UI: User input and error handling
pub type DiaryMsg {
  // === Date Navigation ===
  /// Navigate to previous day ([ key)
  DateNavigatePrevious
  /// Navigate to next day (] key)
  DateNavigateNext
  /// Jump to today (t key)
  DateJumpToToday
  /// Show date picker modal (g key)
  DateShowPicker
  /// Confirm date from picker (Enter in date picker)
  DateConfirmPicker(date_input: String)
  /// Cancel date picker (Esc in date picker)
  DateCancelPicker

  // === Add Entry ===
  /// Start adding entry (show search popup) (a key)
  AddEntryStart
  /// User typed in search box
  SearchQueryChanged(query: String)
  /// Trigger food search API call (Enter in search box)
  SearchFoodStarted
  /// Food search results received from API
  GotFoodSearchResults(Result(List(foods_types.FoodSearchResult), String))
  /// User selected a food from search results (Enter or number key)
  FoodSelected(food: foods_types.FoodSearchResult)
  /// User entered serving size, confirm addition
  ConfirmAddEntry(servings: Float, meal: diary_types.MealType)
  /// Cancel food search (Esc in search popup)
  CancelAddEntry

  // === Edit Entry ===
  /// Start editing entry (e key on entry)
  EditEntryStart(entry: diary_types.FoodEntry)
  /// User changed serving size in edit dialog
  EditEntryServingsChanged(new_servings: Float)
  /// Confirm edit (Enter in edit dialog)
  EditEntryConfirm
  /// Cancel edit (Esc in edit dialog)
  EditEntryCancel

  // === Delete Entry ===
  /// Start delete flow (show confirm dialog) (d key on entry)
  DeleteEntryStart(entry_id: diary_types.FoodEntryId)
  /// Confirm deletion (y key in confirm dialog)
  DeleteEntryConfirm
  /// Cancel deletion (n key in confirm dialog)
  DeleteEntryCancel

  // === Copy Meal ===
  /// Start copying a meal to another day (c key)
  CopyMealStart
  /// User selected source meal type
  CopyMealSelectSource(meal: diary_types.MealType)
  /// User selected destination date
  CopyMealSelectDate(date_int: Int)
  /// User selected destination meal type
  CopyMealSelectDestMeal(meal: diary_types.MealType)
  /// Confirm copy operation
  CopyMealConfirm
  /// Cancel copy operation (Esc)
  CopyMealCancel

  // === Server Responses ===
  /// Fetch entries for current date
  FetchEntriesForDate(date_int: Int)
  /// Received daily entries from API
  GotDailyEntries(Result(List(diary_types.FoodEntry), String))
  /// Received nutrition targets from profile API
  GotNutritionTargets(Result(NutritionTarget, String))
  /// Entry successfully created on server
  EntryCreated(Result(diary_types.FoodEntryId, String))
  /// Entry successfully updated on server
  EntryUpdated(Result(Nil, String))
  /// Entry successfully deleted on server
  EntryDeleted(Result(Nil, String))

  // === UI State ===
  /// Clear current error message
  ClearError
  /// Keyboard input received (for navigation/shortcuts)
  KeyPressed(key: String)
  /// No operation (placeholder)
  NoOp
}

// ============================================================================
// Shore Integration - Effect Type
// ============================================================================

/// Effects returned from update function (Shore framework)
///
/// Shore uses Elm Architecture: update returns (Model, Effect)
/// Effects are interpreted by the runtime to perform side effects.
pub type DiaryEffect {
  /// No side effect
  None
  /// Fetch food entries for a specific date
  FetchEntries(date_int: Int)
  /// Search for foods matching query
  SearchFoods(query: String)
  /// Create new food entry
  CreateEntry(input: diary_types.FoodEntryInput)
  /// Update existing food entry
  UpdateEntry(
    entry_id: diary_types.FoodEntryId,
    update: diary_types.FoodEntryUpdate,
  )
  /// Delete food entry
  DeleteEntry(entry_id: diary_types.FoodEntryId)
  /// Fetch nutrition targets from profile
  FetchNutritionTargets
  /// Batch multiple effects
  Batch(effects: List(DiaryEffect))
}

// ============================================================================
// Initialization
// ============================================================================

/// Create initial DiaryModel for today's date
///
/// INITIAL STATE:
/// - current_date = today (calculated from system time)
/// - entries_by_meal = empty (must fetch from API)
/// - view_state = MainView
/// - search_state = hidden
/// - edit_state = None
/// - food_cache = empty
pub fn init(today_date_int: Int) -> DiaryModel {
  DiaryModel(
    current_date: today_date_int,
    entries_by_meal: [],
    nutrition_targets: option.None,
    search_state: SearchState(
      query: "",
      results: [],
      selected_index: 0,
      is_loading: False,
      search_error: option.None,
    ),
    edit_state: option.None,
    view_state: MainView,
    food_cache: dict.new(),
    error_message: option.None,
  )
}

// ============================================================================
// Helper Functions - Status Calculation
// ============================================================================

/// Calculate macro status based on current/target comparison
///
/// STATUS LOGIC:
/// - Under: current < 0.9 * target
/// - Met: 0.9 * target <= current <= 1.1 * target
/// - Over: current > 1.1 * target
pub fn calculate_macro_status(current: Float, target: Float) -> MacroStatus {
  let lower_bound = target *. 0.9
  let upper_bound = target *. 1.1

  case current <. lower_bound, current >. upper_bound {
    True, _ -> Under
    _, True -> Over
    False, False -> Met
  }
}

/// Build MacroComparison from current and target values
pub fn build_macro_comparison(current: Float, target: Float) -> MacroComparison {
  let percentage = case target >. 0.0 {
    True -> { current /. target } *. 100.0
    False -> 0.0
  }

  MacroComparison(
    current: current,
    target: target,
    percentage: percentage,
    status: calculate_macro_status(current, target),
  )
}

/// Calculate total calories for the day from all meal sections
pub fn calculate_daily_totals(
  sections: List(MealSection),
) -> #(Float, Float, Float, Float) {
  sections
  |> list.fold(#(0.0, 0.0, 0.0, 0.0), fn(acc, section) {
    let #(cal, carb, prot, fat) = acc
    let totals = section.section_totals
    #(
      cal +. totals.calories,
      carb +. totals.carbohydrate,
      prot +. totals.protein,
      fat +. totals.fat,
    )
  })
}

// ============================================================================
// Re-exports from Shore Framework
// ============================================================================

/// Shore Node type for UI rendering
pub type Node(msg) =
  shore.Node(msg)

// ============================================================================
// Import statement cleanup
// ============================================================================

import gleam/list

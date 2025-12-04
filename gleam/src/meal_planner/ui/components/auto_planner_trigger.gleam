/// Auto Planner Trigger Component Module
///
/// This module provides the trigger button and form for initiating the auto meal planner.
/// The component includes:
/// - Trigger button with HTMX attributes for /api/auto-plan endpoint
/// - User profile input form (goals, dietary restrictions)
/// - Loading states with HTMX indicators
/// - Error handling and validation feedback
///
/// All components render as Lustre HTML elements suitable for SSR.
/// All interactivity is handled via HTMX (NO custom JavaScript).
///
/// See: CLAUDE.md (JavaScript Prohibition - CRITICAL RULE)
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/types.{
  type ActivityLevel, type Goal, Active, Gain, Lose, Maintain, Moderate,
  Sedentary,
}

// ===================================================================
// TYPE DEFINITIONS
// ===================================================================

/// Auto planner configuration inputs
pub type AutoPlannerConfig {
  AutoPlannerConfig(
    goal: Option(Goal),
    activity_level: Option(ActivityLevel),
    dietary_restrictions: List(String),
    meals_per_day: Int,
  )
}

/// Loading state for the auto planner
pub type LoadingState {
  Idle
  Loading
  Success
  Error(String)
}

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Convert Goal to string identifier
fn goal_to_string(goal: Goal) -> String {
  case goal {
    Gain -> "gain"
    Maintain -> "maintain"
    Lose -> "lose"
  }
}

/// Convert ActivityLevel to string identifier
fn activity_level_to_string(level: ActivityLevel) -> String {
  case level {
    Sedentary -> "sedentary"
    Moderate -> "moderate"
    Active -> "active"
  }
}

/// Convert Goal to human-readable label
fn goal_to_label(goal: Goal) -> String {
  case goal {
    Gain -> "Gain Muscle"
    Maintain -> "Maintain Weight"
    Lose -> "Lose Weight"
  }
}

/// Convert ActivityLevel to human-readable label
fn activity_level_to_label(level: ActivityLevel) -> String {
  case level {
    Sedentary -> "Sedentary (little exercise)"
    Moderate -> "Moderate (exercise 3-5 days/week)"
    Active -> "Active (exercise 6-7 days/week)"
  }
}

/// Build CSS classes for loading button state
fn button_loading_classes(loading: LoadingState) -> String {
  let base = "btn btn-primary btn-lg"
  case loading {
    Loading -> base <> " btn-loading"
    _ -> base
  }
}

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Render auto planner trigger button with HTMX
///
/// Features:
/// - POST request to /api/auto-plan
/// - Includes form data from #auto-planner-form
/// - Loading indicator during request
/// - Disabled during loading state
/// - Success/error feedback via HTMX response
///
/// HTMX Attributes:
/// - hx-post: POST to /api/auto-plan endpoint
/// - hx-target: #auto-plan-result (displays plan result)
/// - hx-swap: innerHTML (replaces result content)
/// - hx-include: #auto-planner-form (includes all form inputs)
/// - hx-indicator: #auto-plan-loading (shows loading state)
///
/// Renders:
/// <button class="btn btn-primary btn-lg"
///         type="button"
///         hx-post="/api/auto-plan"
///         hx-target="#auto-plan-result"
///         hx-swap="innerHTML"
///         hx-include="#auto-planner-form"
///         hx-indicator="#auto-plan-loading"
///         aria-label="Generate meal plan">
///   Generate Meal Plan
/// </button>
pub fn render_trigger_button(loading: LoadingState) -> element.Element(msg) {
  let classes = button_loading_classes(loading)
  let disabled = case loading {
    Loading -> True
    _ -> False
  }

  html.button(
    [
      attribute.class(classes),
      attribute.type_("button"),
      attribute.disabled(disabled),
      attribute.attribute("aria-label", "Generate meal plan"),
      // HTMX attributes for auto-plan endpoint
      attribute.attribute("hx-post", "/api/auto-plan"),
      attribute.attribute("hx-target", "#auto-plan-result"),
      attribute.attribute("hx-swap", "innerHTML"),
      attribute.attribute("hx-include", "#auto-planner-form"),
      attribute.attribute("hx-indicator", "#auto-plan-loading"),
    ],
    [element.text("Generate Meal Plan")],
  )
}

/// Render goal selection radio buttons
///
/// Features:
/// - Radio buttons for Gain, Maintain, Lose
/// - Selected state based on config
/// - Proper name attribute for form submission
/// - Accessible labels
///
/// Renders:
/// <div class="form-group">
///   <label class="form-label">Fitness Goal</label>
///   <div class="radio-group">
///     <label class="radio-label">
///       <input type="radio" name="goal" value="gain" />
///       Gain Muscle
///     </label>
///     ...
///   </div>
/// </div>
pub fn render_goal_selection(selected: Option(Goal)) -> element.Element(msg) {
  let goals = [Gain, Maintain, Lose]

  let radio_buttons =
    list.map(goals, fn(goal) {
      let is_selected = case selected {
        Some(g) if g == goal -> True
        _ -> False
      }

      html.label([attribute.class("radio-label")], [
        html.input([
          attribute.type_("radio"),
          attribute.name("goal"),
          attribute.value(goal_to_string(goal)),
          attribute.checked(is_selected),
          attribute.attribute("aria-label", goal_to_label(goal)),
        ]),
        element.text(" " <> goal_to_label(goal)),
      ])
    })

  html.div([attribute.class("form-group")], [
    html.label([attribute.class("form-label")], [element.text("Fitness Goal")]),
    html.div(
      [
        attribute.class("radio-group"),
        attribute.attribute("role", "radiogroup"),
      ],
      radio_buttons,
    ),
  ])
}

/// Render activity level selection radio buttons
///
/// Features:
/// - Radio buttons for Sedentary, Moderate, Active
/// - Selected state based on config
/// - Descriptive labels with activity details
/// - Proper form submission attributes
///
/// Renders similar structure to render_goal_selection
pub fn render_activity_level_selection(
  selected: Option(ActivityLevel),
) -> element.Element(msg) {
  let levels = [Sedentary, Moderate, Active]

  let radio_buttons =
    list.map(levels, fn(level) {
      let is_selected = case selected {
        Some(l) if l == level -> True
        _ -> False
      }

      html.label([attribute.class("radio-label")], [
        html.input([
          attribute.type_("radio"),
          attribute.name("activity_level"),
          attribute.value(activity_level_to_string(level)),
          attribute.checked(is_selected),
          attribute.attribute("aria-label", activity_level_to_label(level)),
        ]),
        element.text(" " <> activity_level_to_label(level)),
      ])
    })

  html.div([attribute.class("form-group")], [
    html.label([attribute.class("form-label")], [
      element.text("Activity Level"),
    ]),
    html.div(
      [
        attribute.class("radio-group"),
        attribute.attribute("role", "radiogroup"),
      ],
      radio_buttons,
    ),
  ])
}

/// Render dietary restrictions multi-select checkboxes
///
/// Features:
/// - Common dietary restrictions (vegetarian, vegan, gluten-free, etc.)
/// - Multi-select via checkboxes
/// - Selected restrictions highlighted
/// - Array name for form submission
///
/// Renders:
/// <div class="form-group">
///   <label class="form-label">Dietary Restrictions</label>
///   <div class="checkbox-group">
///     <label class="checkbox-label">
///       <input type="checkbox" name="restrictions[]" value="vegetarian" />
///       Vegetarian
///     </label>
///     ...
///   </div>
/// </div>
pub fn render_dietary_restrictions(
  selected: List(String),
) -> element.Element(msg) {
  let restrictions = [
    #("vegetarian", "Vegetarian"),
    #("vegan", "Vegan"),
    #("gluten-free", "Gluten-Free"),
    #("dairy-free", "Dairy-Free"),
    #("low-fodmap", "Low FODMAP"),
    #("keto", "Ketogenic"),
  ]

  let checkboxes =
    list.map(restrictions, fn(restriction) {
      let #(value, label) = restriction
      let is_selected = list.contains(selected, value)

      html.label([attribute.class("checkbox-label")], [
        html.input([
          attribute.type_("checkbox"),
          attribute.name("restrictions"),
          attribute.value(value),
          attribute.checked(is_selected),
          attribute.attribute("aria-label", label),
        ]),
        element.text(" " <> label),
      ])
    })

  html.div([attribute.class("form-group")], [
    html.label([attribute.class("form-label")], [
      element.text("Dietary Restrictions (Optional)"),
    ]),
    html.div([attribute.class("checkbox-group")], checkboxes),
  ])
}

/// Render meals per day number input
///
/// Features:
/// - Number input with min/max validation
/// - Default value of 3 meals
/// - Step of 1 (whole meals only)
/// - Accessible label
///
/// Renders:
/// <div class="form-group">
///   <label for="meals-per-day" class="form-label">Meals Per Day</label>
///   <input type="number" id="meals-per-day" name="meals_per_day"
///          class="input" value="3" min="1" max="6" step="1" />
/// </div>
pub fn render_meals_per_day(value: Int) -> element.Element(msg) {
  html.div([attribute.class("form-group")], [
    html.label([attribute.for("meals-per-day"), attribute.class("form-label")], [
      element.text("Meals Per Day"),
    ]),
    html.input([
      attribute.type_("number"),
      attribute.id("meals-per-day"),
      attribute.name("meals_per_day"),
      attribute.class("input"),
      attribute.value(string.inspect(value)),
      attribute.attribute("min", "1"),
      attribute.attribute("max", "6"),
      attribute.attribute("step", "1"),
      attribute.attribute("aria-label", "Number of meals per day"),
    ]),
  ])
}

/// Render loading indicator with HTMX
///
/// Features:
/// - Hidden by default (shown via hx-indicator)
/// - Loading spinner animation
/// - Accessible status message
/// - ARIA live region for screen readers
///
/// Renders:
/// <div id="auto-plan-loading" class="htmx-indicator" role="status" aria-live="polite">
///   <div class="loading-spinner"></div>
///   <span class="loading-text">Generating your personalized meal plan...</span>
/// </div>
pub fn render_loading_indicator() -> element.Element(msg) {
  html.div(
    [
      attribute.id("auto-plan-loading"),
      attribute.class("htmx-indicator"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-live", "polite"),
    ],
    [
      html.div([attribute.class("loading-spinner")], []),
      html.span([attribute.class("loading-text")], [
        element.text("Generating your personalized meal plan..."),
      ]),
    ],
  )
}

/// Render error message display
///
/// Features:
/// - Red error styling
/// - Icon for visual feedback
/// - Dismissable (can add dismiss button)
/// - Accessible error role
///
/// Renders:
/// <div class="error-message" role="alert" aria-live="assertive">
///   <div class="error-icon">⚠</div>
///   <div class="error-text">Error message here</div>
/// </div>
pub fn render_error(message: String) -> element.Element(msg) {
  html.div(
    [
      attribute.class("error-message"),
      attribute.attribute("role", "alert"),
      attribute.attribute("aria-live", "assertive"),
    ],
    [
      html.div([attribute.class("error-icon")], [element.text("⚠")]),
      html.div([attribute.class("error-text")], [element.text(message)]),
    ],
  )
}

/// Render success message display
///
/// Features:
/// - Green success styling
/// - Checkmark icon
/// - Accessible success role
/// - Auto-dismiss after delay (via HTMX)
///
/// Renders:
/// <div class="success-message" role="status" aria-live="polite">
///   <div class="success-icon">✓</div>
///   <div class="success-text">Success message here</div>
/// </div>
pub fn render_success(message: String) -> element.Element(msg) {
  html.div(
    [
      attribute.class("success-message"),
      attribute.attribute("role", "status"),
      attribute.attribute("aria-live", "polite"),
    ],
    [
      html.div([attribute.class("success-icon")], [element.text("✓")]),
      html.div([attribute.class("success-text")], [element.text(message)]),
    ],
  )
}

/// Render complete auto planner form with all inputs
///
/// Features:
/// - Goal selection
/// - Activity level selection
/// - Dietary restrictions
/// - Meals per day
/// - Trigger button
/// - Loading indicator
/// - Result container for HTMX response
///
/// Usage:
/// ```gleam
/// render_auto_planner_form(AutoPlannerConfig(
///   goal: Some(Maintain),
///   activity_level: Some(Moderate),
///   dietary_restrictions: [],
///   meals_per_day: 3
/// ), Idle)
/// ```
///
/// Renders:
/// <div class="auto-planner-container">
///   <form id="auto-planner-form">
///     {goal selection}
///     {activity level selection}
///     {dietary restrictions}
///     {meals per day}
///     {trigger button}
///     {loading indicator}
///   </form>
///   <div id="auto-plan-result" class="auto-plan-result"></div>
/// </div>
pub fn render_auto_planner_form(
  config: AutoPlannerConfig,
  loading: LoadingState,
) -> element.Element(msg) {
  html.div([attribute.class("auto-planner-container")], [
    html.form(
      [attribute.id("auto-planner-form"), attribute.class("auto-planner-form")],
      [
        // Form header
        html.div([attribute.class("form-header")], [
          html.h2([attribute.class("form-title")], [
            element.text("Auto Meal Planner"),
          ]),
          html.p([attribute.class("form-description")], [
            element.text(
              "Let us create a personalized meal plan based on your goals and preferences.",
            ),
          ]),
        ]),
        // Form inputs
        render_goal_selection(config.goal),
        render_activity_level_selection(config.activity_level),
        render_dietary_restrictions(config.dietary_restrictions),
        render_meals_per_day(config.meals_per_day),
        // Action buttons and loading
        html.div([attribute.class("form-actions")], [
          render_trigger_button(loading),
          render_loading_indicator(),
        ]),
      ],
    ),
    // Result container (populated by HTMX response)
    html.div(
      [attribute.id("auto-plan-result"), attribute.class("auto-plan-result")],
      [],
    ),
  ])
}

/// Render compact trigger button (for dashboard/page headers)
///
/// Features:
/// - Smaller, icon-based button
/// - Opens modal or navigates to planner form
/// - HTMX-powered modal display
///
/// HTMX Attributes:
/// - hx-get: GET /auto-plan/form (loads form in modal)
/// - hx-target: #modal-container
/// - hx-swap: innerHTML
///
/// Renders:
/// <button class="btn btn-primary btn-sm"
///         hx-get="/auto-plan/form"
///         hx-target="#modal-container"
///         hx-swap="innerHTML"
///         aria-label="Open auto meal planner">
///   🤖 Auto Plan
/// </button>
pub fn render_compact_trigger() -> element.Element(msg) {
  html.button(
    [
      attribute.class("btn btn-primary btn-sm"),
      attribute.type_("button"),
      attribute.attribute("aria-label", "Open auto meal planner"),
      // HTMX attributes for modal form
      attribute.attribute("hx-get", "/auto-plan/form"),
      attribute.attribute("hx-target", "#modal-container"),
      attribute.attribute("hx-swap", "innerHTML"),
    ],
    [element.text("🤖 Auto Plan")],
  )
}

// ===================================================================
// DEFAULT CONFIGURATIONS
// ===================================================================

/// Create default auto planner configuration
///
/// Returns a configuration with sensible defaults:
/// - Goal: Maintain
/// - Activity: Moderate
/// - No dietary restrictions
/// - 3 meals per day
pub fn default_config() -> AutoPlannerConfig {
  AutoPlannerConfig(
    goal: Some(Maintain),
    activity_level: Some(Moderate),
    dietary_restrictions: [],
    meals_per_day: 3,
  )
}

/// Create empty auto planner configuration
///
/// Returns a configuration with no selections
/// (forces user to make choices)
pub fn empty_config() -> AutoPlannerConfig {
  AutoPlannerConfig(
    goal: None,
    activity_level: None,
    dietary_restrictions: [],
    meals_per_day: 3,
  )
}

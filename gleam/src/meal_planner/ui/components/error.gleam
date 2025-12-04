/// Error State Components Module
///
/// This module provides error state components for handling failures:
/// - Error alerts (inline and page-level)
/// - Error boundaries
/// - Network error displays
/// - Retry mechanisms
/// - Empty state displays
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Error States)
import lustre/attribute
import lustre/element
import lustre/element/html

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS - ERROR ALERTS
// ===================================================================

/// Inline error message - for form field errors
///
/// Usage:
/// ```gleam
/// html.div([attribute.class("form-group")], [
///   html.input([attribute.class("input-error")]),
///   error_inline("Recipe name is required")
/// ])
/// ```
pub fn error_inline(message: String) -> element.Element(msg) {
  html.p([attribute.class("error-inline")], [
    html.span([attribute.class("error-icon")], [element.text("⚠")]),
    element.text(" " <> message),
  ])
}

/// Error alert - dismissable error notification
///
/// Usage:
/// ```gleam
/// error_alert(
///   message: "Failed to save recipe",
///   dismissable: True,
///   on_dismiss: Some("#")
/// )
/// ```
pub fn error_alert(
  message message: String,
  dismissable dismissable: Bool,
  on_dismiss dismiss_url: Option(String),
) -> element.Element(msg) {
  let close_button = case dismissable, dismiss_url {
    True, Some(url) -> [
      html.a(
        [attribute.href(url), attribute.class("alert-close")],
        [element.text("×")],
      ),
    ]
    _, _ -> []
  }

  html.div([attribute.class("alert alert-danger")], [
    html.div([attribute.class("alert-content")], [
      html.span([attribute.class("alert-icon")], [element.text("✕")]),
      html.span([attribute.class("alert-message")], [element.text(message)]),
    ]),
    ..close_button
  ])
}

/// Success alert - for successful operations
///
/// Usage:
/// ```gleam
/// success_alert("Recipe saved successfully!", True, Some("#"))
/// ```
pub fn success_alert(
  message message: String,
  dismissable dismissable: Bool,
  on_dismiss dismiss_url: Option(String),
) -> element.Element(msg) {
  let close_button = case dismissable, dismiss_url {
    True, Some(url) -> [
      html.a(
        [attribute.href(url), attribute.class("alert-close")],
        [element.text("×")],
      ),
    ]
    _, _ -> []
  }

  html.div([attribute.class("alert alert-success")], [
    html.div([attribute.class("alert-content")], [
      html.span([attribute.class("alert-icon")], [element.text("✓")]),
      html.span([attribute.class("alert-message")], [element.text(message)]),
    ]),
    ..close_button
  ])
}

/// Warning alert - for warnings and cautions
///
/// Usage:
/// ```gleam
/// warning_alert("This recipe has high sodium", False, None)
/// ```
pub fn warning_alert(
  message message: String,
  dismissable dismissable: Bool,
  on_dismiss dismiss_url: Option(String),
) -> element.Element(msg) {
  let close_button = case dismissable, dismiss_url {
    True, Some(url) -> [
      html.a(
        [attribute.href(url), attribute.class("alert-close")],
        [element.text("×")],
      ),
    ]
    _, _ -> []
  }

  html.div([attribute.class("alert alert-warning")], [
    html.div([attribute.class("alert-content")], [
      html.span([attribute.class("alert-icon")], [element.text("⚡")]),
      html.span([attribute.class("alert-message")], [element.text(message)]),
    ]),
    ..close_button
  ])
}

/// Info alert - for informational messages
///
/// Usage:
/// ```gleam
/// info_alert("Recipes are automatically saved", True, Some("#"))
/// ```
pub fn info_alert(
  message message: String,
  dismissable dismissable: Bool,
  on_dismiss dismiss_url: Option(String),
) -> element.Element(msg) {
  let close_button = case dismissable, dismiss_url {
    True, Some(url) -> [
      html.a(
        [attribute.href(url), attribute.class("alert-close")],
        [element.text("×")],
      ),
    ]
    _, _ -> []
  }

  html.div([attribute.class("alert alert-info")], [
    html.div([attribute.class("alert-content")], [
      html.span([attribute.class("alert-icon")], [element.text("ℹ")]),
      html.span([attribute.class("alert-message")], [element.text(message)]),
    ]),
    ..close_button
  ])
}

// ===================================================================
// ERROR PAGES
// ===================================================================

/// Full page error - for critical errors
///
/// Usage:
/// ```gleam
/// error_page(
///   title: "500 Server Error",
///   message: "Something went wrong. Please try again later.",
///   retry_url: Some("/dashboard")
/// )
/// ```
pub fn error_page(
  title title: String,
  message message: String,
  retry_url retry_url: Option(String),
) -> element.Element(msg) {
  let action_button = case retry_url {
    Some(url) -> [
      html.a([attribute.href(url), attribute.class("btn btn-primary")], [
        element.text("Try Again"),
      ]),
    ]
    None -> []
  }

  html.div([attribute.class("error-page")], [
    html.div([attribute.class("error-page-content")], [
      html.div([attribute.class("error-icon-large")], [element.text("⚠")]),
      html.h1([attribute.class("error-title")], [element.text(title)]),
      html.p([attribute.class("error-message")], [element.text(message)]),
      html.div([attribute.class("error-actions")], [
        html.a([attribute.href("/"), attribute.class("btn btn-secondary")], [
          element.text("Go Home"),
        ]),
        ..action_button
      ]),
    ]),
  ])
}

/// 404 Not Found page
///
/// Usage:
/// ```gleam
/// not_found_page()
/// ```
pub fn not_found_page() -> element.Element(msg) {
  html.div([attribute.class("error-page")], [
    html.div([attribute.class("error-page-content")], [
      html.h1([attribute.class("error-code")], [element.text("404")]),
      html.h2([attribute.class("error-title")], [element.text("Page Not Found")]),
      html.p([attribute.class("error-message")], [
        element.text(
          "The page you're looking for doesn't exist or has been moved.",
        ),
      ]),
      html.div([attribute.class("error-actions")], [
        html.a([attribute.href("/"), attribute.class("btn btn-primary")], [
          element.text("Go Home"),
        ]),
        html.a([attribute.href("/recipes"), attribute.class("btn btn-secondary")], [
          element.text("Browse Recipes"),
        ]),
      ]),
    ]),
  ])
}

// ===================================================================
// NETWORK ERROR DISPLAYS
// ===================================================================

/// Network error message - for API failures
///
/// Usage:
/// ```gleam
/// network_error(
///   message: "Failed to load recipes",
///   retry_action: Some("/api/recipes")
/// )
/// ```
pub fn network_error(
  message message: String,
  retry_action retry_url: Option(String),
) -> element.Element(msg) {
  let retry_button = case retry_url {
    Some(url) -> [
      html.a([attribute.href(url), attribute.class("btn btn-sm btn-primary")], [
        element.text("Retry"),
      ]),
    ]
    None -> []
  }

  html.div([attribute.class("network-error")], [
    html.div([attribute.class("network-error-icon")], [element.text("📡")]),
    html.p([attribute.class("network-error-message")], [element.text(message)]),
    html.div([attribute.class("network-error-actions")], retry_button),
  ])
}

/// Offline indicator - shows when network is unavailable
///
/// Usage:
/// ```gleam
/// offline_indicator()
/// ```
pub fn offline_indicator() -> element.Element(msg) {
  html.div([attribute.class("offline-indicator")], [
    html.span([attribute.class("offline-icon")], [element.text("📡")]),
    html.span([attribute.class("offline-text")], [
      element.text("You are offline"),
    ]),
  ])
}

// ===================================================================
// EMPTY STATES
// ===================================================================

/// Empty state - for empty search results or lists
///
/// Usage:
/// ```gleam
/// empty_state(
///   icon: "🔍",
///   title: "No recipes found",
///   message: "Try adjusting your search filters",
///   action: Some(EmptyAction("Browse All Recipes", "/recipes"))
/// )
/// ```
pub fn empty_state(
  icon icon: String,
  title title: String,
  message message: String,
  action action: Option(EmptyAction),
) -> element.Element(msg) {
  let action_button = case action {
    Some(EmptyAction(label, url)) -> [
      html.a([attribute.href(url), attribute.class("btn btn-primary")], [
        element.text(label),
      ]),
    ]
    None -> []
  }

  html.div([attribute.class("empty-state")], [
    html.div([attribute.class("empty-state-icon")], [element.text(icon)]),
    html.h3([attribute.class("empty-state-title")], [element.text(title)]),
    html.p([attribute.class("empty-state-message")], [element.text(message)]),
    html.div([attribute.class("empty-state-actions")], action_button),
  ])
}

/// No search results state
///
/// Usage:
/// ```gleam
/// no_search_results("chicken")
/// ```
pub fn no_search_results(query: String) -> element.Element(msg) {
  empty_state(
    icon: "🔍",
    title: "No results found",
    message: "No foods matching \"" <> query <> "\" were found. Try a different search term.",
    action: None,
  )
}

/// Empty daily log state
///
/// Usage:
/// ```gleam
/// empty_daily_log()
/// ```
pub fn empty_daily_log() -> element.Element(msg) {
  empty_state(
    icon: "📝",
    title: "No meals logged today",
    message: "Start tracking your nutrition by logging your first meal.",
    action: Some(EmptyAction("Log Meal", "/log")),
  )
}

/// No recipes state
///
/// Usage:
/// ```gleam
/// no_recipes()
/// ```
pub fn no_recipes() -> element.Element(msg) {
  empty_state(
    icon: "🍽",
    title: "No recipes yet",
    message: "Create your first recipe to start meal planning.",
    action: Some(EmptyAction("Create Recipe", "/recipes/new")),
  )
}

// ===================================================================
// ERROR BOUNDARIES
// ===================================================================

/// Error boundary wrapper - catches and displays errors
///
/// Usage:
/// ```gleam
/// error_boundary(
///   content: recipe_form(),
///   fallback: error_fallback("Failed to load form")
/// )
/// ```
pub fn error_boundary(
  content content: element.Element(msg),
  fallback fallback: element.Element(msg),
  has_error has_error: Bool,
) -> element.Element(msg) {
  case has_error {
    True -> fallback
    False -> content
  }
}

/// Error fallback content
///
/// Usage:
/// ```gleam
/// error_fallback("Failed to load content")
/// ```
pub fn error_fallback(message: String) -> element.Element(msg) {
  html.div([attribute.class("error-boundary-fallback")], [
    html.div([attribute.class("error-icon")], [element.text("⚠")]),
    html.p([], [element.text(message)]),
    html.a([attribute.href("/"), attribute.class("btn btn-secondary")], [
      element.text("Go Home"),
    ]),
  ])
}

// ===================================================================
// TYPES
// ===================================================================

/// Action for empty states
pub type EmptyAction {
  EmptyAction(label: String, url: String)
}

/// Option type alias for convenience
pub type Option(a) {
  Some(a)
  None
}

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
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/ui/error_messages.{type ErrorMessage, type Severity}

// ===================================================================
// ENHANCED ERROR MESSAGES WITH SUGGESTIONS
// ===================================================================

/// Rich error display with title, message, suggestions, and actions
///
/// Usage:
/// ```gleam
/// let error_msg = error_messages.from_storage_error(storage_error)
/// rich_error_display(error_msg, show_technical: False)
/// ```
pub fn rich_error_display(
  error: ErrorMessage,
  show_technical show_technical: Bool,
) -> element.Element(msg) {
  let class_name =
    "alert " <> error_messages.severity_class(error.severity) <> " rich-error"
  let icon_text = error_messages.severity_icon(error.severity)

  let suggestions_html = case error.suggestions {
    [] -> []
    suggestions -> [
      html.div([attribute.class("error-suggestions")], [
        html.p([attribute.class("suggestions-title")], [
          element.text("What can you do:"),
        ]),
        html.ul(
          [attribute.class("suggestions-list")],
          list.map(suggestions, fn(suggestion) {
            html.li([], [element.text(suggestion)])
          }),
        ),
      ]),
    ]
  }

  let retry_button = case error.retry_available, error.retry_url {
    True, Some(url) -> [
      html.a([attribute.href(url), attribute.class("btn btn-sm btn-primary")], [
        element.text("Try Again"),
      ]),
    ]
    True, None -> [
      html.button([attribute.class("btn btn-sm btn-primary")], [
        element.text("Retry"),
      ]),
    ]
    False, _ -> []
  }

  let technical_details = case show_technical, error.technical_details {
    True, Some(details) -> [
      html.details([attribute.class("technical-details")], [
        html.summary([], [element.text("Technical Details")]),
        html.pre([attribute.class("technical-details-content")], [
          element.text(details),
        ]),
      ]),
    ]
    _, _ -> []
  }

  html.div([attribute.class(class_name)], [
    html.div([attribute.class("alert-header")], [
      html.span([attribute.class("alert-icon-large")], [element.text(icon_text)]),
      html.h3([attribute.class("alert-title")], [element.text(error.title)]),
    ]),
    html.div([attribute.class("alert-body")], [
      html.p([attribute.class("alert-message")], [element.text(error.message)]),
      ..list.flatten([suggestions_html, technical_details])
    ]),
    html.div([attribute.class("alert-actions")], retry_button),
  ])
}

/// Compact error display for inline/form errors
///
/// Usage:
/// ```gleam
/// let error_msg = error_messages.invalid_input_error("Name is required")
/// compact_error_display(error_msg)
/// ```
pub fn compact_error_display(error: ErrorMessage) -> element.Element(msg) {
  let class_name =
    "alert " <> error_messages.severity_class(error.severity) <> " compact-error"
  let icon_text = error_messages.severity_icon(error.severity)

  html.div([attribute.class(class_name)], [
    html.span([attribute.class("alert-icon")], [element.text(icon_text)]),
    html.span([attribute.class("alert-message")], [
      element.text(error.title <> ": " <> error.message),
    ]),
  ])
}

/// Toast notification for transient errors
///
/// Usage:
/// ```gleam
/// let error_msg = error_messages.network_timeout()
/// error_toast(error_msg, duration: 5000)
/// ```
pub fn error_toast(
  error: ErrorMessage,
  duration duration_ms: Int,
) -> element.Element(msg) {
  let class_name =
    "toast " <> error_messages.severity_class(error.severity)
  let icon_text = error_messages.severity_icon(error.severity)

  html.div(
    [
      attribute.class(class_name),
      attribute.attribute("data-duration", int_to_string(duration_ms)),
      attribute.attribute("role", "alert"),
    ],
    [
      html.span([attribute.class("toast-icon")], [element.text(icon_text)]),
      html.div([attribute.class("toast-content")], [
        html.strong([attribute.class("toast-title")], [element.text(error.title)]),
        html.p([attribute.class("toast-message")], [element.text(error.message)]),
      ]),
      html.button(
        [attribute.class("toast-close"), attribute.attribute("aria-label", "Close")],
        [element.text("×")],
      ),
    ],
  )
}

/// Modal dialog for critical errors
///
/// Usage:
/// ```gleam
/// let error_msg = error_messages.server_error()
/// error_modal(error_msg, is_open: True)
/// ```
pub fn error_modal(
  error: ErrorMessage,
  is_open is_open: Bool,
) -> element.Element(msg) {
  let modal_class = case is_open {
    True -> "modal modal-open"
    False -> "modal"
  }

  let icon_text = error_messages.severity_icon(error.severity)
  let severity_color = error_messages.severity_color(error.severity)

  html.div([attribute.class(modal_class)], [
    html.div([attribute.class("modal-overlay")], []),
    html.div([attribute.class("modal-content error-modal")], [
      html.div(
        [
          attribute.class("modal-header"),
          attribute.style("border-color", severity_color),
        ],
        [
          html.div([attribute.class("modal-icon")], [
            html.span(
              [
                attribute.class("icon-circle"),
                attribute.style("background-color", severity_color),
              ],
              [element.text(icon_text)],
            ),
          ]),
          html.h2([attribute.class("modal-title")], [element.text(error.title)]),
        ],
      ),
      html.div([attribute.class("modal-body")], [
        html.p([attribute.class("modal-message")], [element.text(error.message)]),
        case error.suggestions {
          [] -> element.none()
          suggestions ->
            html.div([attribute.class("modal-suggestions")], [
              html.p([attribute.class("suggestions-label")], [
                element.text("Try these steps:"),
              ]),
              html.ul(
                [],
                list.map(suggestions, fn(s) { html.li([], [element.text(s)]) }),
              ),
            ])
        },
      ]),
      html.div(
        [attribute.class("modal-footer")],
        case error.retry_available, error.retry_url {
          True, Some(url) -> [
            html.a(
              [attribute.href(url), attribute.class("btn btn-primary")],
              [element.text("Try Again")],
            ),
            html.button([attribute.class("btn btn-secondary")], [
              element.text("Cancel"),
            ]),
          ]
          _, _ -> [
            html.button([attribute.class("btn btn-primary")], [
              element.text("OK"),
            ]),
          ]
        },
      ),
    ]),
  ])
}

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

/// Option type alias for convenience (re-exported from gleam/option)
/// Note: Already imported from gleam/option

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Convert integer to string (for attributes)
fn int_to_string(n: Int) -> String {
  case n {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> int_to_string_generic(n)
  }
}

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string_generic(n: Int) -> String

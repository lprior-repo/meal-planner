/// Error Boundary Components Module
///
/// This module provides error boundary wrappers and recovery mechanisms for
/// handling errors gracefully in the Lustre application:
/// - Form boundaries with validation error handling
/// - Fetch boundaries with retry logic for API calls
/// - Route boundaries for navigation errors
/// - Component boundaries for generic component failures
/// - Fallback UI for all error types
///
/// Error boundaries catch errors at render time and display fallback UI,
/// preventing the entire app from crashing when a component fails.
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Error Boundaries)
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/element
import lustre/element/html

// ===================================================================
// ERROR TYPES
// ===================================================================

/// Error severity levels for different types of errors
pub type ErrorSeverity {
  /// Minor error, user can continue with degraded functionality
  Minor
  /// Moderate error, some features unavailable but app usable
  Moderate
  /// Severe error, major functionality broken but app accessible
  Severe
  /// Critical error, app cannot function properly
  Critical
}

/// Error categories for different error sources
pub type ErrorCategory {
  /// Network/API communication errors
  NetworkError
  /// Form validation errors
  ValidationError
  /// State management errors
  StateError
  /// Component rendering errors
  RenderError
  /// Routing/navigation errors
  RouteError
  /// Data parsing/transformation errors
  DataError
  /// Authentication/authorization errors
  AuthError
  /// Unknown or uncategorized errors
  UnknownError
}

/// Comprehensive error information
pub type BoundaryError {
  BoundaryError(
    message: String,
    category: ErrorCategory,
    severity: ErrorSeverity,
    details: Option(String),
    recoverable: Bool,
    retry_action: Option(String),
  )
}

/// Error boundary state - tracks if boundary has caught an error
pub type BoundaryState {
  /// No error, render content normally
  Ok
  /// Error caught, render fallback UI
  Error(BoundaryError)
}

/// Recovery strategy for error boundaries
pub type RecoveryStrategy {
  /// Show retry button to attempt operation again
  AllowRetry
  /// Redirect to safe route
  Redirect(String)
  /// Show fallback content without recovery
  ShowFallback
  /// Reset to default state
  Reset
}

// ===================================================================
// FORM BOUNDARY
// ===================================================================

/// Form boundary wrapper - catches validation and submission errors
///
/// Wraps forms with error handling for validation failures, network errors
/// during submission, and provides user-friendly error messages.
///
/// Usage:
/// ```gleam
/// form_boundary(
///   state: Ok,
///   content: recipe_form(),
///   on_error: fn(error) { show_form_error(error) }
/// )
/// ```
pub fn form_boundary(
  state state: BoundaryState,
  content content: element.Element(msg),
  on_error error_handler: fn(BoundaryError) -> element.Element(msg),
) -> element.Element(msg) {
  case state {
    Ok -> content
    Error(error) -> {
      html.div([attribute.class("form-boundary")], [
        error_handler(error),
        case error.recoverable {
          True -> retry_button(error.retry_action)
          False -> element.none()
        },
      ])
    }
  }
}

/// Form validation error display
///
/// Shows validation errors in a user-friendly format with field-specific
/// error messages and overall form status.
///
/// Usage:
/// ```gleam
/// form_validation_error(
///   errors: [("name", "Recipe name is required"), ("servings", "Must be > 0")],
///   message: "Please fix the errors below"
/// )
/// ```
pub fn form_validation_error(
  errors errors: List(#(String, String)),
  message message: String,
) -> element.Element(msg) {
  html.div([attribute.class("form-validation-error")], [
    html.div([attribute.class("alert alert-danger")], [
      html.div([attribute.class("alert-content")], [
        html.span([attribute.class("alert-icon")], [element.text("⚠")]),
        html.span([attribute.class("alert-message")], [element.text(message)]),
      ]),
    ]),
    html.ul([attribute.class("validation-error-list")], {
      list.map(errors, fn(error) {
        let #(field, msg) = error
        html.li([attribute.class("validation-error-item")], [
          html.strong([], [element.text(field <> ": ")]),
          element.text(msg),
        ])
      })
    }),
  ])
}

// ===================================================================
// FETCH BOUNDARY
// ===================================================================

/// Fetch boundary wrapper - catches API errors with retry logic
///
/// Wraps async API calls with error handling, retry mechanisms, and
/// loading states. Provides user-friendly error messages for network
/// failures and server errors.
///
/// Usage:
/// ```gleam
/// fetch_boundary(
///   state: Error(network_error),
///   content: recipe_list(recipes),
///   loading: loading_skeleton(),
///   retry_url: Some("/api/recipes")
/// )
/// ```
pub fn fetch_boundary(
  state state: BoundaryState,
  content content: element.Element(msg),
  loading: element.Element(msg),
  retry_url retry_url: Option(String),
) -> element.Element(msg) {
  case state {
    Ok -> content
    Error(error) -> {
      html.div([attribute.class("fetch-boundary")], [
        fetch_error_display(error, retry_url),
      ])
    }
  }
}

/// API error display with retry logic
///
/// Shows network/API errors with contextual information and retry options.
/// Includes different messaging for different HTTP status codes.
///
/// Usage:
/// ```gleam
/// fetch_error_display(
///   error: BoundaryError(...),
///   retry_url: Some("/api/recipes")
/// )
/// ```
pub fn fetch_error_display(
  error error: BoundaryError,
  retry_url retry_url: Option(String),
) -> element.Element(msg) {
  html.div([attribute.class("fetch-error")], [
    html.div([attribute.class("fetch-error-content")], [
      html.div([attribute.class("fetch-error-icon")], [
        element.text(get_error_icon(error.severity)),
      ]),
      html.h3([attribute.class("fetch-error-title")], [
        element.text(get_error_title(error.category)),
      ]),
      html.p([attribute.class("fetch-error-message")], [
        element.text(error.message),
      ]),
      case error.details {
        Some(details) ->
          html.details([attribute.class("fetch-error-details")], [
            html.summary([], [element.text("Technical Details")]),
            html.pre([attribute.class("error-details-code")], [
              element.text(details),
            ]),
          ])
        None -> element.none()
      },
    ]),
    case error.recoverable {
      True ->
        html.div([attribute.class("fetch-error-actions")], [
          retry_button(retry_url),
          html.a([attribute.href("/"), attribute.class("btn btn-secondary")], [
            element.text("Go Home"),
          ]),
        ])
      False ->
        html.div([attribute.class("fetch-error-actions")], [
          html.a([attribute.href("/"), attribute.class("btn btn-primary")], [
            element.text("Go Home"),
          ]),
        ])
    },
  ])
}

// ===================================================================
// ROUTE BOUNDARY
// ===================================================================

/// Route boundary wrapper - catches navigation and routing errors
///
/// Wraps route handlers with error boundaries to catch 404s, invalid
/// routes, and navigation errors. Provides user-friendly error pages
/// with navigation options.
///
/// Usage:
/// ```gleam
/// route_boundary(
///   state: Error(route_error),
///   content: page_content(),
///   fallback: not_found_page()
/// )
/// ```
pub fn route_boundary(
  state state: BoundaryState,
  content content: element.Element(msg),
  fallback fallback: element.Element(msg),
) -> element.Element(msg) {
  case state {
    Ok -> content
    Error(_error) -> {
      html.div([attribute.class("route-boundary")], [fallback])
    }
  }
}

/// Route not found error page
///
/// Displays a 404 error page with navigation options and search suggestions.
///
/// Usage:
/// ```gleam
/// route_not_found("/invalid-path")
/// ```
pub fn route_not_found(path: String) -> element.Element(msg) {
  html.div([attribute.class("error-page route-error")], [
    html.div([attribute.class("error-page-content")], [
      html.div([attribute.class("error-code")], [element.text("404")]),
      html.h1([attribute.class("error-title")], [element.text("Page Not Found")]),
      html.p([attribute.class("error-message")], [
        element.text(
          "The page \"" <> path <> "\" doesn't exist or has been moved.",
        ),
      ]),
      html.div([attribute.class("error-suggestions")], [
        html.h3([], [element.text("Try these instead:")]),
        html.ul([attribute.class("suggestion-list")], [
          html.li([], [
            html.a([attribute.href("/")], [element.text("Dashboard")]),
          ]),
          html.li([], [
            html.a([attribute.href("/recipes")], [
              element.text("Browse Recipes"),
            ]),
          ]),
          html.li([], [
            html.a([attribute.href("/food-search")], [
              element.text("Search Foods"),
            ]),
          ]),
          html.li([], [
            html.a([attribute.href("/meal-plan")], [
              element.text("Meal Planner"),
            ]),
          ]),
        ]),
      ]),
    ]),
  ])
}

/// Invalid route parameter error
///
/// Displays error for malformed or invalid route parameters.
///
/// Usage:
/// ```gleam
/// invalid_route_param("recipe_id", "invalid-123")
/// ```
pub fn invalid_route_param(
  param_name: String,
  param_value: String,
) -> element.Element(msg) {
  html.div([attribute.class("error-page route-error")], [
    html.div([attribute.class("error-page-content")], [
      html.div([attribute.class("error-icon-large")], [element.text("⚠")]),
      html.h1([attribute.class("error-title")], [
        element.text("Invalid Parameter"),
      ]),
      html.p([attribute.class("error-message")], [
        element.text(
          "The "
          <> param_name
          <> " parameter \""
          <> param_value
          <> "\" is invalid.",
        ),
      ]),
      html.div([attribute.class("error-actions")], [
        html.a([attribute.href("/"), attribute.class("btn btn-primary")], [
          element.text("Go Home"),
        ]),
      ]),
    ]),
  ])
}

// ===================================================================
// COMPONENT BOUNDARY
// ===================================================================

/// Generic component boundary wrapper
///
/// Wraps any component with error handling. If the component fails to
/// render or throws an error, displays fallback UI instead of crashing
/// the entire application.
///
/// Usage:
/// ```gleam
/// component_boundary(
///   state: Ok,
///   content: complex_component(),
///   fallback: error_fallback("Failed to load component")
/// )
/// ```
pub fn component_boundary(
  state state: BoundaryState,
  content content: element.Element(msg),
  fallback fallback: element.Element(msg),
) -> element.Element(msg) {
  case state {
    Ok -> content
    Error(_error) -> {
      html.div([attribute.class("component-boundary")], [fallback])
    }
  }
}

/// Component error fallback with details
///
/// Shows detailed error information for component failures with
/// optional stack trace and recovery options.
///
/// Usage:
/// ```gleam
/// component_error_fallback(
///   component_name: "RecipeCard",
///   error: BoundaryError(...),
///   show_details: True
/// )
/// ```
pub fn component_error_fallback(
  component_name component_name: String,
  error error: BoundaryError,
  show_details show_details: Bool,
) -> element.Element(msg) {
  html.div([attribute.class("component-error-fallback")], [
    html.div([attribute.class("error-content")], [
      html.div([attribute.class("error-icon")], [
        element.text(get_error_icon(error.severity)),
      ]),
      html.h4([attribute.class("error-title")], [
        element.text("Component Error: " <> component_name),
      ]),
      html.p([attribute.class("error-message")], [element.text(error.message)]),
      case show_details, error.details {
        True, Some(details) ->
          html.details([attribute.class("error-details")], [
            html.summary([], [element.text("Error Details")]),
            html.pre([attribute.class("error-stack")], [element.text(details)]),
          ])
        _, _ -> element.none()
      },
    ]),
    case error.recoverable {
      True ->
        html.div([attribute.class("error-actions")], [
          retry_button(error.retry_action),
        ])
      False ->
        html.div([attribute.class("error-actions")], [
          html.button(
            [attribute.class("btn btn-secondary"), attribute.type_("button")],
            [element.text("Dismiss")],
          ),
        ])
    },
  ])
}

// ===================================================================
// FALLBACK UI COMPONENTS
// ===================================================================

/// Generic error fallback with customizable message
///
/// Simple fallback UI for when content fails to load.
///
/// Usage:
/// ```gleam
/// error_fallback(
///   message: "Failed to load recipes",
///   icon: "⚠",
///   actions: [html.a(...), html.button(...)]
/// )
/// ```
pub fn error_fallback(
  message message: String,
  icon icon: String,
  actions actions: List(element.Element(msg)),
) -> element.Element(msg) {
  html.div([attribute.class("error-fallback")], [
    html.div([attribute.class("error-fallback-content")], [
      html.div([attribute.class("error-icon")], [element.text(icon)]),
      html.p([attribute.class("error-message")], [element.text(message)]),
      html.div([attribute.class("error-actions")], actions),
    ]),
  ])
}

/// Retry button component
///
/// Displays a retry button for recoverable errors.
///
/// Usage:
/// ```gleam
/// retry_button(Some("/api/recipes"))
/// ```
pub fn retry_button(retry_url: Option(String)) -> element.Element(msg) {
  case retry_url {
    Some(url) ->
      html.a([attribute.href(url), attribute.class("btn btn-primary")], [
        element.text("🔄 Retry"),
      ])
    None ->
      html.button(
        [
          attribute.class("btn btn-primary"),
          attribute.type_("button"),
          attribute.attribute("onclick", "window.location.reload()"),
        ],
        [element.text("🔄 Retry")],
      )
  }
}

/// Reset to safe state button
///
/// Provides a way to reset the component to a known safe state.
///
/// Usage:
/// ```gleam
/// reset_button("/dashboard")
/// ```
pub fn reset_button(safe_url: String) -> element.Element(msg) {
  html.a([attribute.href(safe_url), attribute.class("btn btn-secondary")], [
    element.text("Reset"),
  ])
}

// ===================================================================
// ERROR HELPERS
// ===================================================================

/// Create a network error
///
/// Convenience function to create a network/API error.
///
/// Usage:
/// ```gleam
/// network_error("Failed to fetch recipes", Some("Check network connection"))
/// ```
pub fn network_error(message: String, details: Option(String)) -> BoundaryError {
  BoundaryError(
    message: message,
    category: NetworkError,
    severity: Moderate,
    details: details,
    recoverable: True,
    retry_action: None,
  )
}

/// Create a validation error
///
/// Convenience function to create a form validation error.
///
/// Usage:
/// ```gleam
/// validation_error("Invalid input", Some("Field 'name' is required"))
/// ```
pub fn validation_error(
  message: String,
  details: Option(String),
) -> BoundaryError {
  BoundaryError(
    message: message,
    category: ValidationError,
    severity: Minor,
    details: details,
    recoverable: True,
    retry_action: None,
  )
}

/// Create a state error
///
/// Convenience function to create a state management error.
///
/// Usage:
/// ```gleam
/// state_error("Invalid state transition", None)
/// ```
pub fn state_error(message: String, details: Option(String)) -> BoundaryError {
  BoundaryError(
    message: message,
    category: StateError,
    severity: Severe,
    details: details,
    recoverable: False,
    retry_action: None,
  )
}

/// Create a render error
///
/// Convenience function to create a component rendering error.
///
/// Usage:
/// ```gleam
/// render_error("Failed to render component", Some("Missing required prop"))
/// ```
pub fn render_error(message: String, details: Option(String)) -> BoundaryError {
  BoundaryError(
    message: message,
    category: RenderError,
    severity: Moderate,
    details: details,
    recoverable: True,
    retry_action: None,
  )
}

/// Get error icon based on severity
fn get_error_icon(severity: ErrorSeverity) -> String {
  case severity {
    Minor -> "ℹ"
    Moderate -> "⚠"
    Severe -> "⚡"
    Critical -> "🚨"
  }
}

/// Get error title based on category
fn get_error_title(category: ErrorCategory) -> String {
  case category {
    NetworkError -> "Network Error"
    ValidationError -> "Validation Error"
    StateError -> "State Error"
    RenderError -> "Render Error"
    RouteError -> "Route Error"
    DataError -> "Data Error"
    AuthError -> "Authentication Error"
    UnknownError -> "Unexpected Error"
  }
}

// ===================================================================
// INTEGRATION PATTERNS
// ===================================================================

/// Wrap entire page with error boundary
///
/// Catches any errors in the page and provides a fallback.
///
/// Usage:
/// ```gleam
/// page_boundary(
///   state: Ok,
///   content: dashboard_page(),
///   on_error: fn(_) { error_page("Something went wrong", "/") }
/// )
/// ```
pub fn page_boundary(
  state state: BoundaryState,
  content content: element.Element(msg),
  on_error error_handler: fn(BoundaryError) -> element.Element(msg),
) -> element.Element(msg) {
  case state {
    Ok -> content
    Error(error) -> {
      html.div([attribute.class("page-boundary")], [error_handler(error)])
    }
  }
}

/// Wrap async operation with loading and error states
///
/// Provides a complete async UI pattern with loading, error, and success states.
///
/// Usage:
/// ```gleam
/// async_boundary(
///   state: Loading,
///   content: recipe_list(recipes),
///   loading: loading_skeleton(),
///   error_fallback: fn(e) { fetch_error_display(e, Some("/api/recipes")) }
/// )
/// ```
pub fn async_boundary(
  state state: AsyncState(data),
  content content_fn: fn(data) -> element.Element(msg),
  loading loading: element.Element(msg),
  error_fallback error_handler: fn(BoundaryError) -> element.Element(msg),
) -> element.Element(msg) {
  case state {
    Loading -> loading
    Success(data) -> content_fn(data)
    Failed(error) ->
      html.div([attribute.class("async-boundary")], [error_handler(error)])
  }
}

/// Async state for async operations
pub type AsyncState(data) {
  Loading
  Success(data)
  Failed(BoundaryError)
}

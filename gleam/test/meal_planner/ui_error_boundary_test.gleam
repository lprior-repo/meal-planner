/// Error Boundary Component Tests
///
/// Tests for error boundary wrappers, fallback UI, and error handling logic.
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/ui/error_boundary

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// ERROR TYPE TESTS
// ===================================================================

pub fn network_error_creation_test() {
  let error =
    error_boundary.network_error(
      "Failed to fetch data",
      Some("Network timeout"),
    )

  error.message
  |> should.equal("Failed to fetch data")

  error.category
  |> should.equal(error_boundary.NetworkError)

  error.severity
  |> should.equal(error_boundary.Moderate)

  error.recoverable
  |> should.equal(True)

  error.details
  |> should.equal(Some("Network timeout"))
}

pub fn validation_error_creation_test() {
  let error =
    error_boundary.validation_error("Invalid input", Some("Name is required"))

  error.message
  |> should.equal("Invalid input")

  error.category
  |> should.equal(error_boundary.ValidationError)

  error.severity
  |> should.equal(error_boundary.Minor)

  error.recoverable
  |> should.equal(True)
}

pub fn state_error_creation_test() {
  let error = error_boundary.state_error("Invalid state", None)

  error.message
  |> should.equal("Invalid state")

  error.category
  |> should.equal(error_boundary.StateError)

  error.severity
  |> should.equal(error_boundary.Severe)

  error.recoverable
  |> should.equal(False)
}

pub fn render_error_creation_test() {
  let error =
    error_boundary.render_error("Render failed", Some("Missing prop"))

  error.message
  |> should.equal("Render failed")

  error.category
  |> should.equal(error_boundary.RenderError)

  error.severity
  |> should.equal(error_boundary.Moderate)

  error.recoverable
  |> should.equal(True)
}

// ===================================================================
// BOUNDARY STATE TESTS
// ===================================================================

pub fn boundary_state_ok_test() {
  let state = error_boundary.Ok
  let content = html.div([], [element.text("Content")])
  let fallback = html.div([], [element.text("Error")])

  let result =
    error_boundary.component_boundary(
      state: state,
      content: content,
      fallback: fallback,
    )

  // When state is Ok, should render content
  result
  |> element.to_string
  |> should.equal(element.to_string(content))
}

pub fn boundary_state_error_test() {
  let error =
    error_boundary.BoundaryError(
      message: "Test error",
      category: error_boundary.RenderError,
      severity: error_boundary.Minor,
      details: None,
      recoverable: False,
      retry_action: None,
    )
  let state = error_boundary.Error(error)
  let content = html.div([], [element.text("Content")])
  let fallback = html.div([], [element.text("Error fallback")])

  let result =
    error_boundary.component_boundary(
      state: state,
      content: content,
      fallback: fallback,
    )

  // When state is Error, should render fallback wrapped in boundary div
  result
  |> element.to_string
  |> should.contain("component-boundary")
}

// ===================================================================
// FORM BOUNDARY TESTS
// ===================================================================

pub fn form_boundary_ok_state_test() {
  let state = error_boundary.Ok
  let content = html.form([], [html.input([attribute.name("test")])])
  let error_handler = fn(_error) { html.div([], [element.text("Error")]) }

  let result =
    error_boundary.form_boundary(
      state: state,
      content: content,
      on_error: error_handler,
    )

  // Should render form when no error
  result
  |> element.to_string
  |> should.contain("<form")
}

pub fn form_boundary_error_state_test() {
  let error =
    error_boundary.validation_error("Form invalid", Some("Name required"))
  let state = error_boundary.Error(error)
  let content = html.form([], [])
  let error_handler = fn(_error) {
    html.div([attribute.class("form-error")], [element.text("Form error")])
  }

  let result =
    error_boundary.form_boundary(
      state: state,
      content: content,
      on_error: error_handler,
    )

  // Should render error handler when error state
  result
  |> element.to_string
  |> should.contain("form-boundary")

  result
  |> element.to_string
  |> should.contain("form-error")
}

pub fn form_boundary_recoverable_error_shows_retry_test() {
  let error =
    error_boundary.BoundaryError(
      message: "Network error",
      category: error_boundary.NetworkError,
      severity: error_boundary.Moderate,
      details: None,
      recoverable: True,
      retry_action: Some("/submit"),
    )
  let state = error_boundary.Error(error)
  let content = html.form([], [])
  let error_handler = fn(_) { html.div([], [element.text("Error")]) }

  let result =
    error_boundary.form_boundary(
      state: state,
      content: content,
      on_error: error_handler,
    )

  // Should show retry button for recoverable errors
  result
  |> element.to_string
  |> should.contain("Retry")
}

pub fn form_validation_error_display_test() {
  let errors = [
    #("name", "Recipe name is required"),
    #("servings", "Must be greater than 0"),
  ]

  let result =
    error_boundary.form_validation_error(
      errors: errors,
      message: "Please fix the errors below",
    )

  let html_string = element.to_string(result)

  // Should contain overall message
  html_string
  |> should.contain("Please fix the errors below")

  // Should contain field errors
  html_string
  |> should.contain("name")

  html_string
  |> should.contain("Recipe name is required")

  html_string
  |> should.contain("servings")

  html_string
  |> should.contain("Must be greater than 0")

  // Should have proper structure
  html_string
  |> should.contain("validation-error-list")
}

// ===================================================================
// FETCH BOUNDARY TESTS
// ===================================================================

pub fn fetch_boundary_ok_state_test() {
  let state = error_boundary.Ok
  let content = html.div([], [element.text("Data loaded")])
  let loading = html.div([], [element.text("Loading...")])

  let result =
    error_boundary.fetch_boundary(
      state: state,
      content: content,
      loading: loading,
      retry_url: Some("/api/data"),
    )

  // Should render content when no error
  result
  |> element.to_string
  |> should.contain("Data loaded")
}

pub fn fetch_boundary_error_state_test() {
  let error = error_boundary.network_error("API failed", None)
  let state = error_boundary.Error(error)
  let content = html.div([], [element.text("Data")])
  let loading = html.div([], [element.text("Loading...")])

  let result =
    error_boundary.fetch_boundary(
      state: state,
      content: content,
      loading: loading,
      retry_url: Some("/api/data"),
    )

  // Should render error display
  result
  |> element.to_string
  |> should.contain("fetch-boundary")

  result
  |> element.to_string
  |> should.contain("Network Error")
}

pub fn fetch_error_display_with_retry_test() {
  let error =
    error_boundary.BoundaryError(
      message: "Failed to load recipes",
      category: error_boundary.NetworkError,
      severity: error_boundary.Moderate,
      details: Some("HTTP 500 - Server Error"),
      recoverable: True,
      retry_action: None,
    )

  let result =
    error_boundary.fetch_error_display(
      error: error,
      retry_url: Some("/api/recipes"),
    )

  let html_string = element.to_string(result)

  // Should show error message
  html_string
  |> should.contain("Failed to load recipes")

  // Should show retry button
  html_string
  |> should.contain("Retry")

  // Should show technical details
  html_string
  |> should.contain("Technical Details")

  html_string
  |> should.contain("HTTP 500")
}

pub fn fetch_error_display_non_recoverable_test() {
  let error =
    error_boundary.BoundaryError(
      message: "Unauthorized access",
      category: error_boundary.AuthError,
      severity: error_boundary.Severe,
      details: None,
      recoverable: False,
      retry_action: None,
    )

  let result =
    error_boundary.fetch_error_display(error: error, retry_url: None)

  let html_string = element.to_string(result)

  // Should show error message
  html_string
  |> should.contain("Unauthorized access")

  // Should NOT show retry button
  html_string
  |> should.not_contain("Retry")

  // Should show home button instead
  html_string
  |> should.contain("Go Home")
}

// ===================================================================
// ROUTE BOUNDARY TESTS
// ===================================================================

pub fn route_boundary_ok_state_test() {
  let state = error_boundary.Ok
  let content = html.div([], [element.text("Page content")])
  let fallback = html.div([], [element.text("404")])

  let result =
    error_boundary.route_boundary(
      state: state,
      content: content,
      fallback: fallback,
    )

  // Should render content when no error
  result
  |> element.to_string
  |> should.contain("Page content")
}

pub fn route_boundary_error_state_test() {
  let error =
    error_boundary.BoundaryError(
      message: "Route not found",
      category: error_boundary.RouteError,
      severity: error_boundary.Minor,
      details: None,
      recoverable: False,
      retry_action: None,
    )
  let state = error_boundary.Error(error)
  let content = html.div([], [element.text("Page")])
  let fallback = html.div([], [element.text("404 Not Found")])

  let result =
    error_boundary.route_boundary(
      state: state,
      content: content,
      fallback: fallback,
    )

  // Should render fallback
  result
  |> element.to_string
  |> should.contain("route-boundary")

  result
  |> element.to_string
  |> should.contain("404 Not Found")
}

pub fn route_not_found_page_test() {
  let result = error_boundary.route_not_found("/invalid/path")

  let html_string = element.to_string(result)

  // Should show 404 code
  html_string
  |> should.contain("404")

  // Should show the invalid path
  html_string
  |> should.contain("/invalid/path")

  // Should provide navigation suggestions
  html_string
  |> should.contain("Dashboard")

  html_string
  |> should.contain("Browse Recipes")

  html_string
  |> should.contain("Search Foods")
}

pub fn invalid_route_param_page_test() {
  let result = error_boundary.invalid_route_param("recipe_id", "invalid-123")

  let html_string = element.to_string(result)

  // Should show parameter name
  html_string
  |> should.contain("recipe_id")

  // Should show invalid value
  html_string
  |> should.contain("invalid-123")

  // Should show error message
  html_string
  |> should.contain("Invalid Parameter")
}

// ===================================================================
// COMPONENT BOUNDARY TESTS
// ===================================================================

pub fn component_boundary_ok_state_test() {
  let state = error_boundary.Ok
  let content = html.div([], [element.text("Component")])
  let fallback = html.div([], [element.text("Error")])

  let result =
    error_boundary.component_boundary(
      state: state,
      content: content,
      fallback: fallback,
    )

  // Should render content when no error
  result
  |> element.to_string
  |> should.contain("Component")
}

pub fn component_boundary_error_state_test() {
  let error = error_boundary.render_error("Component failed", None)
  let state = error_boundary.Error(error)
  let content = html.div([], [element.text("Component")])
  let fallback = html.div([], [element.text("Fallback")])

  let result =
    error_boundary.component_boundary(
      state: state,
      content: content,
      fallback: fallback,
    )

  // Should render fallback
  result
  |> element.to_string
  |> should.contain("component-boundary")

  result
  |> element.to_string
  |> should.contain("Fallback")
}

pub fn component_error_fallback_with_details_test() {
  let error =
    error_boundary.BoundaryError(
      message: "Failed to render",
      category: error_boundary.RenderError,
      severity: error_boundary.Moderate,
      details: Some("Stack trace:\n  at RecipeCard.render()\n  at App.main()"),
      recoverable: True,
      retry_action: Some("/reload"),
    )

  let result =
    error_boundary.component_error_fallback(
      component_name: "RecipeCard",
      error: error,
      show_details: True,
    )

  let html_string = element.to_string(result)

  // Should show component name
  html_string
  |> should.contain("RecipeCard")

  // Should show error message
  html_string
  |> should.contain("Failed to render")

  // Should show details when requested
  html_string
  |> should.contain("Stack trace")

  // Should show retry for recoverable errors
  html_string
  |> should.contain("Retry")
}

pub fn component_error_fallback_no_details_test() {
  let error =
    error_boundary.BoundaryError(
      message: "Error",
      category: error_boundary.RenderError,
      severity: error_boundary.Minor,
      details: Some("Hidden details"),
      recoverable: False,
      retry_action: None,
    )

  let result =
    error_boundary.component_error_fallback(
      component_name: "TestComponent",
      error: error,
      show_details: False,
    )

  let html_string = element.to_string(result)

  // Should NOT show details when show_details is False
  html_string
  |> should.not_contain("Hidden details")

  // Should show dismiss for non-recoverable errors
  html_string
  |> should.contain("Dismiss")
}

// ===================================================================
// FALLBACK UI TESTS
// ===================================================================

pub fn error_fallback_with_actions_test() {
  let actions = [
    html.a([attribute.href("/retry")], [element.text("Retry")]),
    html.a([attribute.href("/home")], [element.text("Home")]),
  ]

  let result =
    error_boundary.error_fallback(
      message: "Something went wrong",
      icon: "⚠",
      actions: actions,
    )

  let html_string = element.to_string(result)

  // Should contain error message
  html_string
  |> should.contain("Something went wrong")

  // Should contain icon
  html_string
  |> should.contain("⚠")

  // Should contain actions
  html_string
  |> should.contain("Retry")

  html_string
  |> should.contain("Home")
}

pub fn retry_button_with_url_test() {
  let result = error_boundary.retry_button(Some("/api/retry"))

  element.to_string(result)
  |> should.contain("Retry")

  element.to_string(result)
  |> should.contain("/api/retry")
}

pub fn retry_button_without_url_test() {
  let result = error_boundary.retry_button(None)

  let html_string = element.to_string(result)

  // Should have retry button
  html_string
  |> should.contain("Retry")

  // Should have onclick reload
  html_string
  |> should.contain("window.location.reload()")
}

pub fn reset_button_test() {
  let result = error_boundary.reset_button("/dashboard")

  let html_string = element.to_string(result)

  html_string
  |> should.contain("Reset")

  html_string
  |> should.contain("/dashboard")
}

// ===================================================================
// ASYNC BOUNDARY TESTS
// ===================================================================

pub fn async_boundary_loading_state_test() {
  let state = error_boundary.Loading
  let content_fn = fn(data: String) { html.div([], [element.text(data)]) }
  let loading = html.div([], [element.text("Loading...")])
  let error_handler = fn(_) { html.div([], [element.text("Error")]) }

  let result =
    error_boundary.async_boundary(
      state: state,
      content: content_fn,
      loading: loading,
      error_fallback: error_handler,
    )

  // Should show loading state
  result
  |> element.to_string
  |> should.contain("Loading...")
}

pub fn async_boundary_success_state_test() {
  let state = error_boundary.Success("Recipe data")
  let content_fn = fn(data: String) { html.div([], [element.text(data)]) }
  let loading = html.div([], [element.text("Loading...")])
  let error_handler = fn(_) { html.div([], [element.text("Error")]) }

  let result =
    error_boundary.async_boundary(
      state: state,
      content: content_fn,
      loading: loading,
      error_fallback: error_handler,
    )

  // Should show content with data
  result
  |> element.to_string
  |> should.contain("Recipe data")
}

pub fn async_boundary_failed_state_test() {
  let error = error_boundary.network_error("API failed", None)
  let state = error_boundary.Failed(error)
  let content_fn = fn(data: String) { html.div([], [element.text(data)]) }
  let loading = html.div([], [element.text("Loading...")])
  let error_handler = fn(_error) {
    html.div([attribute.class("error")], [element.text("API Error")])
  }

  let result =
    error_boundary.async_boundary(
      state: state,
      content: content_fn,
      loading: loading,
      error_fallback: error_handler,
    )

  // Should show error fallback
  result
  |> element.to_string
  |> should.contain("async-boundary")

  result
  |> element.to_string
  |> should.contain("API Error")
}

// ===================================================================
// PAGE BOUNDARY TESTS
// ===================================================================

pub fn page_boundary_ok_state_test() {
  let state = error_boundary.Ok
  let content = html.div([], [element.text("Page content")])
  let error_handler = fn(_) { html.div([], [element.text("Error page")]) }

  let result =
    error_boundary.page_boundary(
      state: state,
      content: content,
      on_error: error_handler,
    )

  // Should render page content
  result
  |> element.to_string
  |> should.contain("Page content")
}

pub fn page_boundary_error_state_test() {
  let error =
    error_boundary.BoundaryError(
      message: "Page crashed",
      category: error_boundary.UnknownError,
      severity: error_boundary.Critical,
      details: None,
      recoverable: False,
      retry_action: None,
    )
  let state = error_boundary.Error(error)
  let content = html.div([], [element.text("Page")])
  let error_handler = fn(err) {
    html.div([], [element.text("Error: " <> err.message)])
  }

  let result =
    error_boundary.page_boundary(
      state: state,
      content: content,
      on_error: error_handler,
    )

  // Should render error page
  result
  |> element.to_string
  |> should.contain("page-boundary")

  result
  |> element.to_string
  |> should.contain("Error: Page crashed")
}

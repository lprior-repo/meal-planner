# Error Boundary Usage Guide

## Overview

The `meal_planner/ui/error_boundary` module provides comprehensive error handling components for the Lustre application. It implements the error boundary pattern to gracefully catch and handle errors without crashing the entire application.

## Features

- **Form Boundaries**: Validation error handling with field-level error display
- **Fetch Boundaries**: API error handling with retry logic and loading states
- **Route Boundaries**: Navigation and 404 error handling
- **Component Boundaries**: Generic component error catching
- **Async Boundaries**: Combined loading/error/success states
- **Page Boundaries**: Application-level error catching

## Quick Start

### 1. Basic Component Error Boundary

```gleam
import meal_planner/ui/error_boundary

pub fn my_component(has_error: Bool) {
  error_boundary.component_boundary(
    state: case has_error {
      True -> error_boundary.Error(
        error_boundary.render_error("Failed to load component", None)
      )
      False -> error_boundary.Ok
    },
    content: html.div([], [element.text("Component content")]),
    fallback: html.div([], [element.text("Component failed to load")])
  )
}
```

### 2. Form with Validation Errors

```gleam
pub fn recipe_form(validation_errors: List(#(String, String))) {
  let state = case validation_errors {
    [] -> error_boundary.Ok
    errors -> {
      let error = error_boundary.validation_error(
        "Please fix the validation errors",
        Some("See details below")
      )
      error_boundary.Error(error)
    }
  }

  error_boundary.form_boundary(
    state: state,
    content: render_recipe_form(),
    on_error: fn(error) {
      error_boundary.form_validation_error(
        errors: validation_errors,
        message: error.message
      )
    }
  )
}
```

### 3. API Call with Retry

```gleam
pub type LoadState {
  Loading
  Loaded(List(Recipe))
  Failed(String)
}

pub fn recipe_list(load_state: LoadState) {
  let state = case load_state {
    Failed(msg) -> {
      error_boundary.Error(
        error_boundary.network_error(msg, Some("Check your connection"))
      )
    }
    _ -> error_boundary.Ok
  }

  error_boundary.fetch_boundary(
    state: state,
    content: render_recipes(recipes),
    loading: loading_skeleton(),
    retry_url: Some("/api/recipes")
  )
}
```

### 4. Async State Pattern

```gleam
pub fn dashboard_data(data_state: error_boundary.AsyncState(DashboardData)) {
  error_boundary.async_boundary(
    state: data_state,
    content: fn(data) { render_dashboard(data) },
    loading: loading_page("Loading dashboard..."),
    error_fallback: fn(error) {
      error_boundary.fetch_error_display(
        error: error,
        retry_url: Some("/api/dashboard")
      )
    }
  )
}
```

### 5. Route Not Found

```gleam
pub fn handle_route(path: String) {
  case path {
    "/recipes" -> recipe_page()
    "/dashboard" -> dashboard_page()
    invalid_path -> error_boundary.route_not_found(invalid_path)
  }
}
```

## Error Types

### Creating Errors

```gleam
// Network/API error (recoverable, moderate severity)
let network_err = error_boundary.network_error(
  "Failed to fetch data",
  Some("HTTP 500 - Server Error")
)

// Validation error (recoverable, minor severity)
let validation_err = error_boundary.validation_error(
  "Invalid input",
  Some("Name field is required")
)

// State error (non-recoverable, severe severity)
let state_err = error_boundary.state_error(
  "Invalid state transition",
  None
)

// Render error (recoverable, moderate severity)
let render_err = error_boundary.render_error(
  "Component failed to render",
  Some("Missing required prop: 'name'")
)
```

### Custom Errors

```gleam
let custom_error = error_boundary.BoundaryError(
  message: "Custom error message",
  category: error_boundary.DataError,
  severity: error_boundary.Critical,
  details: Some("Additional technical details"),
  recoverable: True,
  retry_action: Some("/retry-url")
)
```

## Error Severity Levels

- **Minor**: User can continue with degraded functionality
- **Moderate**: Some features unavailable but app usable
- **Severe**: Major functionality broken but app accessible
- **Critical**: App cannot function properly

## Error Categories

- `NetworkError` - API/network failures
- `ValidationError` - Form validation failures
- `StateError` - State management errors
- `RenderError` - Component rendering errors
- `RouteError` - Navigation/routing errors
- `DataError` - Data parsing/transformation errors
- `AuthError` - Authentication/authorization errors
- `UnknownError` - Uncategorized errors

## Boundary State

All boundaries use a `BoundaryState` type:

```gleam
pub type BoundaryState {
  Ok                      // No error, render normally
  Error(BoundaryError)    // Error caught, show fallback
}
```

## Fallback UI Components

### Generic Error Fallback

```gleam
error_boundary.error_fallback(
  message: "Something went wrong",
  icon: "⚠",
  actions: [
    html.a([attribute.href("/retry")], [element.text("Retry")]),
    html.a([attribute.href("/")], [element.text("Home")])
  ]
)
```

### Retry Button

```gleam
// With specific URL
error_boundary.retry_button(Some("/api/recipes"))

// Reload current page
error_boundary.retry_button(None)
```

### Reset Button

```gleam
error_boundary.reset_button("/dashboard")
```

## Integration Examples

### Complete Form with Validation

```gleam
import gleam/list
import meal_planner/ui/error_boundary

pub type FormState {
  FormState(
    values: FormValues,
    errors: List(#(String, String)),
    submitting: Bool,
    submit_error: option.Option(String)
  )
}

pub fn recipe_form(form_state: FormState) {
  let boundary_state = case form_state.errors, form_state.submit_error {
    [], None -> error_boundary.Ok
    errors, None -> {
      error_boundary.Error(
        error_boundary.validation_error(
          "Please fix the validation errors",
          None
        )
      )
    }
    _, Some(msg) -> {
      error_boundary.Error(
        error_boundary.network_error(msg, None)
      )
    }
  }

  error_boundary.form_boundary(
    state: boundary_state,
    content: render_form_fields(form_state),
    on_error: fn(error) {
      case error.category {
        error_boundary.ValidationError -> {
          error_boundary.form_validation_error(
            errors: form_state.errors,
            message: error.message
          )
        }
        error_boundary.NetworkError -> {
          error_boundary.fetch_error_display(
            error: error,
            retry_url: Some("/recipes/create")
          )
        }
        _ -> {
          error_boundary.error_fallback(
            message: error.message,
            icon: "⚠",
            actions: []
          )
        }
      }
    }
  )
}
```

### Page-Level Error Handling

```gleam
pub fn dashboard_page(page_state: PageState) {
  let boundary_state = case page_state.load_error {
    Some(err) -> error_boundary.Error(
      error_boundary.BoundaryError(
        message: err,
        category: error_boundary.UnknownError,
        severity: error_boundary.Critical,
        details: None,
        recoverable: False,
        retry_action: None
      )
    )
    None -> error_boundary.Ok
  }

  error_boundary.page_boundary(
    state: boundary_state,
    content: render_dashboard_content(page_state),
    on_error: fn(error) {
      error_boundary.error_page(
        title: "Page Error",
        message: error.message,
        retry_url: Some("/dashboard")
      )
    }
  )
}
```

## Best Practices

### 1. Use Specific Boundaries

Choose the right boundary for each use case:
- **Forms**: `form_boundary()` for validation
- **API Calls**: `fetch_boundary()` for network errors
- **Components**: `component_boundary()` for render errors
- **Pages**: `page_boundary()` for app-level errors

### 2. Provide Helpful Error Messages

```gleam
// ❌ BAD
error_boundary.network_error("Error", None)

// ✅ GOOD
error_boundary.network_error(
  "Failed to load recipes. Please check your internet connection.",
  Some("HTTP 503 - Service Unavailable")
)
```

### 3. Enable Recovery When Possible

```gleam
// Mark errors as recoverable when retry is available
BoundaryError(
  message: "...",
  recoverable: True,  // Allow retry
  retry_action: Some("/api/retry")
)
```

### 4. Show Technical Details in Development

```gleam
// Show details in development, hide in production
error_boundary.component_error_fallback(
  component_name: "RecipeCard",
  error: error,
  show_details: is_development_mode()
)
```

### 5. Layer Boundaries

```gleam
// Page boundary wraps entire page
page_boundary(
  state: page_state,
  content: {
    // Component boundary for specific component
    component_boundary(
      state: component_state,
      content: recipe_list,
      fallback: fallback_ui
    )
  },
  on_error: page_error_handler
)
```

## Testing

See `test/meal_planner/ui_error_boundary_test.gleam` for comprehensive test examples covering:

- Error type creation
- Boundary state transitions
- Form validation errors
- Network error handling
- Route error pages
- Component error fallbacks
- Async state management
- Fallback UI rendering

## CSS Styling

The error boundary components use these CSS classes:

- `.form-boundary` - Form error wrapper
- `.fetch-boundary` - API error wrapper
- `.route-boundary` - Route error wrapper
- `.component-boundary` - Component error wrapper
- `.page-boundary` - Page error wrapper
- `.async-boundary` - Async state wrapper
- `.error-fallback` - Generic fallback container
- `.fetch-error` - Network error display
- `.component-error-fallback` - Component error display
- `.form-validation-error` - Validation error list
- `.error-page` - Full page error display

Ensure these are styled appropriately in your CSS.

## Migration from Existing Code

If you have existing error handling:

```gleam
// OLD - manual error handling
case result {
  Ok(data) -> render_content(data)
  Error(err) -> html.div([], [element.text("Error: " <> err)])
}

// NEW - error boundary
error_boundary.async_boundary(
  state: case result {
    Ok(data) -> error_boundary.Success(data)
    Error(err) -> error_boundary.Failed(
      error_boundary.network_error(err, None)
    )
  },
  content: render_content,
  loading: loading_spinner(),
  error_fallback: fn(e) {
    error_boundary.fetch_error_display(e, Some("/retry"))
  }
)
```

## See Also

- `meal_planner/ui/components/error.gleam` - Basic error alert components
- `meal_planner/ui/components/loading.gleam` - Loading state components
- `test/meal_planner/ui_error_boundary_test.gleam` - Comprehensive tests

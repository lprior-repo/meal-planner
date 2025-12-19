/// Model - Application state management for TUI
///
/// This module provides the Model type and initialization functions
/// following the Elm Architecture pattern.
import gleam/option.{None, Some}
import meal_planner/cli/types
import meal_planner/config

/// Initialize the application model with defaults
pub fn init(config: config.Config) -> types.Model {
  types.Model(
    config: config,
    current_screen: types.MainMenu,
    navigation_stack: [],
    selected_domain: None,
    search_query: "",
    results: None,
    loading: False,
    error: None,
    pagination_offset: 0,
    pagination_limit: 100,
  )
}

/// Navigate to a new screen, pushing current screen to stack
pub fn navigate_to(model: types.Model, screen: types.Screen) -> types.Model {
  let new_stack = [model.current_screen, ..model.navigation_stack]
  types.Model(
    ..model,
    current_screen: screen,
    navigation_stack: new_stack,
    error: None,
  )
}

/// Go back to the previous screen
pub fn go_back(model: types.Model) -> types.Model {
  case model.navigation_stack {
    [] -> {
      // Already at root, stay on current screen
      model
    }
    [previous, ..rest] -> {
      types.Model(
        ..model,
        current_screen: previous,
        navigation_stack: rest,
        error: None,
      )
    }
  }
}

/// Set loading state
pub fn set_loading(model: types.Model, is_loading: Bool) -> types.Model {
  types.Model(..model, loading: is_loading, error: None)
}

/// Set error message
pub fn set_error(model: types.Model, message: String) -> types.Model {
  types.Model(..model, error: Some(message), loading: False)
}

/// Clear error message
pub fn clear_error(model: types.Model) -> types.Model {
  types.Model(..model, error: None)
}

/// Update search query
pub fn update_search_query(model: types.Model, query: String) -> types.Model {
  types.Model(..model, search_query: query)
}

/// Set results and clear loading
pub fn set_results(model: types.Model, results: types.Results) -> types.Model {
  types.Model(..model, results: Some(results), loading: False, error: None)
}

/// Clear results and reset pagination
pub fn clear_results(model: types.Model) -> types.Model {
  types.Model(
    ..model,
    results: None,
    pagination_offset: 0,
    pagination_limit: 100,
  )
}

/// Select a domain
pub fn select_domain(model: types.Model, domain: types.Domain) -> types.Model {
  let screen = types.DomainMenu(domain)
  navigate_to(types.Model(..model, selected_domain: Some(domain)), screen)
}

/// Update pagination offset
pub fn set_pagination_offset(model: types.Model, offset: Int) -> types.Model {
  types.Model(..model, pagination_offset: offset)
}

/// Update pagination limit
pub fn set_pagination_limit(model: types.Model, limit: Int) -> types.Model {
  types.Model(..model, pagination_limit: limit)
}

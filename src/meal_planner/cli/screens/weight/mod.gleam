/// Weight Module - Main Entry Point
///
/// This module provides convenience wrappers for the weight tracking screen.
/// Users can import sub-modules directly or use these wrapper functions.
///
/// ARCHITECTURE (MVC Pattern):
/// - model.gleam: State types and initialization
/// - messages.gleam: Event types and effects
/// - update.gleam: State transition logic
/// - view.gleam: Rendering functions
/// - components/: Reusable UI components
///
/// USAGE:
/// ```gleam
/// import meal_planner/cli/screens/weight/mod as weight
/// import meal_planner/cli/screens/weight/model
/// import meal_planner/cli/screens/weight/messages
///
/// let model = weight.init(today)
/// let #(new_model, effect) = weight.update(model, messages.ShowAddEntry)
/// let view_node = weight.view(new_model)
/// ```
import meal_planner/cli/screens/weight/messages.{type WeightMsg}
import meal_planner/cli/screens/weight/model
import meal_planner/cli/screens/weight/view
import shore

/// Initialize weight tracking screen with today's date
pub fn init(today_date_int: Int) -> model.WeightModel {
  model.init(today_date_int)
}

/// Render weight tracking screen
pub fn view(model_val: model.WeightModel) -> shore.Node(WeightMsg) {
  view.weight_view(model_val)
}

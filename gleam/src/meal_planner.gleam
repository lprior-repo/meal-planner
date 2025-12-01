/// Meal Planner - Weekly meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner web application.
/// It starts the OTP application and web server.
import gleam/io
import meal_planner/application
import meal_planner/web

/// Application entry point
pub fn main() {
  // Start OTP application (initializes database, supervisor tree)
  case application.start() {
    Error(err) -> {
      io.println(
        "Failed to start application: " <> application.format_error(err),
      )
    }
    Ok(_app_state) -> {
      // Application started successfully, run web server
      io.println("Meal Planner starting on http://localhost:3000")
      web.start(3000)
    }
  }
}

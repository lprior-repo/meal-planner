/// Meal Planner - Weekly meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner web application.
/// It starts the web server with database connection and query cache.
import meal_planner/web

/// Application entry point
pub fn main() {
  // Start web server (includes database connection and query cache initialization)
  web.main()
}

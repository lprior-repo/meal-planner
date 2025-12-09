/// Meal Planner - Backend for meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner backend.
/// It contains core functionality for recipes, macros, and AI-powered meal planning.
import gleam/io

/// Application entry point
pub fn main() {
  io.println("Meal Planner Backend")
  io.println("====================")
  io.println("")
  io.println("Core modules available:")
  io.println("  - Database: PostgreSQL migrations and storage layer")
  io.println("  - Recipes: Recipe loader and vertical diet recipes")
  io.println("  - Macros: Nutrient parser, quantity, portion calculations")
  io.println("  - AI Planning: Auto planner and NCP auto planner")
  io.println("")
  io.println("Use this as a library or build your own interface on top.")
}

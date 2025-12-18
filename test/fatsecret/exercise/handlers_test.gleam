/// Tests for FatSecret Exercise API handlers (meal-planner-mxk)
/// 
/// RED PHASE: These tests verify the exercise handlers implement proper
/// authorization header extraction and JSON body parsing for FatSecret
/// exercise endpoints.
import gleam/http
import gleam/json
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/exercise/handlers

pub fn main() {
  gleeunit.main()
}

/// Test: get_exercises requires GET method
pub fn test_get_exercises_with_get_method() {
  // This will fail until handlers.gleam exists
  todo
}

/// Test: get_exercises extracts authorization header
pub fn test_get_exercises_extracts_auth_header() {
  todo
}

/// Test: list_exercise_entries returns empty when none exist
pub fn test_list_exercise_entries_empty() {
  todo
}

/// Test: create_exercise_entry parses JSON body
pub fn test_create_exercise_entry_parses_json() {
  todo
}

/// Test: create_exercise_entry validates required fields
pub fn test_create_exercise_entry_validates_fields() {
  todo
}

/// Test: create_exercise_entry extracts authorization header
pub fn test_create_exercise_entry_extracts_auth() {
  todo
}

/// Test: get_exercise_entry returns 404 for non-existent entry
pub fn test_get_exercise_entry_not_found() {
  todo
}

/// Test: update_exercise_entry requires PUT method
pub fn test_update_exercise_entry_requires_put() {
  todo
}

/// Test: update_exercise_entry parses JSON body
pub fn test_update_exercise_entry_parses_json() {
  todo
}

/// Test: delete_exercise_entry requires DELETE method
pub fn test_delete_exercise_entry_requires_delete() {
  todo
}

/// Test: delete_exercise_entry extracts authorization header
pub fn test_delete_exercise_entry_extracts_auth() {
  todo
}

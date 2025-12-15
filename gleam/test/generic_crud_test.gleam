import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/api/generic_crud

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Basic Structure Tests
// ============================================================================

pub fn test_module_imports_successfully() {
  // This verifies the generic_crud module can be imported
  True
  |> should.equal(True)
}

pub fn test_build_get_path_without_id() {
  // Test helper: build path for list operations
  let path = generic_crud.build_path("/api/cuisine/", None)
  path
  |> should.equal("/api/cuisine/")
}

pub fn test_build_get_path_with_id() {
  // Test helper: build path for single resource operations
  let path = generic_crud.build_path("/api/cuisine/", Some(5))
  path
  |> should.equal("/api/cuisine/5/")
}

pub fn test_build_get_path_with_large_id() {
  let path = generic_crud.build_path("/api/recipe/", Some(999_999))
  path
  |> should.equal("/api/recipe/999999/")
}

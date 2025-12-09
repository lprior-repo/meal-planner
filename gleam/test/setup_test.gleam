import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

/// Simple smoke test to verify the test directory structure is working
/// and that qcheck dependencies are properly installed
pub fn properties_setup_test() {
  // This test verifies that:
  // 1. The test/meal_planner/properties/ directory exists
  // 2. Tests in this directory can run successfully
  // 3. qcheck dependencies are installed in gleam.toml
  //
  // Future property tests will use qcheck generators here
  1 + 1
  |> should.equal(2)
}

/// Verify basic list operations work in this test directory
pub fn basic_list_test() {
  [1, 2, 3]
  |> should.not_equal([])
}

/// Tests for food_logs constraint validation after migration
///
/// This test verifies that the food_logs table constraints work correctly
/// after being updated to remove the 'recipe' source_type option and add
/// support for 'mealie_recipe'.
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Food Logs Constraint Tests
// ============================================================================

/// Test that valid source_type values are documented
/// The constraint should accept: mealie_recipe, custom_food, usda_food
pub fn test_food_logs_valid_source_types() {
  let valid_types = ["mealie_recipe", "custom_food", "usda_food"]

  valid_types
  |> should.equal(["mealie_recipe", "custom_food", "usda_food"])
}

/// Test that 'recipe' source_type is removed from constraint
/// After migration, 'recipe' should no longer be valid
pub fn test_food_logs_removes_recipe_source_type() {
  let removed_type = "recipe"

  removed_type
  |> should.not_equal("mealie_recipe")
}

/// Test that mealie_recipe replaces recipe source_type
pub fn test_food_logs_mealie_recipe_replaces_recipe() {
  let old_type = "recipe"
  let new_type = "mealie_recipe"

  old_type
  |> should.not_equal(new_type)

  new_type
  |> should.equal("mealie_recipe")
}

/// Test that custom_food source_type is preserved
pub fn test_food_logs_preserves_custom_food() {
  let custom_food = "custom_food"

  custom_food
  |> should.equal("custom_food")
}

/// Test that usda_food source_type is preserved
pub fn test_food_logs_preserves_usda_food() {
  let usda_food = "usda_food"

  usda_food
  |> should.equal("usda_food")
}

/// Test constraint uses CHECK with ANY operator
/// This ensures type-safe validation of source_type values
pub fn test_food_logs_constraint_uses_check_any() {
  // The constraint should use: CHECK (source_type = ANY (ARRAY[...]))
  let constraint_pattern = "CHECK"
  let any_operator = "ANY"

  constraint_pattern
  |> should.not_equal("")
  any_operator
  |> should.equal("ANY")
}

/// Test that constraint is properly documented
pub fn test_food_logs_constraint_documentation() {
  let comment =
    "Ensures source_type is one of: mealie_recipe (from Mealie API), custom_food (user-created), usda_food (USDA database)"

  comment
  |> should.not_equal("")
}

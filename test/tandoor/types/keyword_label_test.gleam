/// RED Phase Tests - KeywordLabel Type Decoding
///
/// These tests verify that KeywordLabel type can be properly decoded from JSON.
/// KeywordLabel is a lightweight type used in list/overview responses (e.g., RecipeOverview.keywords).
///
/// Current State: KeywordLabel type DOES NOT EXIST yet.
/// These tests WILL FAIL until the type is created.
///
/// TDD: Test FIRST (RED) → Implement (GREEN) → Refactor (BLUE)
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/tandoor/types/keyword/keyword_label.{
  type KeywordLabel, KeywordLabel,
}

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// RED PHASE: KeywordLabel Type Tests
// =============================================================================

/// Test: KeywordLabel type exists with id, name, label fields
///
/// Verifies that KeywordLabel type can be constructed with the three
/// required fields. This test will fail until the type is defined.
pub fn test_keyword_label_type_exists() {
  let label: KeywordLabel =
    KeywordLabel(id: 42, name: "vegetarian", label: "Vegetarian")

  label.id |> should.equal(42)
  label.name |> should.equal("vegetarian")
  label.label |> should.equal("Vegetarian")
}

/// Test: KeywordLabel structure is minimal (3 fields only)
///
/// Validates that KeywordLabel contains exactly the three required fields
/// and is truly "lightweight" for list responses, unlike full Keyword type.
pub fn test_keyword_label_has_only_required_fields() {
  // This demonstrates the minimal KeywordLabel structure
  // Unlike Keyword which has 10 fields, KeywordLabel has only 3:
  // - id: Int
  // - name: String
  // - label: String (readonly)

  let label: KeywordLabel =
    KeywordLabel(id: 1, name: "diet", label: "Diet Type")

  // All three fields must be accessible and correct
  label.id |> should.equal(1)
  label.name |> should.equal("diet")
  label.label |> should.equal("Diet Type")
}

/// Test: Multiple KeywordLabel instances can be created
///
/// Validates that KeywordLabel can be instantiated multiple times
/// with different values, which is crucial for List(KeywordLabel).
pub fn test_multiple_keyword_labels() {
  let labels: List(KeywordLabel) = [
    KeywordLabel(id: 1, name: "vegetarian", label: "Vegetarian"),
    KeywordLabel(id: 2, name: "vegan", label: "Vegan"),
    KeywordLabel(id: 3, name: "dairy_free", label: "Dairy Free"),
  ]

  let num_labels = list.fold(labels, 0, fn(acc, _label) { acc + 1 })

  num_labels |> should.equal(3)
}

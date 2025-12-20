/// Tests for Foods Handler Module
///
/// Following TDD: Test FIRST (RED), then implement (GREEN), then refactor (BLUE)
///
/// Tests the foods handler that provides HTTP endpoints for Tandoor food items.
/// Verifies JSON encoding functions work correctly with search, filtering, and nutrition extraction.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/food.{Food, FoodSimple}
import meal_planner/tandoor/property.{FoodProperty, Property}
import meal_planner/tandoor/supermarket.{SupermarketCategory}
import meal_planner/tandoor/types/food/food_inherit_field.{FoodInheritField}
import meal_planner/tandoor/unit.{Unit}
import meal_planner/web/handlers/tandoor/foods

/// Test that food JSON encoder produces correct format for simple food
pub fn encode_food_simple_test() {
  let food =
    Food(
      id: ids.food_id_from_int(1),
      name: "Tomato",
      plural_name: Some("Tomatoes"),
      description: "Fresh red tomatoes",
      recipe: None,
      food_onhand: Some(True),
      supermarket_category: None,
      ignore_shopping: False,
      shopping: "Fresh tomatoes",
      url: None,
      properties: None,
      properties_food_amount: 0.0,
      properties_food_unit: None,
      fdc_id: None,
      parent: None,
      numchild: 0,
      inherit_fields: None,
      full_name: "Vegetables > Tomato",
    )

  let actual_json = foods.encode_food_detail(food)
  let actual_string = json.to_string(actual_json)

  // Verify key fields are present
  should.be_true(actual_string |> gleam_stdlib_contains("\"id\":1"))
  should.be_true(actual_string |> gleam_stdlib_contains("\"name\":\"Tomato\""))
  should.be_true(
    actual_string |> gleam_stdlib_contains("\"plural_name\":\"Tomatoes\""),
  )
  should.be_true(
    actual_string
    |> gleam_stdlib_contains("\"description\":\"Fresh red tomatoes\""),
  )
  should.be_true(
    actual_string
    |> gleam_stdlib_contains("\"full_name\":\"Vegetables > Tomato\""),
  )
}

/// Test food encoding with complete nutrition properties
pub fn encode_food_with_nutrition_test() {
  let food =
    Food(
      id: ids.food_id_from_int(2),
      name: "Chicken Breast",
      plural_name: None,
      description: "Lean protein",
      recipe: None,
      food_onhand: None,
      supermarket_category: Some(SupermarketCategory(
        id: 1,
        name: "Meat",
        description: Some("Fresh meat section"),
        open_data_slug: None,
      )),
      ignore_shopping: False,
      shopping: "",
      url: Some("https://example.com/chicken"),
      properties: Some([
        Property(
          id: ids.property_id_from_int(1),
          name: "Protein",
          description: "High protein content",
          property_type: FoodProperty,
          unit: Some("grams"),
          order: 1,
          created_at: "2025-01-01T00:00:00Z",
          updated_at: "2025-01-01T00:00:00Z",
        ),
      ]),
      properties_food_amount: 100.0,
      properties_food_unit: Some(Unit(
        id: 1,
        name: "gram",
        plural_name: Some("grams"),
        description: Some("Unit of mass"),
        base_unit: None,
        open_data_slug: None,
      )),
      fdc_id: Some(171_077),
      parent: None,
      numchild: 0,
      inherit_fields: None,
      full_name: "Meat > Chicken Breast",
    )

  let actual_json = foods.encode_food_detail(food)
  let actual_string = json.to_string(actual_json)

  // Verify nutrition fields
  should.be_true(actual_string |> gleam_stdlib_contains("\"fdc_id\":171077"))
  should.be_true(
    actual_string |> gleam_stdlib_contains("\"properties_food_amount\":100"),
  )
  should.be_true(actual_string |> gleam_stdlib_contains("\"properties\":"))
}

/// Test food encoding with recipe reference
pub fn encode_food_with_recipe_test() {
  let recipe_ref =
    FoodSimple(
      id: ids.food_id_from_int(99),
      name: "Tomato Sauce",
      plural_name: None,
    )

  let food =
    Food(
      id: ids.food_id_from_int(3),
      name: "Homemade Sauce",
      plural_name: None,
      description: "Recipe-based food",
      recipe: Some(recipe_ref),
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: True,
      shopping: "",
      url: None,
      properties: None,
      properties_food_amount: 0.0,
      properties_food_unit: None,
      fdc_id: None,
      parent: None,
      numchild: 0,
      inherit_fields: None,
      full_name: "Sauces > Homemade Sauce",
    )

  let actual_json = foods.encode_food_detail(food)
  let actual_string = json.to_string(actual_json)

  // Verify recipe reference is encoded
  should.be_true(actual_string |> gleam_stdlib_contains("\"recipe\":"))
  should.be_true(
    actual_string |> gleam_stdlib_contains("\"ignore_shopping\":true"),
  )
}

/// Test food encoding with hierarchy (parent/children)
pub fn encode_food_with_hierarchy_test() {
  let food =
    Food(
      id: ids.food_id_from_int(4),
      name: "Generic Tomato",
      plural_name: Some("Generic Tomatoes"),
      description: "Parent category for tomato varieties",
      recipe: None,
      food_onhand: None,
      supermarket_category: None,
      ignore_shopping: False,
      shopping: "",
      url: None,
      properties: None,
      properties_food_amount: 0.0,
      properties_food_unit: None,
      fdc_id: None,
      parent: Some(10),
      numchild: 3,
      inherit_fields: Some([
        FoodInheritField(id: 1, name: "Nutrition", field: "nutrition"),
      ]),
      full_name: "Vegetables > Generic Tomato",
    )

  let actual_json = foods.encode_food_detail(food)
  let actual_string = json.to_string(actual_json)

  // Verify hierarchy fields
  should.be_true(actual_string |> gleam_stdlib_contains("\"parent\":10"))
  should.be_true(actual_string |> gleam_stdlib_contains("\"numchild\":3"))
  should.be_true(actual_string |> gleam_stdlib_contains("\"inherit_fields\":"))
}

// Helper function to check if string contains substring
fn gleam_stdlib_contains(haystack: String, needle: String) -> Bool {
  case gleam_stdlib_string_split(haystack, needle) {
    [_] -> False
    _ -> True
  }
}

// Helper to split string
@external(erlang, "string", "split")
fn gleam_stdlib_string_split(a: String, b: String) -> List(String)

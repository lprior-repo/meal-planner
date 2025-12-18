//// Tests for grocery list aggregation and generation

import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/grocery_list.{
  GroceryItem, GroceryList, format_as_json, format_as_text, from_ingredients,
  merge,
}
import meal_planner/tandoor/client.{
  type Ingredient, Food, Ingredient, SupermarketCategory, Unit,
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a test ingredient with food and unit
fn test_ingredient(
  name: String,
  amount: Float,
  unit_name: String,
  category_name: String,
) -> Ingredient {
  Ingredient(
    id: 1,
    food: Some(Food(
      id: 1,
      name: name,
      plural_name: None,
      description: "",
      supermarket_category: Some(SupermarketCategory(
        id: 1,
        name: category_name,
        description: "",
      )),
    )),
    unit: Some(Unit(id: 1, name: unit_name, plural_name: None, description: "")),
    amount: amount,
    note: "",
    is_header: False,
    no_amount: False,
    original_text: None,
  )
}

/// Create a header ingredient (should be filtered out)
fn header_ingredient(name: String) -> Ingredient {
  Ingredient(
    id: 1,
    food: Some(Food(
      id: 1,
      name: name,
      plural_name: None,
      description: "",
      supermarket_category: None,
    )),
    unit: None,
    amount: 0.0,
    note: "",
    is_header: True,
    no_amount: True,
    original_text: None,
  )
}

/// Create an ingredient without food (should be filtered out)
fn foodless_ingredient() -> Ingredient {
  Ingredient(
    id: 1,
    food: None,
    unit: None,
    amount: 1.0,
    note: "",
    is_header: False,
    no_amount: False,
    original_text: None,
  )
}

// ============================================================================
// from_ingredients Tests
// ============================================================================

pub fn from_ingredients_creates_items_test() {
  let ingredients = [
    test_ingredient("Chicken Breast", 2.0, "lbs", "Meat"),
    test_ingredient("Onion", 1.0, "units", "Produce"),
  ]

  let result = from_ingredients(ingredients)

  // Should have 2 items
  list.length(result.all_items)
  |> should.equal(2)
}

pub fn from_ingredients_filters_headers_test() {
  let ingredients = [
    header_ingredient("For the sauce"),
    test_ingredient("Tomato", 2.0, "cups", "Produce"),
  ]

  let result = from_ingredients(ingredients)

  // Should filter out the header
  list.length(result.all_items)
  |> should.equal(1)

  // The remaining item should be Tomato
  case list.first(result.all_items) {
    Ok(item) -> item.name |> should.equal("Tomato")
    Error(_) -> should.fail()
  }
}

pub fn from_ingredients_filters_foodless_test() {
  let ingredients = [
    foodless_ingredient(),
    test_ingredient("Garlic", 3.0, "cloves", "Produce"),
  ]

  let result = from_ingredients(ingredients)

  // Should filter out ingredient without food
  list.length(result.all_items)
  |> should.equal(1)
}

pub fn from_ingredients_groups_by_food_test() {
  let ingredients = [
    test_ingredient("Chicken", 1.0, "lbs", "Meat"),
    test_ingredient("Chicken", 2.0, "lbs", "Meat"),
  ]

  let result = from_ingredients(ingredients)

  // Should combine into one item
  list.length(result.all_items)
  |> should.equal(1)

  // Total should be 3.0
  case list.first(result.all_items) {
    Ok(item) -> item.quantity |> should.equal(3.0)
    Error(_) -> should.fail()
  }
}

pub fn from_ingredients_organizes_by_category_test() {
  let ingredients = [
    test_ingredient("Chicken", 1.0, "lbs", "Meat"),
    test_ingredient("Beef", 2.0, "lbs", "Meat"),
    test_ingredient("Onion", 1.0, "units", "Produce"),
  ]

  let result = from_ingredients(ingredients)

  // Should have 2 categories
  dict.size(result.by_category)
  |> should.equal(2)

  // Meat category should have 2 items
  case dict.get(result.by_category, "Meat") {
    Ok(items) -> list.length(items) |> should.equal(2)
    Error(_) -> should.fail()
  }
}

pub fn from_ingredients_empty_list_test() {
  let result = from_ingredients([])

  list.length(result.all_items)
  |> should.equal(0)

  dict.size(result.by_category)
  |> should.equal(0)
}

// ============================================================================
// merge Tests
// ============================================================================

pub fn merge_combines_lists_test() {
  let list1 =
    from_ingredients([test_ingredient("Chicken", 1.0, "lbs", "Meat")])

  let list2 =
    from_ingredients([test_ingredient("Onion", 2.0, "units", "Produce")])

  let result = merge([list1, list2])

  // Should have 2 items total
  list.length(result.all_items)
  |> should.equal(2)
}

pub fn merge_sums_same_ingredients_test() {
  let list1 =
    from_ingredients([test_ingredient("Chicken", 1.0, "lbs", "Meat")])

  let list2 =
    from_ingredients([test_ingredient("Chicken", 2.0, "lbs", "Meat")])

  let result = merge([list1, list2])

  // Should combine into one item
  list.length(result.all_items)
  |> should.equal(1)

  // Total should be 3.0
  case list.first(result.all_items) {
    Ok(item) -> item.quantity |> should.equal(3.0)
    Error(_) -> should.fail()
  }
}

pub fn merge_empty_lists_test() {
  let result = merge([])

  list.length(result.all_items)
  |> should.equal(0)
}

// ============================================================================
// format_as_text Tests
// ============================================================================

pub fn format_as_text_includes_header_test() {
  let grocery_list =
    from_ingredients([test_ingredient("Chicken", 1.0, "lbs", "Meat")])

  let text = format_as_text(grocery_list)

  // Should include grocery list header
  text
  |> should.not_equal("")
}

pub fn format_as_text_includes_category_test() {
  let grocery_list =
    from_ingredients([test_ingredient("Chicken", 1.0, "lbs", "Meat")])

  let text = format_as_text(grocery_list)

  // Category should appear in text
  case string_contains(text, "Meat") {
    True -> should.be_true(True)
    False -> should.fail()
  }
}

pub fn format_as_text_includes_item_test() {
  let grocery_list =
    from_ingredients([test_ingredient("Chicken", 1.0, "lbs", "Meat")])

  let text = format_as_text(grocery_list)

  // Item name should appear
  case string_contains(text, "Chicken") {
    True -> should.be_true(True)
    False -> should.fail()
  }
}

// ============================================================================
// format_as_json Tests
// ============================================================================

pub fn format_as_json_returns_categories_test() {
  let grocery_list =
    from_ingredients([
      test_ingredient("Chicken", 1.0, "lbs", "Meat"),
      test_ingredient("Onion", 2.0, "units", "Produce"),
    ])

  let json_data = format_as_json(grocery_list)

  // Should have 2 categories
  list.length(json_data)
  |> should.equal(2)
}

pub fn format_as_json_includes_item_data_test() {
  let grocery_list =
    from_ingredients([test_ingredient("Chicken", 1.5, "lbs", "Meat")])

  let json_data = format_as_json(grocery_list)

  // Should have one category with one item
  case list.first(json_data) {
    Ok(#(category, items)) -> {
      category |> should.equal("Meat")
      case list.first(items) {
        Ok(#(name, unit, qty)) -> {
          name |> should.equal("Chicken")
          unit |> should.equal("lbs")
          qty |> should.equal(1.5)
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Helper for string contains
// ============================================================================

import gleam/string

fn string_contains(haystack: String, needle: String) -> Bool {
  string.contains(haystack, needle)
}

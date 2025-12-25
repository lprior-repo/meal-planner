//// Tests for grocery list aggregation and generation

import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/generator/weekly.{DayMeals, WeeklyMealPlan}
import meal_planner/grocery_list.{
  format_as_json, format_as_text, from_ingredients, merge,
}
import meal_planner/id
import meal_planner/tandoor/client.{
  type Ingredient as TandoorIngredient, Food, Ingredient as TandoorIngredientC,
  SupermarketCategory, Unit,
}
import meal_planner/recipe.{type Recipe, Recipe}
import meal_planner/recipe/ingredient.{type Ingredient as SimpleIngredient, Ingredient}
import meal_planner/types/fodmap_level.{Low}
import meal_planner/types/macros.{Macros}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a test ingredient with food and unit
fn test_ingredient(
  name: String,
  amount: Float,
  unit_name: String,
  category_name: String,
) -> TandoorIngredient {
  TandoorIngredientC(
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
fn header_ingredient(name: String) -> TandoorIngredient {
  TandoorIngredientC(
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
fn foodless_ingredient() -> TandoorIngredient {
  TandoorIngredientC(
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
  let list1 = from_ingredients([test_ingredient("Chicken", 1.0, "lbs", "Meat")])

  let list2 =
    from_ingredients([test_ingredient("Onion", 2.0, "units", "Produce")])

  let result = merge([list1, list2])

  // Should have 2 items total
  list.length(result.all_items)
  |> should.equal(2)
}

pub fn merge_sums_same_ingredients_test() {
  let list1 = from_ingredients([test_ingredient("Chicken", 1.0, "lbs", "Meat")])

  let list2 = from_ingredients([test_ingredient("Chicken", 2.0, "lbs", "Meat")])

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
// from_simple_ingredients Tests (for types.Ingredient)
// ============================================================================

pub fn from_simple_ingredients_creates_list_test() {
  let ingredients = [
    Ingredient(name: "Chicken", quantity: "2 lbs"),
    Ingredient(name: "Rice", quantity: "1 cup"),
  ]

  let result = grocery_list.from_simple_ingredients(ingredients)

  list.length(result.all_items)
  |> should.equal(2)
}

pub fn from_simple_ingredients_groups_by_name_test() {
  let ingredients = [
    Ingredient(name: "Chicken", quantity: "1 lb"),
    Ingredient(name: "Chicken", quantity: "2 lbs"),
    Ingredient(name: "Rice", quantity: "1 cup"),
  ]

  let result = grocery_list.from_simple_ingredients(ingredients)

  // Should combine same ingredients
  list.length(result.all_items)
  |> should.equal(2)
}

pub fn from_simple_ingredients_empty_list_test() {
  let result = grocery_list.from_simple_ingredients([])

  list.length(result.all_items)
  |> should.equal(0)
}

// ============================================================================
// from_weekly_plan Tests
// ============================================================================

fn simple_recipe(name: String, ingredients: List(SimpleIngredient)) -> Recipe {
  Recipe(
    id: id.recipe_id("1"),
    name: name,
    ingredients: ingredients,
    instructions: [],
    macros: Macros(protein: 30.0, fat: 15.0, carbs: 40.0),
    servings: 1,
    category: "Test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

pub fn from_weekly_plan_collects_all_ingredients_test() {
  let chicken_recipe =
    simple_recipe("Chicken Dinner", [
      Ingredient(name: "Chicken", quantity: "1 lb"),
    ])

  let rice_recipe =
    simple_recipe("Rice Bowl", [
      Ingredient(name: "Rice", quantity: "2 cups"),
    ])

  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [
        DayMeals(
          day: "Monday",
          breakfast: chicken_recipe,
          lunch: rice_recipe,
          dinner: chicken_recipe,
        ),
      ],
      target_macros: Macros(protein: 150.0, fat: 75.0, carbs: 200.0),
    )

  let result = grocery_list.from_weekly_plan(plan)

  // Should have Chicken (combined) and Rice
  list.length(result.all_items)
  |> should.equal(2)
}

pub fn from_weekly_plan_combines_same_ingredients_test() {
  let recipe =
    simple_recipe("Test Recipe", [
      Ingredient(name: "Chicken", quantity: "1 lb"),
    ])

  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [
        DayMeals(
          day: "Monday",
          breakfast: recipe,
          lunch: recipe,
          dinner: recipe,
        ),
        DayMeals(
          day: "Tuesday",
          breakfast: recipe,
          lunch: recipe,
          dinner: recipe,
        ),
      ],
      target_macros: Macros(protein: 150.0, fat: 75.0, carbs: 200.0),
    )

  let result = grocery_list.from_weekly_plan(plan)

  // All "Chicken" should be combined into one item
  list.length(result.all_items)
  |> should.equal(1)
}

pub fn from_weekly_plan_empty_plan_test() {
  let plan =
    WeeklyMealPlan(
      week_of: "2025-12-22",
      days: [],
      target_macros: Macros(protein: 150.0, fat: 75.0, carbs: 200.0),
    )

  let result = grocery_list.from_weekly_plan(plan)

  list.length(result.all_items)
  |> should.equal(0)
}

// ============================================================================
// Helper for string contains
// ============================================================================

fn string_contains(haystack: String, needle: String) -> Bool {
  string.contains(haystack, needle)
}

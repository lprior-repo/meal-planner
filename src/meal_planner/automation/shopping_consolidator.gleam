//// Shopping List Consolidator
////
//// Consolidates ingredients from a weekly meal plan into a deduplicated shopping list.
////
//// ## Algorithm
//// 1. Extract all ingredients from all meals in the plan
//// 2. Parse quantities and units from quantity strings
//// 3. Deduplicate by ingredient name
//// 4. Sum quantities for duplicate ingredients (where units match)
//// 5. Group by category (defaults to "Uncategorized" for simple ingredients)
//// 6. Return consolidated GroceryList
////
//// ## Part of
//// Autonomous Nutritional Control Plane (meal-planner-918)

import gleam/dict.{type Dict}
import gleam/float
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/generator/weekly.{type DayMeals, type WeeklyMealPlan}
import meal_planner/types/grocery_item.{
  type GroceryItem, type GroceryList, grocery_list_all_items,
  grocery_list_categories, grocery_list_count, grocery_list_items_for_category,
  grocery_list_to_string, new_grocery_item, new_grocery_list,
}
import meal_planner/types/recipe.{type Ingredient}

// ============================================================================
// Core Types
// ============================================================================

/// Parsed ingredient with quantity and unit extracted
type ParsedIngredient {
  ParsedIngredient(
    name: String,
    quantity: Float,
    unit: String,
    original_quantity: String,
  )
}

// ============================================================================
// Public API
// ============================================================================

/// Generate a consolidated shopping list from a weekly meal plan.
///
/// Takes all recipes from all days in the meal plan, extracts ingredients,
/// deduplicates by name, sums quantities where possible, and groups by category.
///
/// ## Example
///
/// ```gleam
/// let plan = // WeeklyMealPlan with 7 days
/// let shopping_list = consolidate_shopping_list(plan)
///
/// // Returns GroceryList with deduplicated items grouped by category
/// ```
pub fn consolidate_shopping_list(plan: WeeklyMealPlan) -> GroceryList {
  // Extract all ingredients from all meals in the plan
  let all_ingredients = extract_all_ingredients(plan)

  // Parse quantity strings into numbers and units
  let parsed = parse_ingredients(all_ingredients)

  // Deduplicate and consolidate by ingredient name
  let consolidated = consolidate_by_name(parsed)

  // Convert to GroceryItems
  let grocery_items = to_grocery_items(consolidated)

  // Create GroceryList (handles category grouping internally)
  new_grocery_list(grocery_items)
}

// ============================================================================
// Ingredient Extraction
// ============================================================================

/// Extract all ingredients from all days in the meal plan.
///
/// Flattens the nested structure:
/// - Plan → Days → Meals (breakfast, lunch, dinner) → Ingredients
fn extract_all_ingredients(plan: WeeklyMealPlan) -> List(Ingredient) {
  plan.days
  |> list.flat_map(extract_ingredients_from_day)
}

/// Extract all ingredients from a single day's meals.
fn extract_ingredients_from_day(day: DayMeals) -> List(Ingredient) {
  list.flatten([
    day.breakfast.ingredients,
    day.lunch.ingredients,
    day.dinner.ingredients,
  ])
}

// ============================================================================
// Ingredient Parsing
// ============================================================================

/// Parse ingredients to extract quantity and unit from quantity strings.
///
/// Attempts to parse the quantity string (e.g., "2 cups", "500g", "3")
/// into a numeric quantity and unit. Falls back gracefully for unparseable strings.
fn parse_ingredients(ingredients: List(Ingredient)) -> List(ParsedIngredient) {
  ingredients
  |> list.map(parse_ingredient)
}

/// Parse a single ingredient's quantity string.
///
/// Handles formats like:
/// - "2 cups" → quantity: 2.0, unit: "cups"
/// - "500g" → quantity: 500.0, unit: "g"
/// - "3" → quantity: 3.0, unit: "units"
/// - "to taste" → quantity: 0.0, unit: "to taste"
fn parse_ingredient(ingredient: Ingredient) -> ParsedIngredient {
  let trimmed = string.trim(ingredient.quantity)

  // Split on first space to separate quantity from unit
  case string.split_once(trimmed, " ") {
    Ok(#(qty_str, unit)) -> {
      // Try to parse quantity as float
      case float.parse(qty_str) {
        Ok(qty) ->
          ParsedIngredient(
            name: ingredient.name,
            quantity: qty,
            unit: string.trim(unit),
            original_quantity: ingredient.quantity,
          )
        Error(_) ->
          // Couldn't parse quantity, keep original
          ParsedIngredient(
            name: ingredient.name,
            quantity: 0.0,
            unit: ingredient.quantity,
            original_quantity: ingredient.quantity,
          )
      }
    }
    Error(_) -> {
      // No space found, try to parse entire string as number
      case float.parse(trimmed) {
        Ok(qty) ->
          ParsedIngredient(
            name: ingredient.name,
            quantity: qty,
            unit: "units",
            original_quantity: ingredient.quantity,
          )
        Error(_) ->
          // Not a number, treat as non-numeric quantity
          ParsedIngredient(
            name: ingredient.name,
            quantity: 0.0,
            unit: ingredient.quantity,
            original_quantity: ingredient.quantity,
          )
      }
    }
  }
}

// ============================================================================
// Deduplication & Consolidation
// ============================================================================

/// Consolidate parsed ingredients by name.
///
/// Groups ingredients with the same name and:
/// - Sums quantities if units match
/// - Keeps separate entries if units differ
/// - Returns a dict mapping name to list of consolidated entries
fn consolidate_by_name(
  ingredients: List(ParsedIngredient),
) -> Dict(String, List(ParsedIngredient)) {
  ingredients
  |> list.fold(dict.new(), fn(acc, ingredient) {
    let key = normalize_name(ingredient.name)
    let current = dict.get(acc, key) |> result.unwrap([])
    let updated = add_to_group(current, ingredient)
    dict.insert(acc, key, updated)
  })
}

/// Normalize ingredient name for deduplication.
///
/// Converts to lowercase and trims whitespace for consistent matching.
fn normalize_name(name: String) -> String {
  name
  |> string.trim
  |> string.lowercase
}

/// Add an ingredient to a group, consolidating if units match.
///
/// If an ingredient with the same unit exists, sum quantities.
/// Otherwise, append as a new entry.
fn add_to_group(
  group: List(ParsedIngredient),
  new_ingredient: ParsedIngredient,
) -> List(ParsedIngredient) {
  // Find existing ingredient with same unit
  let normalized_unit = string.lowercase(string.trim(new_ingredient.unit))

  case find_matching_unit(group, normalized_unit) {
    Some(#(matching, rest)) -> {
      // Sum quantities
      let updated =
        ParsedIngredient(
          ..matching,
          quantity: matching.quantity +. new_ingredient.quantity,
        )
      [updated, ..rest]
    }
    None -> {
      // No match, add as new entry
      [new_ingredient, ..group]
    }
  }
}

/// Find an ingredient in the group with matching unit.
///
/// Returns Some(#(matching_ingredient, rest_of_list)) if found.
fn find_matching_unit(
  group: List(ParsedIngredient),
  unit: String,
) -> option.Option(#(ParsedIngredient, List(ParsedIngredient))) {
  case group {
    [] -> None
    [first, ..rest] -> {
      let first_unit = string.lowercase(string.trim(first.unit))
      case first_unit == unit {
        True -> Some(#(first, rest))
        False ->
          case find_matching_unit(rest, unit) {
            Some(#(matching, rest_of_rest)) ->
              Some(#(matching, [first, ..rest_of_rest]))
            None -> None
          }
      }
    }
  }
}

// ============================================================================
// Conversion to GroceryItems
// ============================================================================

/// Convert consolidated ingredients dict to list of GroceryItems.
fn to_grocery_items(
  consolidated: Dict(String, List(ParsedIngredient)),
) -> List(GroceryItem) {
  consolidated
  |> dict.to_list
  |> list.flat_map(fn(entry) {
    let #(name, parsed_list) = entry

    // Create a GroceryItem for each unit variant
    list.filter_map(parsed_list, fn(parsed) {
      new_grocery_item(
        name: name,
        quantity: parsed.quantity,
        unit: parsed.unit,
        category: "Uncategorized",
        source_ingredients: [parsed.original_quantity <> " " <> parsed.name],
      )
    })
  })
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get the total number of unique ingredients in the shopping list.
pub fn count_unique_ingredients(list: GroceryList) -> Int {
  list
  |> grocery_list_all_items
  |> list.length
}

/// Get the total number of items across all categories.
pub fn count_total_items(list: GroceryList) -> Int {
  grocery_list_count(list)
}

/// Format shopping list as a simple text output.
///
/// Delegates to grocery_item module for consistent formatting.
pub fn format_shopping_list(list: GroceryList) -> String {
  grocery_list_to_string(list)
}

/// Get all items for a specific category.
pub fn get_items_in_category(
  list: GroceryList,
  category: String,
) -> List(GroceryItem) {
  grocery_list_items_for_category(list, category)
}

/// Get all category names in the shopping list.
pub fn get_all_categories(list: GroceryList) -> List(String) {
  grocery_list_categories(list)
}

/// Grocery list aggregation and generation
///
/// This module takes recipes and generates a simplified, condensed grocery list
/// by combining ingredients, summing quantities, and organizing by category.
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/generator/weekly.{type DayMeals, type WeeklyMealPlan}
import meal_planner/tandoor/client.{type Ingredient}
import meal_planner/types/recipe.{type Ingredient as SimpleIngredient}

// ============================================================================
// Types
// ============================================================================

/// A grocery list item (condensed ingredient)
pub type GroceryItem {
  GroceryItem(
    /// Name of the food/ingredient
    name: String,
    /// Total quantity needed
    quantity: Float,
    /// Unit of measurement (e.g., "cups", "lbs", "grams")
    unit: String,
    /// Supermarket category for organization
    category: String,
    /// Original ingredients that contributed to this item
    source_ingredients: List(String),
  )
}

/// A condensed grocery list organized by category
pub type GroceryList {
  GroceryList(
    /// Items organized by category
    by_category: Dict(String, List(GroceryItem)),
    /// Flat list of all items
    all_items: List(GroceryItem),
  )
}

// ============================================================================
// Grocery List Generation
// ============================================================================

/// Generate a grocery list from recipe ingredients
///
/// # Arguments
/// * `ingredients` - List of ingredients from recipe steps
///
/// # Returns
/// A condensed GroceryList
pub fn from_ingredients(ingredients: List(Ingredient)) -> GroceryList {
  // Filter out header ingredients and combine by food
  let valid_ingredients =
    ingredients
    |> list.filter(fn(ing) { !ing.is_header && option.is_some(ing.food) })

  // Group by food name and sum quantities
  let grouped = group_by_food(valid_ingredients)

  // Convert to grocery items
  let items =
    grouped
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(food_name, ingredient_group) = entry
      let total_qty = sum_quantities(ingredient_group)
      let unit_name = get_unit_name(ingredient_group)
      let category = get_category(ingredient_group)
      let sources =
        ingredient_group
        |> list.map(ingredient_source_string)

      GroceryItem(
        name: food_name,
        quantity: total_qty,
        unit: unit_name,
        category: category,
        source_ingredients: sources,
      )
    })

  // Organize by category
  let by_category =
    items
    |> list.fold(dict.new(), fn(acc, item) {
      let category_items =
        dict.get(acc, item.category)
        |> result.unwrap([])
      dict.insert(acc, item.category, [item, ..category_items])
    })

  GroceryList(by_category: by_category, all_items: items)
}

// ============================================================================
// Aggregation Logic
// ============================================================================

/// Group ingredients by food name
fn group_by_food(
  ingredients: List(Ingredient),
) -> Dict(String, List(Ingredient)) {
  ingredients
  |> list.fold(dict.new(), fn(acc, ing) {
    case ing.food {
      Some(food) -> {
        let food_name = food.name
        let current =
          dict.get(acc, food_name)
          |> result.unwrap([])
        dict.insert(acc, food_name, [ing, ..current])
      }
      None -> acc
    }
  })
}

/// Sum quantities for a group of ingredients with the same food
fn sum_quantities(ingredients: List(Ingredient)) -> Float {
  ingredients
  |> list.fold(0.0, fn(total, ing) {
    // Convert to common unit if possible, otherwise just sum
    let converted_amount = case ing.unit {
      Some(_) -> ing.amount
      None -> ing.amount
    }
    total +. converted_amount
  })
}

/// Get the most common unit name from a group of ingredients
fn get_unit_name(ingredients: List(Ingredient)) -> String {
  ingredients
  |> list.filter_map(fn(ing) {
    case ing.unit {
      Some(unit) -> Ok(unit.name)
      None -> Error(Nil)
    }
  })
  |> list.first
  |> result.unwrap("units")
}

/// Get the supermarket category from ingredients
fn get_category(ingredients: List(Ingredient)) -> String {
  ingredients
  |> list.filter_map(fn(ing) {
    case ing.food {
      Some(food) -> {
        case food.supermarket_category {
          Some(cat) -> Ok(cat.name)
          None -> Ok("Uncategorized")
        }
      }
      None -> Error(Nil)
    }
  })
  |> list.first
  |> result.unwrap("Uncategorized")
}

/// Get a human-readable string for an ingredient source
fn ingredient_source_string(ing: Ingredient) -> String {
  let food_name =
    ing.food
    |> option.map(fn(f) { f.name })
    |> option.unwrap("Unknown")

  let qty = ing.amount |> float_to_string
  let unit_name =
    ing.unit
    |> option.map(fn(u) { u.name })
    |> option.unwrap("")

  case ing.note {
    "" -> qty <> " " <> unit_name <> " " <> food_name
    note -> qty <> " " <> unit_name <> " " <> food_name <> " (" <> note <> ")"
  }
}

/// Format a float as a simple string
fn float_to_string(f: Float) -> String {
  // Round to 2 decimals
  let int_part = int_of_float(f)
  let decimal_part = f -. int.to_float(int_part)

  let formatted_decimal =
    int_of_float(decimal_part *. 100.0)
    |> int.to_string

  case decimal_part >. 0.01 {
    True -> {
      let padded_decimal = case string.length(formatted_decimal) {
        1 -> "0" <> formatted_decimal
        _ -> formatted_decimal
      }
      int.to_string(int_part) <> "." <> padded_decimal
    }
    False -> int.to_string(int_part)
  }
}

@external(erlang, "erlang", "trunc")
fn int_of_float(f: Float) -> Int

// ============================================================================
// Formatting
// ============================================================================

/// Format grocery list as a simple text shopping list
pub fn format_as_text(list: GroceryList) -> String {
  let category_sections =
    list.by_category
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(category, items) = entry
      let items_text =
        items
        |> list.map(fn(item) {
          "  ☐ " <> item.name <> " (" <> format_quantity(item) <> ")"
        })
        |> string.join("\n")

      "📦 " <> category <> "\n" <> items_text
    })
    |> string.join("\n\n")

  "🛒 GROCERY LIST\n================\n\n" <> category_sections
}

/// Format quantity with unit
fn format_quantity(item: GroceryItem) -> String {
  let qty = float_to_string(item.quantity)
  case item.unit {
    "units" | "" -> qty
    unit -> qty <> " " <> unit
  }
}

/// Format grocery list as JSON-friendly structure
pub fn format_as_json(
  list: GroceryList,
) -> List(#(String, List(#(String, String, Float)))) {
  list.by_category
  |> dict.to_list
  |> list.map(fn(entry) {
    let #(category, items) = entry
    let item_data =
      items
      |> list.map(fn(item) { #(item.name, item.unit, item.quantity) })
    #(category, item_data)
  })
}

// ============================================================================
// Merging Grocery Lists
// ============================================================================

/// Merge multiple grocery lists into one
pub fn merge(lists: List(GroceryList)) -> GroceryList {
  let all_items =
    lists
    |> list.flat_map(fn(list) { list.all_items })

  // Re-aggregate merged items
  let by_food =
    all_items
    |> list.fold(dict.new(), fn(acc, item) {
      let current =
        dict.get(acc, item.name)
        |> result.unwrap([])
      dict.insert(acc, item.name, [item, ..current])
    })

  // Sum quantities and rebuild
  let merged_items =
    by_food
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(name, items) = entry
      let total_qty =
        items
        |> list.fold(0.0, fn(acc, item) { acc +. item.quantity })
      let unit =
        items
        |> list.first
        |> result.map(fn(i) { i.unit })
        |> result.unwrap("units")
      let category =
        items
        |> list.first
        |> result.map(fn(i) { i.category })
        |> result.unwrap("Uncategorized")

      GroceryItem(
        name: name,
        quantity: total_qty,
        unit: unit,
        category: category,
        source_ingredients: items
          |> list.flat_map(fn(i) { i.source_ingredients }),
      )
    })

  // Re-organize by category
  let by_category =
    merged_items
    |> list.fold(dict.new(), fn(acc, item) {
      let current =
        dict.get(acc, item.category)
        |> result.unwrap([])
      dict.insert(acc, item.category, [item, ..current])
    })

  GroceryList(by_category: by_category, all_items: merged_items)
}

// ============================================================================
// Simple Ingredient Support (for types.Ingredient)
// ============================================================================

/// Generate a grocery list from simple ingredients (name + quantity string)
///
/// This works with the types.Ingredient type which has just name and quantity.
/// Ingredients with the same name are combined into a single item.
pub fn from_simple_ingredients(
  ingredients: List(SimpleIngredient),
) -> GroceryList {
  // Group ingredients by name
  let grouped =
    ingredients
    |> list.fold(dict.new(), fn(acc, ing) {
      let current =
        dict.get(acc, ing.name)
        |> result.unwrap([])
      dict.insert(acc, ing.name, [ing, ..current])
    })

  // Convert to grocery items
  let items =
    grouped
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(name, ings) = entry
      // Combine quantities as comma-separated list
      let quantities =
        ings
        |> list.map(fn(i: SimpleIngredient) { i.quantity })
        |> string.join(", ")

      GroceryItem(
        name: name,
        quantity: 0.0,
        // Not applicable for simple ingredients
        unit: quantities,
        // Store quantities in unit field
        category: "Uncategorized",
        source_ingredients: list.map(ings, fn(i: SimpleIngredient) {
          i.name <> ": " <> i.quantity
        }),
      )
    })

  // All items go to "Uncategorized"
  let by_category = case list.is_empty(items) {
    True -> dict.new()
    False -> dict.from_list([#("Uncategorized", items)])
  }

  GroceryList(by_category: by_category, all_items: items)
}

// ============================================================================
// Weekly Plan Integration
// ============================================================================

/// Generate a grocery list from a weekly meal plan
///
/// Collects all ingredients from all recipes in the plan and combines them.
pub fn from_weekly_plan(plan: WeeklyMealPlan) -> GroceryList {
  // Collect all ingredients from all days
  let all_ingredients =
    plan.days
    |> list.flat_map(fn(day: DayMeals) {
      // Get ingredients from each meal
      list.flatten([
        day.breakfast.ingredients,
        day.lunch.ingredients,
        day.dinner.ingredients,
      ])
    })

  // Use from_simple_ingredients to process them
  from_simple_ingredients(all_ingredients)
}

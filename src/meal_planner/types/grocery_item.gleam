//// Grocery List Types
////
//// Types for consolidated grocery list generation.
//// Part of NORTH STAR epic (meal-planner-918).

import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/json.{type Json}
import gleam/list
import gleam/result

// ============================================================================
// Core Types
// ============================================================================

/// A single item in a grocery list with consolidated quantities
pub opaque type GroceryItem {
  GroceryItem(
    /// Name of the ingredient/food
    name: String,
    /// Total quantity needed (sum of all occurrences)
    quantity: Float,
    /// Unit of measurement (e.g., "cups", "lbs", "grams")
    unit: String,
    /// Supermarket category for organization (e.g., "Produce", "Dairy")
    category: String,
    /// Original ingredient references that contributed to this item
    source_ingredients: List(String),
  )
}

/// Constructor for GroceryItem with validation
pub fn new_grocery_item(
  name name: String,
  quantity quantity: Float,
  unit unit: String,
  category category: String,
  source_ingredients source_ingredients: List(String),
) -> Result(GroceryItem, String) {
  // Validate quantity >= 0
  case quantity >=. 0.0 {
    False ->
      Error(
        "GroceryItem quantity must be >= 0.0, got " <> float.to_string(quantity),
      )
    True ->
      Ok(GroceryItem(
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        source_ingredients: source_ingredients,
      ))
  }
}

/// Get item name
pub fn grocery_item_name(item: GroceryItem) -> String {
  item.name
}

/// Get item quantity
pub fn grocery_item_quantity(item: GroceryItem) -> Float {
  item.quantity
}

/// Get item unit
pub fn grocery_item_unit(item: GroceryItem) -> String {
  item.unit
}

/// Get item category
pub fn grocery_item_category(item: GroceryItem) -> String {
  item.category
}

/// Get source ingredients
pub fn grocery_item_sources(item: GroceryItem) -> List(String) {
  item.source_ingredients
}

/// A consolidated grocery list organized by category
pub opaque type GroceryList {
  GroceryList(
    /// Items organized by category (e.g., "Produce" -> [items])
    by_category: Dict(String, List(GroceryItem)),
    /// Flat list of all items for easy iteration
    all_items: List(GroceryItem),
  )
}

/// Constructor for GroceryList
pub fn new_grocery_list(items: List(GroceryItem)) -> GroceryList {
  // Organize items by category
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

/// Get items by category
pub fn grocery_list_by_category(
  list: GroceryList,
) -> Dict(String, List(GroceryItem)) {
  list.by_category
}

/// Get all items as a flat list
pub fn grocery_list_all_items(list: GroceryList) -> List(GroceryItem) {
  list.all_items
}

/// Get all category names
pub fn grocery_list_categories(list: GroceryList) -> List(String) {
  list.by_category
  |> dict.keys
}

/// Get items for a specific category
pub fn grocery_list_items_for_category(
  list: GroceryList,
  category: String,
) -> List(GroceryItem) {
  list.by_category
  |> dict.get(category)
  |> result.unwrap([])
}

/// Get total number of items
pub fn grocery_list_count(list: GroceryList) -> Int {
  list.length(list.all_items)
}

/// Merge two grocery lists, combining quantities for duplicate items
pub fn merge_grocery_lists(
  list1: GroceryList,
  list2: GroceryList,
) -> GroceryList {
  let all_items = list.append(list1.all_items, list2.all_items)

  // Group items by name and sum quantities
  let merged_by_name =
    all_items
    |> list.fold(dict.new(), fn(acc, item) {
      let current =
        dict.get(acc, item.name)
        |> result.unwrap([])
      dict.insert(acc, item.name, [item, ..current])
    })

  // Combine items with the same name
  let merged_items =
    merged_by_name
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(name, items) = entry
      // Sum quantities
      let total_qty =
        items
        |> list.fold(0.0, fn(acc, item) { acc +. item.quantity })

      // Use first item's unit and category
      let first_item = case items {
        [item, ..] -> item
        [] ->
          GroceryItem(
            name: name,
            quantity: 0.0,
            unit: "units",
            category: "Uncategorized",
            source_ingredients: [],
          )
      }

      // Combine all source ingredients
      let all_sources =
        items
        |> list.flat_map(fn(item) { item.source_ingredients })

      GroceryItem(
        name: name,
        quantity: total_qty,
        unit: first_item.unit,
        category: first_item.category,
        source_ingredients: all_sources,
      )
    })

  new_grocery_list(merged_items)
}

// ============================================================================
// JSON Serialization
// ============================================================================

/// Encode GroceryItem to JSON
pub fn grocery_item_to_json(item: GroceryItem) -> Json {
  json.object([
    #("name", json.string(item.name)),
    #("quantity", json.float(item.quantity)),
    #("unit", json.string(item.unit)),
    #("category", json.string(item.category)),
    #("source_ingredients", json.array(item.source_ingredients, json.string)),
  ])
}

/// Encode GroceryList to JSON
pub fn grocery_list_to_json(list: GroceryList) -> Json {
  json.object([
    #("all_items", json.array(list.all_items, grocery_item_to_json)),
    #(
      "by_category",
      json.object(
        list.by_category
        |> dict.to_list
        |> list.map(fn(entry) {
          let #(category, items) = entry
          #(category, json.array(items, grocery_item_to_json))
        }),
      ),
    ),
  ])
}

// ============================================================================
// JSON Deserialization
// ============================================================================

/// Decode GroceryItem from JSON
pub fn grocery_item_decoder() -> Decoder(GroceryItem) {
  use name <- decode.field("name", decode.string)
  use quantity <- decode.field("quantity", decode.float)
  use unit <- decode.field("unit", decode.string)
  use category <- decode.field("category", decode.string)
  use source_ingredients <- decode.field(
    "source_ingredients",
    decode.list(decode.string),
  )

  decode.success(GroceryItem(
    name: name,
    quantity: quantity,
    unit: unit,
    category: category,
    source_ingredients: source_ingredients,
  ))
}

/// Decode GroceryList from JSON
pub fn grocery_list_decoder() -> Decoder(GroceryList) {
  use all_items <- decode.field(
    "all_items",
    decode.list(grocery_item_decoder()),
  )

  // Reconstruct by_category from all_items
  let by_category =
    all_items
    |> list.fold(dict.new(), fn(acc, item) {
      let current =
        dict.get(acc, item.category)
        |> result.unwrap([])
      dict.insert(acc, item.category, [item, ..current])
    })

  decode.success(GroceryList(by_category: by_category, all_items: all_items))
}

// ============================================================================
// Display Formatting
// ============================================================================

/// Format quantity with unit
fn format_quantity(item: GroceryItem) -> String {
  let qty_str = case item.quantity {
    0.0 -> "0"
    _ -> float.to_string(item.quantity)
  }

  case item.unit {
    "" | "units" -> qty_str
    unit -> qty_str <> " " <> unit
  }
}

/// Format a single grocery item as a string
pub fn grocery_item_to_string(item: GroceryItem) -> String {
  "  ☐ " <> item.name <> " (" <> format_quantity(item) <> ")"
}

/// Format entire grocery list as a readable shopping list
pub fn grocery_list_to_string(list: GroceryList) -> String {
  let categories =
    list.by_category
    |> dict.to_list
    |> list.map(fn(entry) {
      let #(category, items) = entry
      let items_text =
        items
        |> list.map(grocery_item_to_string)
        |> string.join("\n")

      "📦 " <> category <> "\n" <> items_text
    })
    |> string.join("\n\n")

  "🛒 GROCERY LIST\n================\n\n" <> categories
}

import gleam/string

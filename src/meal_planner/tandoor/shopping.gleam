/// Tandoor Shopping List Module
///
/// Provides shopping list types for grocery shopping management, along with JSON
/// encoding/decoding and CRUD API operations.
///
/// This module handles three main entities:
/// - ShoppingList: Container for shopping list entries with metadata
/// - ShoppingListEntry: Individual items on a shopping list (e.g., "2.5 cups tomatoes")
/// - ShoppingListRecipe: Recipe-based shopping lists with servings
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_list,
  parse_json_paginated, parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/food.{type Food, food_decoder}
import meal_planner/tandoor/unit.{type Unit}

// ============================================================================
// Types - ShoppingList
// ============================================================================

/// Represents a complete shopping list with all entries
///
/// A shopping list is a container for shopping list entries that can be
/// organized by category, checked off, and shared with other users.
pub type ShoppingList {
  ShoppingList(
    /// Shopping list ID
    id: ids.ShoppingListId,
    /// Optional name/title for the shopping list
    name: Option(String),
    /// All entries in this shopping list
    entries: List(ShoppingListEntry),
    /// User who created this shopping list
    created_by: ids.UserId,
    /// Creation timestamp (ISO 8601)
    created_at: String,
    /// Last update timestamp (ISO 8601)
    updated_at: String,
  )
}

/// Request to create a new shopping list
pub type ShoppingListCreate {
  ShoppingListCreate(
    /// Optional name for the shopping list
    name: Option(String),
  )
}

/// Request to update a shopping list
pub type ShoppingListUpdate {
  ShoppingListUpdate(
    /// Optional name for the shopping list
    name: Option(String),
  )
}

// ============================================================================
// Types - ShoppingListEntry
// ============================================================================

/// Represents a single item on a shopping list
pub type ShoppingListEntry {
  ShoppingListEntry(
    /// Entry ID
    id: ids.ShoppingListEntryId,
    /// Associated shopping list recipe ID (optional)
    list_recipe: Option(ids.ShoppingListId),
    /// Food item (optional)
    food: Option(ids.FoodId),
    /// Unit of measurement (optional)
    unit: Option(ids.UnitId),
    /// Amount/quantity
    amount: Float,
    /// Display order in the list
    order: Int,
    /// Whether this item has been checked off
    checked: Bool,
    /// Associated ingredient ID (optional)
    ingredient: Option(ids.IngredientId),
    /// User who created this entry
    created_by: ids.UserId,
    /// Creation timestamp (ISO 8601)
    created_at: String,
    /// Last update timestamp (ISO 8601)
    updated_at: String,
    /// When the item was checked/completed (optional)
    completed_at: Option(String),
    /// Delay display until this date (optional)
    delay_until: Option(String),
  )
}

/// Request to create a shopping list entry
pub type ShoppingListEntryCreate {
  ShoppingListEntryCreate(
    list_recipe: Option(ids.ShoppingListId),
    food: Option(ids.FoodId),
    unit: Option(ids.UnitId),
    amount: Float,
    order: Int,
    checked: Bool,
    ingredient: Option(ids.IngredientId),
    completed_at: Option(String),
    delay_until: Option(String),
    /// Mealplan ID for auto-linking
    mealplan_id: Option(Int),
  )
}

/// Request to update a shopping list entry
pub type ShoppingListEntryUpdate {
  ShoppingListEntryUpdate(
    list_recipe: Option(ids.ShoppingListId),
    food: Option(ids.FoodId),
    unit: Option(ids.UnitId),
    amount: Float,
    order: Int,
    checked: Bool,
    ingredient: Option(ids.IngredientId),
    completed_at: Option(String),
    delay_until: Option(String),
  )
}

/// Shopping list entry from API response
/// Contains nested Food and Unit objects instead of IDs
pub type ShoppingListEntryResponse {
  ShoppingListEntryResponse(
    /// Entry ID
    id: Int,
    /// Associated shopping list recipe ID (optional)
    list_recipe: Option(Int),
    /// Food item (nested object, optional)
    food: Option(Food),
    /// Unit of measurement (nested object, optional)
    unit: Option(Unit),
    /// Amount/quantity
    amount: Float,
    /// Display order in the list
    order: Int,
    /// Whether this item has been checked off
    checked: Bool,
    /// Creation timestamp (ISO 8601)
    created_at: String,
    /// When the item was checked/completed (optional)
    completed_at: Option(String),
  )
}

// ============================================================================
// Types - ShoppingListRecipe
// ============================================================================

/// Represents a recipe-based shopping list
pub type ShoppingListRecipe {
  ShoppingListRecipe(
    /// Shopping list ID
    id: ids.ShoppingListId,
    /// Name of the shopping list
    name: String,
    /// Associated recipe ID (optional)
    recipe: Option(ids.RecipeId),
    /// Associated meal plan ID (optional)
    mealplan: Option(ids.MealPlanId),
    /// Number of servings this list is for
    servings: Float,
    /// User who created this shopping list
    created_by: ids.UserId,
  )
}

/// Request to create a shopping list from a recipe
pub type ShoppingListRecipeCreate {
  ShoppingListRecipeCreate(
    name: String,
    recipe: Option(ids.RecipeId),
    mealplan: Option(ids.MealPlanId),
    servings: Float,
  )
}

/// Request to update a shopping list
pub type ShoppingListRecipeUpdate {
  ShoppingListRecipeUpdate(
    name: String,
    recipe: Option(ids.RecipeId),
    mealplan: Option(ids.MealPlanId),
    servings: Float,
  )
}

// ============================================================================
// Types - Shopping List Query and Category Grouping
// ============================================================================

/// Query parameters for filtering shopping list entries
///
/// This type encapsulates all possible query parameters when fetching
/// shopping list entries from the Tandoor API.
///
/// Fields:
/// - checked: Filter by checked status (None = all items)
/// - mealplan: Filter by meal plan ID
/// - updated_after: Return only items updated after this timestamp (ISO 8601)
/// - limit: Maximum number of results to return (page_size)
/// - offset: Offset for pagination
pub type ShoppingListQuery {
  ShoppingListQuery(
    /// Filter by checked status (true/false/None for all)
    checked: Option(Bool),
    /// Filter by meal plan ID
    mealplan: Option(Int),
    /// Filter by update timestamp (ISO 8601)
    updated_after: Option(String),
    /// Pagination limit (page_size)
    limit: Option(Int),
    /// Pagination offset
    offset: Option(Int),
  )
}

/// Shopping list item with category information for display
///
/// This type extends ShoppingListEntryResponse with computed category
/// information for UI rendering and grouping.
///
/// The category is derived from the food's supermarket_category field
/// and is used to group items by store aisle/section.
pub type ShoppingListItem {
  ShoppingListItem(
    /// Entry ID
    id: Int,
    /// Food item (nested object, optional)
    food: Option(Food),
    /// Unit of measurement (nested object, optional)
    unit: Option(Unit),
    /// Amount/quantity
    amount: Float,
    /// Display order in the list
    order: Int,
    /// Whether this item has been checked off
    checked: Bool,
    /// Creation timestamp (ISO 8601)
    created_at: String,
    /// When the item was checked/completed (optional)
    completed_at: Option(String),
    /// Derived category for grouping (from food.supermarket_category)
    category: Option(CategoryInfo),
  )
}

/// Category information for grouping shopping list items
///
/// This type represents the supermarket category extracted from a food item
/// for the purpose of grouping items by store section/aisle.
pub type CategoryInfo {
  CategoryInfo(
    /// Category ID
    id: Int,
    /// Category name (e.g., "Produce", "Dairy", "Frozen Foods")
    name: String,
    /// Optional category description
    description: Option(String),
  )
}

/// Shopping list grouped by category
///
/// This type represents a shopping list organized by supermarket categories
/// for easier shopping navigation (e.g., all produce items together).
pub type GroupedShoppingList {
  GroupedShoppingList(
    /// Items organized by category
    categories: List(CategoryGroup),
    /// Items without a category (uncategorized)
    uncategorized: List(ShoppingListItem),
  )
}

/// A group of shopping list items in the same category
///
/// Represents all items that belong to a specific supermarket category.
pub type CategoryGroup {
  CategoryGroup(
    /// Category information
    category: CategoryInfo,
    /// All items in this category
    items: List(ShoppingListItem),
  )
}

// ============================================================================
// Decoders - ShoppingList
// ============================================================================

/// Decoder for shopping lists
///
/// This decoder handles the complete shopping list including all entries.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Weekly Groceries",
///   "entries": [...],
///   "created_by": 1,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z"
/// }
/// ```
pub fn shopping_list_decoder() -> decode.Decoder(ShoppingList) {
  use id <- decode.field("id", ids.shopping_list_id_decoder())
  use name <- decode.field("name", decode.optional(decode.string))
  use entries <- decode.field(
    "entries",
    decode.list(shopping_list_entry_decoder()),
  )
  use created_by <- decode.field("created_by", ids.user_id_decoder())
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(ShoppingList(
    id: id,
    name: name,
    entries: entries,
    created_by: created_by,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

// ============================================================================
// Decoders - ShoppingListEntry
// ============================================================================

/// Decode a ShoppingListEntry from JSON (for internal use)
///
/// This decoder handles the full ShoppingListEntry type with all fields
/// including those returned by the API.
///
/// Example API response:
/// ```json
/// {
///   "id": 1,
///   "list_recipe": 5,
///   "food": 10,
///   "unit": 2,
///   "amount": 3.0,
///   "order": 0,
///   "checked": false,
///   "ingredient": null,
///   "created_by": 1,
///   "created_at": "2025-12-14T12:00:00Z",
///   "updated_at": "2025-12-14T12:00:00Z",
///   "completed_at": null,
///   "delay_until": null
/// }
/// ```
pub fn shopping_list_entry_decoder() -> decode.Decoder(ShoppingListEntry) {
  use id <- decode.field("id", ids.shopping_list_entry_id_decoder())
  use list_recipe <- decode.field(
    "list_recipe",
    decode.optional(ids.shopping_list_id_decoder()),
  )
  use food <- decode.field("food", decode.optional(ids.food_id_decoder()))
  use unit <- decode.field("unit", decode.optional(ids.unit_id_decoder()))
  use amount <- decode.field("amount", decode.float)
  use order <- decode.field("order", decode.int)
  use checked <- decode.field("checked", decode.bool)
  use ingredient <- decode.field(
    "ingredient",
    decode.optional(ids.ingredient_id_decoder()),
  )
  use created_by <- decode.field("created_by", ids.user_id_decoder())
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)
  use completed_at <- decode.field(
    "completed_at",
    decode.optional(decode.string),
  )
  use delay_until <- decode.field("delay_until", decode.optional(decode.string))

  decode.success(ShoppingListEntry(
    id: id,
    list_recipe: list_recipe,
    food: food,
    unit: unit,
    amount: amount,
    order: order,
    checked: checked,
    ingredient: ingredient,
    created_by: created_by,
    created_at: created_at,
    updated_at: updated_at,
    completed_at: completed_at,
    delay_until: delay_until,
  ))
}

/// Decode a single shopping list entry from JSON
///
/// Handles the nested Food and Unit objects returned by the API.
pub fn shopping_list_entry_response_decoder() -> decode.Decoder(
  ShoppingListEntryResponse,
) {
  use id <- decode.field("id", decode.int)
  use list_recipe <- decode.field("list_recipe", decode.optional(decode.int))
  use food <- decode.field("food", decode.optional(food_decoder()))
  use unit <- decode.field("unit", decode.optional(unit.decode_unit()))
  use amount <- decode.field("amount", decode.float)
  use order <- decode.field("order", decode.int)
  use checked <- decode.field("checked", decode.bool)
  use created_at <- decode.field("created_at", decode.string)
  use completed_at <- decode.field(
    "completed_at",
    decode.optional(decode.string),
  )

  decode.success(ShoppingListEntryResponse(
    id: id,
    list_recipe: list_recipe,
    food: food,
    unit: unit,
    amount: amount,
    order: order,
    checked: checked,
    created_at: created_at,
    completed_at: completed_at,
  ))
}

// ============================================================================
// Decoders - ShoppingListRecipe
// ============================================================================

/// Decode a ShoppingListRecipe from JSON
///
/// Handles both required and optional fields according to the Tandoor API spec.
///
/// Required fields:
/// - id: ShoppingListId
/// - name: String
/// - servings: Float
/// - created_by: UserId
///
/// Optional fields:
/// - recipe: RecipeId (when shopping list is based on a recipe)
/// - mealplan: MealPlanId (when shopping list is based on a meal plan)
pub fn shopping_list_recipe_decoder() -> decode.Decoder(ShoppingListRecipe) {
  use id <- decode.field("id", ids.shopping_list_id_decoder())
  use name <- decode.field("name", decode.string)
  use recipe <- decode.field("recipe", decode.optional(ids.recipe_id_decoder()))
  use mealplan <- decode.field(
    "mealplan",
    decode.optional(ids.meal_plan_id_decoder()),
  )
  use servings <- decode.field("servings", decode.float)
  use created_by <- decode.field("created_by", ids.user_id_decoder())

  decode.success(ShoppingListRecipe(
    id: id,
    name: name,
    recipe: recipe,
    mealplan: mealplan,
    servings: servings,
    created_by: created_by,
  ))
}

// ============================================================================
// Encoders - ShoppingList
// ============================================================================

/// Encode a ShoppingListCreate request to JSON
///
/// This encoder creates JSON for shopping list creation requests.
/// Only the optional name field is included.
///
/// # Example
/// ```gleam
/// let list = ShoppingListCreate(name: Some("Weekly Groceries"))
/// let encoded = encode_shopping_list_create(list)
/// // JSON: {"name": "Weekly Groceries"}
/// ```
pub fn encode_shopping_list_create(list: ShoppingListCreate) -> Json {
  let ShoppingListCreate(name) = list
  json.object([#("name", encode_optional_string(name))])
}

/// Encode a ShoppingListUpdate request to JSON
///
/// This encoder creates JSON for shopping list update requests.
/// Only the optional name field is included.
///
/// # Example
/// ```gleam
/// let update = ShoppingListUpdate(name: Some("Monthly Groceries"))
/// let encoded = encode_shopping_list_update(update)
/// // JSON: {"name": "Monthly Groceries"}
/// ```
pub fn encode_shopping_list_update(list: ShoppingListUpdate) -> Json {
  let ShoppingListUpdate(name) = list
  json.object([#("name", encode_optional_string(name))])
}

// ============================================================================
// Encoders - ShoppingListEntry
// ============================================================================

/// Encode a ShoppingListEntryCreate request to JSON
///
/// This encoder creates JSON for shopping list entry creation requests.
/// It includes required fields (amount, order, checked) and optional fields
/// (food, unit, list_recipe, ingredient, completed_at, delay_until, mealplan_id).
///
/// # Example
/// ```gleam
/// let entry = ShoppingListEntryCreate(
///   list_recipe: None,
///   food: Some(food_id(42)),
///   unit: Some(unit_id(1)),
///   amount: 2.5,
///   order: 0,
///   checked: False,
///   ingredient: None,
///   completed_at: None,
///   delay_until: None,
///   mealplan_id: None,
/// )
/// let encoded = encode_shopping_list_entry_create(entry)
/// // JSON: {"food": 42, "unit": 1, "amount": 2.5, "order": 0, "checked": false}
/// ```
pub fn encode_shopping_list_entry_create(entry: ShoppingListEntryCreate) -> Json {
  let ShoppingListEntryCreate(
    list_recipe,
    food,
    unit,
    amount,
    order,
    checked,
    ingredient,
    completed_at,
    delay_until,
    mealplan_id,
  ) = entry

  json.object([
    #("list_recipe", encode_optional_shopping_list_id(list_recipe)),
    #("food", encode_optional_food_id(food)),
    #("unit", encode_optional_unit_id(unit)),
    #("amount", json.float(amount)),
    #("order", json.int(order)),
    #("checked", json.bool(checked)),
    #("ingredient", encode_optional_ingredient_id(ingredient)),
    #("completed_at", encode_optional_string(completed_at)),
    #("delay_until", encode_optional_string(delay_until)),
    #("mealplan_id", encode_optional_int(mealplan_id)),
  ])
}

/// Encode a ShoppingListEntryUpdate request to JSON
///
/// This encoder creates JSON for shopping list entry update requests.
/// It includes the same fields as the create request except for mealplan_id.
///
/// # Example
/// ```gleam
/// let update = ShoppingListEntryUpdate(
///   list_recipe: None,
///   food: Some(food_id(42)),
///   unit: Some(unit_id(1)),
///   amount: 3.0,
///   order: 1,
///   checked: True,
///   ingredient: None,
///   completed_at: Some("2025-12-14T10:30:00Z"),
///   delay_until: None,
/// )
/// let encoded = encode_shopping_list_entry_update(update)
/// ```
pub fn encode_shopping_list_entry_update(entry: ShoppingListEntryUpdate) -> Json {
  let ShoppingListEntryUpdate(
    list_recipe,
    food,
    unit,
    amount,
    order,
    checked,
    ingredient,
    completed_at,
    delay_until,
  ) = entry

  json.object([
    #("list_recipe", encode_optional_shopping_list_id(list_recipe)),
    #("food", encode_optional_food_id(food)),
    #("unit", encode_optional_unit_id(unit)),
    #("amount", json.float(amount)),
    #("order", json.int(order)),
    #("checked", json.bool(checked)),
    #("ingredient", encode_optional_ingredient_id(ingredient)),
    #("completed_at", encode_optional_string(completed_at)),
    #("delay_until", encode_optional_string(delay_until)),
  ])
}

// ============================================================================
// Encoders - ShoppingListRecipe
// ============================================================================

/// Encode a ShoppingListRecipeCreate to JSON
///
/// This encoder creates JSON for shopping list recipe creation requests.
/// It handles all optional and required fields according to the Tandoor API.
///
/// # Example
/// ```gleam
/// let list = ShoppingListRecipeCreate(
///   name: "Weekly Meal Prep",
///   recipe: Some(recipe_id(100)),
///   mealplan: None,
///   servings: 4.0,
/// )
/// let encoded = encode_shopping_list_recipe_create(list)
/// ```
pub fn encode_shopping_list_recipe_create(
  list: ShoppingListRecipeCreate,
) -> Json {
  json.object([
    #("name", json.string(list.name)),
    #("recipe", encode_optional_recipe_id(list.recipe)),
    #("mealplan", encode_optional_meal_plan_id(list.mealplan)),
    #("servings", json.float(list.servings)),
  ])
}

/// Encode a ShoppingListRecipeUpdate to JSON
///
/// This encoder creates JSON for shopping list recipe update requests.
/// It handles all optional and required fields according to the Tandoor API.
///
/// # Example
/// ```gleam
/// let update = ShoppingListRecipeUpdate(
///   name: "Updated Meal Prep",
///   recipe: Some(recipe_id(100)),
///   mealplan: Some(meal_plan_id(5)),
///   servings: 6.0,
/// )
/// let encoded = encode_shopping_list_recipe_update(update)
/// ```
pub fn encode_shopping_list_recipe_update(
  update: ShoppingListRecipeUpdate,
) -> Json {
  json.object([
    #("name", json.string(update.name)),
    #("recipe", encode_optional_recipe_id(update.recipe)),
    #("mealplan", encode_optional_meal_plan_id(update.mealplan)),
    #("servings", json.float(update.servings)),
  ])
}

// ============================================================================
// Encoder Helpers
// ============================================================================

/// Encode optional ShoppingListId
fn encode_optional_shopping_list_id(id: Option(ids.ShoppingListId)) -> Json {
  case id {
    Some(id) -> json.int(ids.shopping_list_id_to_int(id))
    None -> json.null()
  }
}

/// Encode optional FoodId
fn encode_optional_food_id(id: Option(ids.FoodId)) -> Json {
  case id {
    Some(id) -> json.int(ids.food_id_to_int(id))
    None -> json.null()
  }
}

/// Encode optional UnitId
fn encode_optional_unit_id(id: Option(ids.UnitId)) -> Json {
  case id {
    Some(id) -> json.int(ids.unit_id_to_int(id))
    None -> json.null()
  }
}

/// Encode optional IngredientId
fn encode_optional_ingredient_id(id: Option(ids.IngredientId)) -> Json {
  case id {
    Some(id) -> json.int(ids.ingredient_id_to_int(id))
    None -> json.null()
  }
}

/// Encode optional RecipeId
fn encode_optional_recipe_id(id: Option(ids.RecipeId)) -> Json {
  case id {
    Some(id) -> json.int(ids.recipe_id_to_int(id))
    None -> json.null()
  }
}

/// Encode optional MealPlanId
fn encode_optional_meal_plan_id(id: Option(ids.MealPlanId)) -> Json {
  case id {
    Some(id) -> json.int(ids.meal_plan_id_to_int(id))
    None -> json.null()
  }
}

/// Encode optional String
fn encode_optional_string(value: Option(String)) -> Json {
  case value {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

/// Encode optional Int
fn encode_optional_int(value: Option(Int)) -> Json {
  case value {
    Some(i) -> json.int(i)
    None -> json.null()
  }
}

// ============================================================================
// API - CRUD Operations (ShoppingListEntry)
// ============================================================================

/// Get a single shopping list entry by ID
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_entry(config, entry_id: 42)
/// ```
pub fn get_entry(
  config: ClientConfig,
  entry_id entry_id: Int,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, shopping_list_entry_decoder())
}

/// List shopping list entries with optional filtering and pagination
///
/// # Arguments
/// * `checked` - Filter by checked status (true/false)
/// * `limit` - Number of results per page
/// * `offset` - Offset for pagination
///
/// # Example
/// ```gleam
/// // Get unchecked items
/// let result = list_entries(config, checked: Some(False), limit: Some(20), offset: Some(0))
/// // Get all items
/// let all = list_entries(config, checked: None, limit: None, offset: None)
/// ```
pub fn list_entries(
  config: ClientConfig,
  checked checked: Option(Bool),
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(ShoppingListEntryResponse), TandoorError) {
  let params = build_entry_query_params(checked, limit, offset)
  use resp <- result.try(execute_get(
    config,
    "/api/shopping-list-entry/",
    params,
  ))
  parse_json_paginated(resp, shopping_list_entry_response_decoder())
}

/// Create a new shopping list entry
///
/// # Example
/// ```gleam
/// let entry = ShoppingListEntryCreate(
///   list_recipe: None,
///   food: Some(food_id(42)),
///   unit: Some(unit_id(1)),
///   amount: 2.5,
///   order: 0,
///   checked: False,
///   ingredient: None,
///   completed_at: None,
///   delay_until: None,
///   mealplan_id: None,
/// )
/// let result = create_entry(config, entry)
/// ```
pub fn create_entry(
  config: ClientConfig,
  data: ShoppingListEntryCreate,
) -> Result(ShoppingListEntry, TandoorError) {
  let body =
    encode_shopping_list_entry_create(data)
    |> json.to_string

  use resp <- result.try(execute_post(config, "/api/shopping-list-entry/", body))
  parse_json_single(resp, shopping_list_entry_decoder())
}

/// Update an existing shopping list entry
///
/// # Example
/// ```gleam
/// let updates = ShoppingListEntryUpdate(
///   amount: 3.0,
///   checked: True,
///   completed_at: Some("2025-12-14T10:30:00Z"),
///   ..
/// )
/// let result = update_entry(config, entry_id: 42, data: updates)
/// ```
pub fn update_entry(
  config: ClientConfig,
  entry_id entry_id: Int,
  data data: ShoppingListEntryUpdate,
) -> Result(ShoppingListEntry, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"
  let body =
    encode_shopping_list_entry_update(data)
    |> json.to_string

  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, shopping_list_entry_decoder())
}

/// Delete a shopping list entry
///
/// # Example
/// ```gleam
/// let result = delete_entry(config, entry_id: 42)
/// ```
pub fn delete_entry(
  config: ClientConfig,
  entry_id entry_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(entry_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}

/// Add a recipe to the shopping list
///
/// Creates shopping list entries for all ingredients in the specified recipe.
///
/// # Example
/// ```gleam
/// let result = add_recipe_to_shopping_list(config, recipe_id: 123, servings: 4)
/// ```
pub fn add_recipe_to_shopping_list(
  config: ClientConfig,
  recipe_id recipe_id: Int,
  servings servings: Int,
) -> Result(List(ShoppingListEntry), TandoorError) {
  let body =
    json.object([
      #("recipe", json.int(recipe_id)),
      #("servings", json.int(servings)),
    ])
    |> json.to_string

  use resp <- result.try(execute_post(
    config,
    "/api/shopping-list-recipe/",
    body,
  ))
  parse_json_list(resp, shopping_list_entry_decoder())
}

// ============================================================================
// Private Helpers
// ============================================================================

/// Build query parameters from optional filters
fn build_entry_query_params(
  checked: Option(Bool),
  limit: Option(Int),
  offset: Option(Int),
) -> List(#(String, String)) {
  let checked_param = case checked {
    Some(True) -> [#("checked", "true")]
    Some(False) -> [#("checked", "false")]
    None -> []
  }

  let limit_param = case limit {
    Some(l) -> [#("page_size", int.to_string(l))]
    None -> []
  }

  let offset_param = case offset {
    Some(o) -> [#("offset", int.to_string(o))]
    None -> []
  }

  // Flatten all parameter lists together
  list.flatten([checked_param, limit_param, offset_param])
}

// ============================================================================
// Query Builders
// ============================================================================

/// Create a default/empty shopping list query
///
/// Returns a query with all fields set to None, which will fetch all items
/// without any filtering.
///
/// # Example
/// ```gleam
/// let query = empty_query()
/// // ShoppingListQuery with all None fields
/// ```
pub fn empty_query() -> ShoppingListQuery {
  ShoppingListQuery(
    checked: None,
    mealplan: None,
    updated_after: None,
    limit: None,
    offset: None,
  )
}

/// Build query parameters from a ShoppingListQuery
///
/// Converts a ShoppingListQuery into a list of URL query parameter tuples
/// that can be used with the Tandoor API.
///
/// # Example
/// ```gleam
/// let query = ShoppingListQuery(
///   checked: Some(False),
///   mealplan: Some(123),
///   updated_after: None,
///   limit: Some(20),
///   offset: Some(0),
/// )
/// let params = build_query_params(query)
/// // [#("checked", "false"), #("mealplan", "123"), #("page_size", "20"), #("offset", "0")]
/// ```
pub fn build_query_params(query: ShoppingListQuery) -> List(#(String, String)) {
  let checked_param = case query.checked {
    Some(True) -> [#("checked", "true")]
    Some(False) -> [#("checked", "false")]
    None -> []
  }

  let mealplan_param = case query.mealplan {
    Some(id) -> [#("mealplan", int.to_string(id))]
    None -> []
  }

  let updated_after_param = case query.updated_after {
    Some(timestamp) -> [#("updated_after", timestamp)]
    None -> []
  }

  let limit_param = case query.limit {
    Some(l) -> [#("page_size", int.to_string(l))]
    None -> []
  }

  let offset_param = case query.offset {
    Some(o) -> [#("offset", int.to_string(o))]
    None -> []
  }

  list.flatten([
    checked_param,
    mealplan_param,
    updated_after_param,
    limit_param,
    offset_param,
  ])
}

/// Set the checked filter on a query
///
/// # Example
/// ```gleam
/// empty_query()
/// |> with_checked(Some(False))  // Only unchecked items
/// ```
pub fn with_checked(
  query: ShoppingListQuery,
  checked: Option(Bool),
) -> ShoppingListQuery {
  ShoppingListQuery(..query, checked: checked)
}

/// Set the mealplan filter on a query
///
/// # Example
/// ```gleam
/// empty_query()
/// |> with_mealplan(Some(123))
/// ```
pub fn with_mealplan(
  query: ShoppingListQuery,
  mealplan: Option(Int),
) -> ShoppingListQuery {
  ShoppingListQuery(..query, mealplan: mealplan)
}

/// Set the updated_after filter on a query
///
/// # Example
/// ```gleam
/// empty_query()
/// |> with_updated_after(Some("2025-12-20T10:00:00Z"))
/// ```
pub fn with_updated_after(
  query: ShoppingListQuery,
  updated_after: Option(String),
) -> ShoppingListQuery {
  ShoppingListQuery(..query, updated_after: updated_after)
}

/// Set pagination limit on a query
///
/// # Example
/// ```gleam
/// empty_query()
/// |> with_limit(Some(50))
/// ```
pub fn with_limit(
  query: ShoppingListQuery,
  limit: Option(Int),
) -> ShoppingListQuery {
  ShoppingListQuery(..query, limit: limit)
}

/// Set pagination offset on a query
///
/// # Example
/// ```gleam
/// empty_query()
/// |> with_offset(Some(20))
/// ```
pub fn with_offset(
  query: ShoppingListQuery,
  offset: Option(Int),
) -> ShoppingListQuery {
  ShoppingListQuery(..query, offset: offset)
}

/// Convert ShoppingListEntryResponse to ShoppingListItem
///
/// Extracts category information from the food's supermarket_category field
/// and creates a ShoppingListItem for display/grouping purposes.
///
/// # Example
/// ```gleam
/// let item = entry_response_to_item(entry_response)
/// ```
pub fn entry_response_to_item(
  entry: ShoppingListEntryResponse,
) -> ShoppingListItem {
  let category = case entry.food {
    Some(food) ->
      case food.supermarket_category {
        Some(cat) ->
          Some(CategoryInfo(
            id: cat.id,
            name: cat.name,
            description: cat.description,
          ))
        None -> None
      }
    None -> None
  }

  ShoppingListItem(
    id: entry.id,
    food: entry.food,
    unit: entry.unit,
    amount: entry.amount,
    order: entry.order,
    checked: entry.checked,
    created_at: entry.created_at,
    completed_at: entry.completed_at,
    category: category,
  )
}

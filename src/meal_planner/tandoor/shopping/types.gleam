/// Tandoor Shopping List Types
///
/// Type definitions for shopping lists, entries, and queries.
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/food.{type Food}
import meal_planner/tandoor/unit.{type Unit}

// ============================================================================
// Types - ShoppingList
// ============================================================================

/// Represents a complete shopping list with all entries
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

/// Shopping list entry from API response with nested objects
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
// Types - Query and Grouping
// ============================================================================

/// Query parameters for filtering shopping list entries
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
pub type GroupedShoppingList {
  GroupedShoppingList(
    /// Items organized by category
    categories: List(CategoryGroup),
    /// Items without a category (uncategorized)
    uncategorized: List(ShoppingListItem),
  )
}

/// A group of shopping list items in the same category
pub type CategoryGroup {
  CategoryGroup(
    /// Category information
    category: CategoryInfo,
    /// All items in this category
    items: List(ShoppingListItem),
  )
}

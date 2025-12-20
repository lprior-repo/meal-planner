/// Tandoor MealPlan Module
///
/// Provides meal planning types for scheduling recipes, along with JSON
/// encoding/decoding and CRUD API operations.
///
/// MealPlans allow scheduling recipes for specific dates and times, with support
/// for meal types (breakfast, lunch, dinner), servings, notes, and sharing with
/// other users.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/recipe.{type RecipeOverview, recipe_overview_decoder}

// ============================================================================
// Types
// ============================================================================

/// Complete meal plan entry with all metadata
/// Represents a planned meal for a specific date/time
pub type MealPlan {
  MealPlan(
    /// Tandoor meal plan ID
    id: Int,
    /// Meal plan title (max 64 characters)
    title: String,
    /// Optional recipe reference (can be null if just a note/reminder)
    recipe: Option(RecipeOverview),
    /// Number of servings for this meal
    servings: Float,
    /// Plain text note about the meal
    note: String,
    /// Markdown-formatted note (read-only, computed from note)
    note_markdown: String,
    /// Start date/time for the meal (ISO 8601 format)
    from_date: String,
    /// End date/time for the meal (ISO 8601 format)
    to_date: String,
    /// Meal type categorization (breakfast, lunch, dinner, etc)
    meal_type: MealType,
    /// User ID who created this meal plan
    created_by: Int,
    /// Users this meal plan is shared with
    shared: Option(List(User)),
    /// Recipe name (read-only, denormalized for performance)
    recipe_name: String,
    /// Meal type name (read-only, denormalized for performance)
    meal_type_name: String,
    /// Whether this meal plan is on the shopping list
    shopping: Bool,
  )
}

/// Paginated response for meal plan list operations
pub type MealPlanListResponse {
  MealPlanListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(MealPlan),
  )
}

/// Simplified meal plan entry for list operations
/// Used when fetching multiple meal plans where full details aren't needed
pub type MealPlanEntry {
  MealPlanEntry(
    /// Tandoor meal plan ID
    id: Int,
    /// Meal plan title
    title: String,
    /// Recipe ID if linked to a recipe
    recipe_id: Option(Int),
    /// Recipe name for display
    recipe_name: String,
    /// Number of servings
    servings: Float,
    /// Start date/time (ISO 8601)
    from_date: String,
    /// End date/time (ISO 8601)
    to_date: String,
    /// Meal type ID
    meal_type_id: Int,
    /// Meal type name for display
    meal_type_name: String,
    /// Whether on shopping list
    shopping: Bool,
  )
}

/// Meal type categorization (breakfast, lunch, dinner, etc)
/// Used to organize meal plans by time of day
pub type MealType {
  MealType(
    /// Tandoor meal type ID
    id: Int,
    /// Meal type name (e.g., "Breakfast", "Lunch", "Dinner")
    name: String,
    /// Display order for sorting meal types
    order: Int,
    /// Optional time of day for this meal type (HH:MM format)
    time: Option(String),
    /// Optional color hex code for UI display (e.g., "#FF5733")
    color: Option(String),
    /// Whether this is the default meal type for the user
    default: Bool,
    /// User ID who created this meal type
    created_by: Int,
  )
}

/// Simplified user type for meal plan sharing
/// Contains minimal user information needed for meal plan operations
pub type User {
  User(
    /// Tandoor user ID
    id: Int,
    /// Username (required, 150 chars max, letters/digits/@/./+/-/_ only)
    username: String,
    /// User's first name
    first_name: String,
    /// User's last name
    last_name: String,
    /// Display name (computed from first/last name or username)
    display_name: String,
    /// Whether user has admin/staff permissions
    is_staff: Bool,
    /// Whether user has superuser permissions
    is_superuser: Bool,
    /// Whether user account is active
    is_active: Bool,
  )
}

/// Request to create a new meal plan entry
pub type MealPlanCreateRequest {
  MealPlanCreateRequest(
    recipe: Option(Int),
    title: String,
    servings: Float,
    note: String,
    from_date: String,
    to_date: String,
    meal_type: Int,
  )
}

/// Request to update an existing meal plan entry
/// All fields are optional to support partial updates
pub type MealPlanUpdateRequest {
  MealPlanUpdateRequest(
    recipe: Option(Option(Int)),
    title: Option(String),
    servings: Option(Float),
    note: Option(String),
    from_date: Option(String),
    to_date: Option(String),
    meal_type: Option(Int),
  )
}

// ============================================================================
// Decoder
// ============================================================================

/// Decode a complete MealPlan from JSON
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "title": "Pasta Night",
///   "recipe": { "id": 42, "name": "Carbonara", ... },
///   "servings": 4.0,
///   "note": "Don't forget the parmesan",
///   "note_markdown": "Don't forget the parmesan",
///   "from_date": "2024-01-15T18:00:00Z",
///   "to_date": "2024-01-15T19:00:00Z",
///   "meal_type": { "id": 2, "name": "Dinner", ... },
///   "created_by": 1,
///   "shared": [{ "id": 2, "username": "alice", ... }],
///   "recipe_name": "Carbonara",
///   "meal_type_name": "Dinner",
///   "shopping": true
/// }
/// ```
pub fn meal_plan_decoder() -> decode.Decoder(MealPlan) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use recipe <- decode.field(
    "recipe",
    decode.optional(recipe_overview_decoder()),
  )
  use servings <- decode.field("servings", decode.float)
  use note <- decode.field("note", decode.string)
  use note_markdown <- decode.field("note_markdown", decode.string)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type <- decode.field("meal_type", meal_type_decoder())
  use created_by <- decode.field("created_by", decode.int)
  use shared <- decode.field(
    "shared",
    decode.optional(decode.list(user_decoder())),
  )
  use recipe_name <- decode.field("recipe_name", decode.string)
  use meal_type_name <- decode.field("meal_type_name", decode.string)
  use shopping <- decode.field("shopping", decode.bool)

  decode.success(MealPlan(
    id: id,
    title: title,
    recipe: recipe,
    servings: servings,
    note: note,
    note_markdown: note_markdown,
    from_date: from_date,
    to_date: to_date,
    meal_type: meal_type,
    created_by: created_by,
    shared: shared,
    recipe_name: recipe_name,
    meal_type_name: meal_type_name,
    shopping: shopping,
  ))
}

/// Decode a paginated meal plan list response from JSON
pub fn meal_plan_list_decoder() -> decode.Decoder(MealPlanListResponse) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field("results", decode.list(meal_plan_decoder()))

  decode.success(MealPlanListResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}

/// Decode a simplified MealPlanEntry from JSON
///
/// Used for list operations where full details aren't needed.
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "title": "Quick Breakfast",
///   "recipe_id": 10,
///   "recipe_name": "Scrambled Eggs",
///   "servings": 2.0,
///   "from_date": "2024-01-15T08:00:00Z",
///   "to_date": "2024-01-15T08:30:00Z",
///   "meal_type_id": 1,
///   "meal_type_name": "Breakfast",
///   "shopping": false
/// }
/// ```
pub fn meal_plan_entry_decoder() -> decode.Decoder(MealPlanEntry) {
  use id <- decode.field("id", decode.int)
  use title <- decode.field("title", decode.string)
  use recipe_id <- decode.field("recipe_id", decode.optional(decode.int))
  use recipe_name <- decode.field("recipe_name", decode.string)
  use servings <- decode.field("servings", decode.float)
  use from_date <- decode.field("from_date", decode.string)
  use to_date <- decode.field("to_date", decode.string)
  use meal_type_id <- decode.field("meal_type_id", decode.int)
  use meal_type_name <- decode.field("meal_type_name", decode.string)
  use shopping <- decode.field("shopping", decode.bool)

  decode.success(MealPlanEntry(
    id: id,
    title: title,
    recipe_id: recipe_id,
    recipe_name: recipe_name,
    servings: servings,
    from_date: from_date,
    to_date: to_date,
    meal_type_id: meal_type_id,
    meal_type_name: meal_type_name,
    shopping: shopping,
  ))
}

/// Decode a MealType from JSON
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "name": "Breakfast",
///   "order": 0,
///   "time": "08:00",
///   "color": "#FF5733",
///   "default": true,
///   "created_by": 1
/// }
/// ```
pub fn meal_type_decoder() -> decode.Decoder(MealType) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use order <- decode.field("order", decode.int)
  use time <- decode.field("time", decode.optional(decode.string))
  use color <- decode.field("color", decode.optional(decode.string))
  use default <- decode.field("default", decode.bool)
  use created_by <- decode.field("created_by", decode.int)

  decode.success(MealType(
    id: id,
    name: name,
    order: order,
    time: time,
    color: color,
    default: default,
    created_by: created_by,
  ))
}

/// Decode a User from JSON
///
/// Example JSON:
/// ```json
/// {
///   "id": 1,
///   "username": "chef123",
///   "first_name": "Gordon",
///   "last_name": "Ramsay",
///   "display_name": "Gordon Ramsay",
///   "is_staff": true,
///   "is_superuser": false,
///   "is_active": true
/// }
/// ```
pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use username <- decode.field("username", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.string)
  use display_name <- decode.field("display_name", decode.string)
  use is_staff <- decode.field("is_staff", decode.bool)
  use is_superuser <- decode.field("is_superuser", decode.bool)
  use is_active <- decode.field("is_active", decode.bool)

  decode.success(User(
    id: id,
    username: username,
    first_name: first_name,
    last_name: last_name,
    display_name: display_name,
    is_staff: is_staff,
    is_superuser: is_superuser,
    is_active: is_active,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Helper to encode Keyword to JSON
fn encode_keyword_json(kw: client.Keyword) -> Json {
  json.object([
    #("id", json.int(kw.id)),
    #("name", json.string(kw.name)),
    #("description", json.string(kw.description)),
  ])
}

/// Encode a RecipeOverview to JSON
fn encode_recipe_overview(recipe: RecipeOverview) -> Json {
  json.object([
    #("id", json.int(recipe.id)),
    #("name", json.string(recipe.name)),
    #("description", json.string(recipe.description)),
    #("image", case recipe.image {
      Some(img) -> json.string(img)
      None -> json.null()
    }),
    #("keywords", json.array(recipe.keywords, encode_keyword_json)),
    #("rating", case recipe.rating {
      Some(r) -> json.float(r)
      None -> json.null()
    }),
    #("last_cooked", case recipe.last_cooked {
      Some(lc) -> json.string(lc)
      None -> json.null()
    }),
  ])
}

/// Encode a complete MealPlan to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_meal_plan(meal_plan: MealPlan) -> Json {
  json.object([
    #("id", json.int(meal_plan.id)),
    #("title", json.string(meal_plan.title)),
    #("recipe", case meal_plan.recipe {
      Some(r) -> encode_recipe_overview(r)
      None -> json.null()
    }),
    #("servings", json.float(meal_plan.servings)),
    #("note", json.string(meal_plan.note)),
    #("note_markdown", json.string(meal_plan.note_markdown)),
    #("from_date", json.string(meal_plan.from_date)),
    #("to_date", json.string(meal_plan.to_date)),
    #("meal_type", encode_meal_type(meal_plan.meal_type)),
    #("created_by", json.int(meal_plan.created_by)),
    #("shared", case meal_plan.shared {
      Some(users) -> json.array(users, encode_user)
      None -> json.null()
    }),
    #("recipe_name", json.string(meal_plan.recipe_name)),
    #("meal_type_name", json.string(meal_plan.meal_type_name)),
    #("shopping", json.bool(meal_plan.shopping)),
  ])
}

/// Encode a MealType to JSON
pub fn encode_meal_type(meal_type: MealType) -> Json {
  json.object([
    #("id", json.int(meal_type.id)),
    #("name", json.string(meal_type.name)),
    #("order", json.int(meal_type.order)),
    #("time", case meal_type.time {
      Some(t) -> json.string(t)
      None -> json.null()
    }),
    #("color", case meal_type.color {
      Some(c) -> json.string(c)
      None -> json.null()
    }),
    #("default", json.bool(meal_type.default)),
    #("created_by", json.int(meal_type.created_by)),
  ])
}

/// Convert a MealType to its string representation
pub fn meal_type_to_string(meal_type: MealType) -> String {
  case meal_type.name {
    "Breakfast" -> "BREAKFAST"
    "Lunch" -> "LUNCH"
    "Dinner" -> "DINNER"
    "Snack" -> "SNACK"
    _ -> "OTHER"
  }
}

/// Encode a User to JSON
pub fn encode_user(user: User) -> Json {
  json.object([
    #("id", json.int(user.id)),
    #("username", json.string(user.username)),
    #("first_name", json.string(user.first_name)),
    #("last_name", json.string(user.last_name)),
    #("display_name", json.string(user.display_name)),
    #("is_staff", json.bool(user.is_staff)),
    #("is_superuser", json.bool(user.is_superuser)),
    #("is_active", json.bool(user.is_active)),
  ])
}

/// Encode a MealPlanCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_meal_plan_create_request(request: MealPlanCreateRequest) -> Json {
  json.object([
    #("recipe", case request.recipe {
      Some(id) -> json.int(id)
      None -> json.null()
    }),
    #("title", json.string(request.title)),
    #("servings", json.float(request.servings)),
    #("note", json.string(request.note)),
    #("from_date", json.string(request.from_date)),
    #("to_date", json.string(request.to_date)),
    #("meal_type", json.int(request.meal_type)),
  ])
}

/// Encode a MealPlanUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_meal_plan_update_request(request: MealPlanUpdateRequest) -> Json {
  let recipe_field = case request.recipe {
    Some(Some(id)) -> [#("recipe", json.int(id))]
    Some(None) -> [#("recipe", json.null())]
    None -> []
  }

  let title_field = case request.title {
    Some(title) -> [#("title", json.string(title))]
    None -> []
  }

  let servings_field = case request.servings {
    Some(servings) -> [#("servings", json.float(servings))]
    None -> []
  }

  let note_field = case request.note {
    Some(note) -> [#("note", json.string(note))]
    None -> []
  }

  let from_date_field = case request.from_date {
    Some(date) -> [#("from_date", json.string(date))]
    None -> []
  }

  let to_date_field = case request.to_date {
    Some(date) -> [#("to_date", json.string(date))]
    None -> []
  }

  let meal_type_field = case request.meal_type {
    Some(meal_type) -> [#("meal_type", json.int(meal_type))]
    None -> []
  }

  json.object(
    list.flatten([
      recipe_field,
      title_field,
      servings_field,
      note_field,
      from_date_field,
      to_date_field,
      meal_type_field,
    ]),
  )
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// List meal plans from Tandoor API with optional date filtering
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `from_date` - Optional start date filter (YYYY-MM-DD)
/// * `to_date` - Optional end date filter (YYYY-MM-DD)
///
/// # Returns
/// Result with paginated meal plan list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_meal_plans(
///   config,
///   from_date: Some("2024-01-01"),
///   to_date: Some("2024-01-31")
/// )
/// ```
pub fn list_meal_plans(
  config: ClientConfig,
  from_date from_date: Option(String),
  to_date to_date: Option(String),
) -> Result(MealPlanListResponse, TandoorError) {
  let path = "/api/meal-plan/"

  let query_params =
    []
    |> fn(params) {
      case from_date {
        Some(d) -> [#("from_date", d), ..params]
        None -> params
      }
    }
    |> fn(params) {
      case to_date {
        Some(d) -> [#("to_date", d), ..params]
        None -> params
      }
    }

  use resp <- result.try(execute_get(config, path, query_params))
  parse_json_single(resp, meal_plan_list_decoder())
}

/// Get a single meal plan entry by ID
pub fn get_meal_plan(
  config: ClientConfig,
  meal_plan_id meal_plan_id: Int,
) -> Result(MealPlan, TandoorError) {
  let path = "/api/meal-plan/" <> int.to_string(meal_plan_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, meal_plan_decoder())
}

/// Create a new meal plan entry in Tandoor
pub fn create_meal_plan(
  config: ClientConfig,
  create_data: MealPlanCreateRequest,
) -> Result(MealPlan, TandoorError) {
  let body =
    encode_meal_plan_create_request(create_data)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/meal-plan/", body))
  parse_json_single(resp, meal_plan_decoder())
}

/// Update an existing meal plan entry (supports partial updates)
pub fn update_meal_plan(
  config: ClientConfig,
  meal_plan_id meal_plan_id: Int,
  data update_data: MealPlanUpdateRequest,
) -> Result(MealPlan, TandoorError) {
  let path = "/api/meal-plan/" <> int.to_string(meal_plan_id) <> "/"
  let body =
    encode_meal_plan_update_request(update_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, meal_plan_decoder())
}

/// Delete a meal plan entry from Tandoor
pub fn delete_meal_plan(
  config: ClientConfig,
  meal_plan_id meal_plan_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/meal-plan/" <> int.to_string(meal_plan_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}

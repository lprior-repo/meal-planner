/// Tandoor Automation Module
///
/// Provides the Automation type for automatic recipe processing, along with JSON
/// encoding/decoding and CRUD API operations.
///
/// Automations allow automatic replacement/transformation of Foods, Units, Keywords,
/// and Descriptions during recipe import and editing.
///
/// Automation Types:
/// - FOOD_ALIAS: Replace one food with another
/// - UNIT_ALIAS: Replace one unit with another
/// - KEYWORD_ALIAS: Replace one keyword with another
/// - DESCRIPTION_REPLACE: Replace patterns in recipe descriptions using RegEx
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import gleam/result
import meal_planner/tandoor/api/crud_helpers.{
  execute_delete, execute_get, execute_patch, execute_post, parse_json_list,
  parse_json_single,
}
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

// ============================================================================
// Types
// ============================================================================

/// Automation types supported by Tandoor
pub type AutomationType {
  FoodAlias
  UnitAlias
  KeywordAlias
  DescriptionReplace
}

/// Automation for automatic recipe processing
///
/// Automations run automatically during recipe import and editing to maintain
/// consistency and reduce manual work.
///
/// Fields:
/// - id: Unique identifier
/// - name: Human-readable name for the automation
/// - description: Optional detailed description
/// - automation_type: Type of automation (alias or description replace)
/// - param_1: First parameter (varies by type)
/// - param_2: Second parameter (varies by type)
/// - param_3: Third parameter (used only for description replace)
/// - order: Execution order (lower numbers run first)
/// - disabled: Whether automation is currently disabled
/// - created_at: Creation timestamp (readonly)
/// - updated_at: Last update timestamp (readonly)
pub type Automation {
  Automation(
    id: Int,
    name: String,
    description: String,
    automation_type: AutomationType,
    param_1: String,
    param_2: String,
    param_3: Option(String),
    order: Int,
    disabled: Bool,
    created_at: String,
    updated_at: String,
  )
}

/// Request to create a new automation in Tandoor
///
/// Only includes writable fields (excludes readonly fields like id, created_at, etc.)
pub type AutomationCreateRequest {
  AutomationCreateRequest(
    name: String,
    description: String,
    automation_type: AutomationType,
    param_1: String,
    param_2: String,
    param_3: Option(String),
    order: Int,
    disabled: Bool,
  )
}

/// Request to update an existing automation in Tandoor
///
/// All fields are optional to support partial updates
pub type AutomationUpdateRequest {
  AutomationUpdateRequest(
    name: Option(String),
    description: Option(String),
    automation_type: Option(AutomationType),
    param_1: Option(String),
    param_2: Option(String),
    param_3: Option(Option(String)),
    order: Option(Int),
    disabled: Option(Bool),
  )
}

// ============================================================================
// Decoder
// ============================================================================

/// Decode AutomationType from JSON string
fn automation_type_decoder() -> decode.Decoder(AutomationType) {
  use type_string <- decode.then(decode.string)
  case type_string {
    "FOOD_ALIAS" -> decode.success(FoodAlias)
    "UNIT_ALIAS" -> decode.success(UnitAlias)
    "KEYWORD_ALIAS" -> decode.success(KeywordAlias)
    "DESCRIPTION_REPLACE" -> decode.success(DescriptionReplace)
    _ -> decode.failure(FoodAlias, "Unknown automation type: " <> type_string)
  }
}

/// Decode an Automation from JSON
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Convert grams to ounces",
///   "description": "Automatically convert gram measurements to ounces",
///   "type": "UNIT_ALIAS",
///   "param_1": "g",
///   "param_2": "oz",
///   "param_3": null,
///   "order": 1,
///   "disabled": false,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z"
/// }
/// ```
pub fn automation_decoder() -> decode.Decoder(Automation) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use automation_type <- decode.field("type", automation_type_decoder())
  use param_1 <- decode.field("param_1", decode.string)
  use param_2 <- decode.field("param_2", decode.string)
  use param_3 <- decode.field("param_3", decode.optional(decode.string))
  use order <- decode.field("order", decode.int)
  use disabled <- decode.field("disabled", decode.bool)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(Automation(
    id: id,
    name: name,
    description: description,
    automation_type: automation_type,
    param_1: param_1,
    param_2: param_2,
    param_3: param_3,
    order: order,
    disabled: disabled,
    created_at: created_at,
    updated_at: updated_at,
  ))
}

// ============================================================================
// Encoders
// ============================================================================

/// Convert AutomationType to JSON string
fn automation_type_to_string(automation_type: AutomationType) -> String {
  case automation_type {
    FoodAlias -> "FOOD_ALIAS"
    UnitAlias -> "UNIT_ALIAS"
    KeywordAlias -> "KEYWORD_ALIAS"
    DescriptionReplace -> "DESCRIPTION_REPLACE"
  }
}

/// Encode a complete Automation to JSON
///
/// This includes all fields for GET responses and complete representations.
pub fn encode_automation(automation: Automation) -> Json {
  json.object([
    #("id", json.int(automation.id)),
    #("name", json.string(automation.name)),
    #("description", json.string(automation.description)),
    #(
      "type",
      json.string(automation_type_to_string(automation.automation_type)),
    ),
    #("param_1", json.string(automation.param_1)),
    #("param_2", json.string(automation.param_2)),
    #("param_3", case automation.param_3 {
      Some(val) -> json.string(val)
      None -> json.null()
    }),
    #("order", json.int(automation.order)),
    #("disabled", json.bool(automation.disabled)),
    #("created_at", json.string(automation.created_at)),
    #("updated_at", json.string(automation.updated_at)),
  ])
}

/// Encode an AutomationCreateRequest to JSON
///
/// Only includes writable fields for POST requests.
pub fn encode_automation_create_request(
  request: AutomationCreateRequest,
) -> Json {
  json.object([
    #("name", json.string(request.name)),
    #("description", json.string(request.description)),
    #("type", json.string(automation_type_to_string(request.automation_type))),
    #("param_1", json.string(request.param_1)),
    #("param_2", json.string(request.param_2)),
    #("param_3", case request.param_3 {
      Some(val) -> json.string(val)
      None -> json.null()
    }),
    #("order", json.int(request.order)),
    #("disabled", json.bool(request.disabled)),
  ])
}

/// Encode an AutomationUpdateRequest to JSON
///
/// Only includes fields that are being updated (partial update support).
pub fn encode_automation_update_request(
  request: AutomationUpdateRequest,
) -> Json {
  let fields = []

  let fields = case request.name {
    Some(name) -> [#("name", json.string(name)), ..fields]
    None -> fields
  }

  let fields = case request.description {
    Some(desc) -> [#("description", json.string(desc)), ..fields]
    None -> fields
  }

  let fields = case request.automation_type {
    Some(atype) -> [
      #("type", json.string(automation_type_to_string(atype))),
      ..fields
    ]
    None -> fields
  }

  let fields = case request.param_1 {
    Some(p1) -> [#("param_1", json.string(p1)), ..fields]
    None -> fields
  }

  let fields = case request.param_2 {
    Some(p2) -> [#("param_2", json.string(p2)), ..fields]
    None -> fields
  }

  let fields = case request.param_3 {
    Some(opt_p3) -> [
      #("param_3", case opt_p3 {
        Some(p3) -> json.string(p3)
        None -> json.null()
      }),
      ..fields
    ]
    None -> fields
  }

  let fields = case request.order {
    Some(ord) -> [#("order", json.int(ord)), ..fields]
    None -> fields
  }

  let fields = case request.disabled {
    Some(dis) -> [#("disabled", json.bool(dis)), ..fields]
    None -> fields
  }

  json.object(fields)
}

// ============================================================================
// API - CRUD Operations
// ============================================================================

/// Get all automations from Tandoor API
pub fn list_automations(
  config: ClientConfig,
) -> Result(List(Automation), TandoorError) {
  use resp <- result.try(execute_get(config, "/api/automation/", []))
  parse_json_list(resp, automation_decoder())
}

/// Get a single automation by ID
pub fn get_automation(
  config: ClientConfig,
  automation_id automation_id: Int,
) -> Result(Automation, TandoorError) {
  let path = "/api/automation/" <> int.to_string(automation_id) <> "/"
  use resp <- result.try(execute_get(config, path, []))
  parse_json_single(resp, automation_decoder())
}

/// Create a new automation in Tandoor
pub fn create_automation(
  config: ClientConfig,
  create_data: AutomationCreateRequest,
) -> Result(Automation, TandoorError) {
  let body =
    encode_automation_create_request(create_data)
    |> json.to_string
  use resp <- result.try(execute_post(config, "/api/automation/", body))
  parse_json_single(resp, automation_decoder())
}

/// Update an existing automation (supports partial updates)
pub fn update_automation(
  config: ClientConfig,
  automation_id automation_id: Int,
  data update_data: AutomationUpdateRequest,
) -> Result(Automation, TandoorError) {
  let path = "/api/automation/" <> int.to_string(automation_id) <> "/"
  let body =
    encode_automation_update_request(update_data)
    |> json.to_string
  use resp <- result.try(execute_patch(config, path, body))
  parse_json_single(resp, automation_decoder())
}

/// Delete an automation from Tandoor
pub fn delete_automation(
  config: ClientConfig,
  automation_id automation_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/automation/" <> int.to_string(automation_id) <> "/"
  use _resp <- result.try(execute_delete(config, path))
  Ok(Nil)
}

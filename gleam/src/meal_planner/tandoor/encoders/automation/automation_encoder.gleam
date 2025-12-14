/// Automation encoder for Tandoor SDK
///
/// This module provides JSON encoders for Automation types.
/// Handles encoding for create and update requests.
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/types/automation/automation.{
  type AutomationType, DescriptionReplace, FoodAlias, KeywordAlias, UnitAlias,
}

/// Request type for creating an automation
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

/// Request type for updating an automation (all fields optional)
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

/// Convert AutomationType to JSON string
fn automation_type_to_string(automation_type: AutomationType) -> String {
  case automation_type {
    FoodAlias -> "FOOD_ALIAS"
    UnitAlias -> "UNIT_ALIAS"
    KeywordAlias -> "KEYWORD_ALIAS"
    DescriptionReplace -> "DESCRIPTION_REPLACE"
  }
}

/// Encode AutomationCreateRequest to JSON
///
/// # Arguments
/// * `req` - Automation create request
///
/// # Returns
/// JSON representation
pub fn encode_automation_create_request(req: AutomationCreateRequest) -> Json {
  json.object([
    #("name", json.string(req.name)),
    #("description", json.string(req.description)),
    #("type", json.string(automation_type_to_string(req.automation_type))),
    #("param_1", json.string(req.param_1)),
    #("param_2", json.string(req.param_2)),
    #("param_3", case req.param_3 {
      Some(val) -> json.string(val)
      None -> json.null()
    }),
    #("order", json.int(req.order)),
    #("disabled", json.bool(req.disabled)),
  ])
}

/// Encode AutomationUpdateRequest to JSON
///
/// Only includes fields that are Some(_), allowing partial updates
///
/// # Arguments
/// * `req` - Automation update request
///
/// # Returns
/// JSON representation
pub fn encode_automation_update_request(req: AutomationUpdateRequest) -> Json {
  let fields = []

  let fields = case req.name {
    Some(name) -> [#("name", json.string(name)), ..fields]
    None -> fields
  }

  let fields = case req.description {
    Some(desc) -> [#("description", json.string(desc)), ..fields]
    None -> fields
  }

  let fields = case req.automation_type {
    Some(atype) -> [
      #("type", json.string(automation_type_to_string(atype))),
      ..fields
    ]
    None -> fields
  }

  let fields = case req.param_1 {
    Some(p1) -> [#("param_1", json.string(p1)), ..fields]
    None -> fields
  }

  let fields = case req.param_2 {
    Some(p2) -> [#("param_2", json.string(p2)), ..fields]
    None -> fields
  }

  let fields = case req.param_3 {
    Some(opt_p3) -> [
      #("param_3", case opt_p3 {
        Some(p3) -> json.string(p3)
        None -> json.null()
      }),
      ..fields
    ]
    None -> fields
  }

  let fields = case req.order {
    Some(ord) -> [#("order", json.int(ord)), ..fields]
    None -> fields
  }

  let fields = case req.disabled {
    Some(dis) -> [#("disabled", json.bool(dis)), ..fields]
    None -> fields
  }

  json.object(fields)
}

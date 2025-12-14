/// Tandoor Automation type definition
///
/// This module defines the Automation type used for automatic recipe processing in Tandoor.
/// Automations allow automatic replacement/transformation of Foods, Units, Keywords, and Descriptions
/// during recipe import and editing.
///
/// Automation Types:
/// - FOOD_ALIAS: Replace one food with another
/// - UNIT_ALIAS: Replace one unit with another
/// - KEYWORD_ALIAS: Replace one keyword with another
/// - DESCRIPTION_REPLACE: Replace patterns in recipe descriptions using RegEx
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/option.{type Option}

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

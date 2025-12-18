/// Tandoor SDK - Recipe Step Type
///
/// Represents a single step in a recipe's cooking instructions.
/// Based on the Tandoor API Step schema (PatchedStep).
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids.{type IngredientId, type StepId}

/// A single step in a recipe's instructions
///
/// Represents a cooking step with instructions, timing, and optional
/// ingredients and files. Steps can be marked as headers for organization.
///
/// ## Fields
/// - `id`: Unique identifier for the step
/// - `name`: Short name/title for the step (max 128 chars)
/// - `instruction`: Full instruction text (plaintext)
/// - `instruction_markdown`: Optional markdown-formatted instructions (read-only)
/// - `ingredients`: List of ingredient IDs used in this step
/// - `time`: Time required in minutes
/// - `order`: Display order in the recipe (lower = earlier)
/// - `show_as_header`: If true, display as section header
/// - `show_ingredients_table`: If true, show ingredient table for this step
/// - `file`: Optional attached file (image, video, etc.)
pub type Step {
  Step(
    id: StepId,
    name: String,
    instruction: String,
    instruction_markdown: Option(String),
    ingredients: List(IngredientId),
    time: Int,
    order: Int,
    show_as_header: Bool,
    show_ingredients_table: Bool,
    file: Option(String),
  )
}

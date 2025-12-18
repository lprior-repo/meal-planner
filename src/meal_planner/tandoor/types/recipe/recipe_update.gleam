import gleam/option.{type Option}

/// Request to update an existing recipe (partial update)
///
/// All fields are optional to support partial updates.
/// Only provided fields will be sent in the PATCH request.
pub type RecipeUpdate {
  RecipeUpdate(
    name: Option(String),
    description: Option(String),
    servings: Option(Int),
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

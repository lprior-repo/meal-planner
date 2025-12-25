/// Weight Entry Form Component
///
/// Provides reusable form components for weight entry input.
///
/// FUNCTIONS:
/// - weight_input_field: Weight value input field
/// - comment_input_field: Comment input field
/// - form_buttons: Standard form action buttons
import shore
import shore/style
import shore/ui

// ============================================================================
// Public API
// ============================================================================

/// Render weight input field with validation
pub fn weight_input_field(
  weight_str: String,
  on_change: fn(String) -> msg,
) -> shore.Node(msg) {
  ui.input("Weight (kg):", weight_str, style.Pct(30), on_change)
}

/// Render comment input field
pub fn comment_input_field(
  comment: String,
  on_change: fn(String) -> msg,
) -> shore.Node(msg) {
  ui.input("Comment:", comment, style.Pct(60), on_change)
}

/// Render standard form action buttons
pub fn form_buttons(save_text: String, cancel_text: String) -> shore.Node(msg) {
  ui.text_styled(
    "[Enter] " <> save_text <> "  [Esc] " <> cancel_text,
    Some(style.Cyan),
    None,
  )
}

/// Render validation feedback for weight value
pub fn weight_validation_message(
  parsed_weight: Bool,
  weight_str: String,
) -> List(shore.Node(msg)) {
  case parsed_weight {
    True -> []
    False ->
      case weight_str {
        "" -> []
        _ -> [ui.text_styled("Invalid weight", Some(style.Red), None)]
      }
  }
}

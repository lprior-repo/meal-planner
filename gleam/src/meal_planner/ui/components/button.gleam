/// Button Components Module
///
/// This module provides button components with various variants and states:
/// - Basic button links
/// - Sized buttons
/// - Submit buttons
/// - Disabled states
/// - Button groups
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Buttons)
import gleam/string
import meal_planner/ui/types/ui_types

// ===================================================================
// HELPER FUNCTIONS
// ===================================================================

/// Convert ButtonVariant to CSS class string
fn variant_to_class(variant: ui_types.ButtonVariant) -> String {
  case variant {
    ui_types.Primary -> "btn-primary"
    ui_types.Secondary -> "btn-secondary"
    ui_types.Danger -> "btn-danger"
    ui_types.Success -> "btn-success"
    ui_types.Warning -> "btn-warning"
    ui_types.Ghost -> "btn-ghost"
  }
}

/// Convert ButtonSize to CSS class string
fn size_to_class(size: ui_types.ButtonSize) -> String {
  case size {
    ui_types.Small -> "btn-sm"
    ui_types.Medium -> "btn-md"
    ui_types.Large -> "btn-lg"
  }
}

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Basic button link
///
/// Renders: <a href="/path" class="btn btn-primary">Label</a>
pub fn button(
  label: String,
  href: String,
  variant: ui_types.ButtonVariant,
) -> String {
  // CONTRACT: Returns HTML string for button link with variant classes
  let variant_class = variant_to_class(variant)
  "<a href=\""
  <> href
  <> "\" class=\"btn "
  <> variant_class
  <> "\">"
  <> label
  <> "</a>"
}

/// Button with custom size
///
/// Renders: <a href="/path" class="btn btn-primary btn-lg">Label</a>
pub fn button_sized(
  label: String,
  href: String,
  variant: ui_types.ButtonVariant,
  size: ui_types.ButtonSize,
) -> String {
  // CONTRACT: Returns HTML string for sized button link
  let variant_class = variant_to_class(variant)
  let size_class = size_to_class(size)
  "<a href=\""
  <> href
  <> "\" class=\"btn "
  <> variant_class
  <> " "
  <> size_class
  <> "\">"
  <> label
  <> "</a>"
}

/// Submit button for forms
///
/// Renders: <button type="submit" class="btn btn-primary">Label</button>
pub fn submit_button(label: String, variant: ui_types.ButtonVariant) -> String {
  // CONTRACT: Returns HTML string for submit button
  let variant_class = variant_to_class(variant)
  "<button type=\"submit\" class=\"btn "
  <> variant_class
  <> "\">"
  <> label
  <> "</button>"
}

/// Disabled button state
///
/// Renders: <button disabled class="btn btn-primary btn-disabled">Label</button>
pub fn button_disabled(label: String, variant: ui_types.ButtonVariant) -> String {
  // CONTRACT: Returns HTML string for disabled button
  let variant_class = variant_to_class(variant)
  "<button disabled class=\"btn "
  <> variant_class
  <> " btn-disabled\">"
  <> label
  <> "</button>"
}

/// Button group container
///
/// Renders: <div class="button-group">buttons...</div>
pub fn button_group(buttons: List(String)) -> String {
  // CONTRACT: Returns HTML string for button group container
  let buttons_html = string.concat(buttons)
  "<div class=\"button-group\">" <> buttons_html <> "</div>"
}

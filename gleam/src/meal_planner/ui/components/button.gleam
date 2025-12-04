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
import lustre/attribute
import lustre/element
import lustre/element/html
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
/// Renders: <a href="/path" class="btn btn-primary" role="button">Label</a>
pub fn button(
  label: String,
  href: String,
  variant: ui_types.ButtonVariant,
) -> element.Element(msg) {
  let variant_class = variant_to_class(variant)
  html.a(
    [
      attribute.href(href),
      attribute.class("btn " <> variant_class),
      attribute.attribute("role", "button"),
    ],
    [element.text(label)],
  )
}

/// Button with custom size
///
/// Renders: <a href="/path" class="btn btn-primary btn-lg" role="button">Label</a>
pub fn button_sized(
  label: String,
  href: String,
  variant: ui_types.ButtonVariant,
  size: ui_types.ButtonSize,
) -> element.Element(msg) {
  let variant_class = variant_to_class(variant)
  let size_class = size_to_class(size)
  html.a(
    [
      attribute.href(href),
      attribute.class("btn " <> variant_class <> " " <> size_class),
      attribute.attribute("role", "button"),
    ],
    [element.text(label)],
  )
}

/// Submit button for forms
///
/// Renders: <button type="submit" class="btn btn-primary">Label</button>
pub fn submit_button(
  label: String,
  variant: ui_types.ButtonVariant,
) -> element.Element(msg) {
  let variant_class = variant_to_class(variant)
  html.button(
    [attribute.type_("submit"), attribute.class("btn " <> variant_class)],
    [element.text(label)],
  )
}

/// Disabled button state
///
/// Renders: <button disabled class="btn btn-primary btn-disabled" aria-disabled="true">Label</button>
pub fn button_disabled(
  label: String,
  variant: ui_types.ButtonVariant,
) -> element.Element(msg) {
  let variant_class = variant_to_class(variant)
  html.button(
    [
      attribute.disabled(True),
      attribute.class("btn " <> variant_class <> " btn-disabled"),
      attribute.attribute("aria-disabled", "true"),
    ],
    [element.text(label)],
  )
}

/// Button group container
///
/// Renders: <div class="button-group">buttons...</div>
pub fn button_group(buttons: List(element.Element(msg))) -> element.Element(msg) {
  html.div([attribute.class("button-group")], buttons)
}

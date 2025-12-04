/// Typography Components Module
///
/// This module provides text and heading components:
/// - Heading levels (h1-h6)
/// - Body text
/// - Secondary text
/// - Label text
/// - Emphasized text (strong, italic, code, underline)
/// - Monospace text
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Typography)
import gleam/option.{type Option}
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/ui/types/ui_types

// ===================================================================
// HEADING COMPONENTS
// ===================================================================

/// Heading level 1
///
/// Renders: <h1>text</h1>
pub fn h1(text: String) -> element.Element(msg) {
  html.h1([], [element.text(text)])
}

/// Heading level 2
///
/// Renders: <h2>text</h2>
pub fn h2(text: String) -> element.Element(msg) {
  html.h2([], [element.text(text)])
}

/// Heading level 3
///
/// Renders: <h3>text</h3>
pub fn h3(text: String) -> element.Element(msg) {
  html.h3([], [element.text(text)])
}

/// Heading level 4
///
/// Renders: <h4>text</h4>
pub fn h4(text: String) -> element.Element(msg) {
  html.h4([], [element.text(text)])
}

/// Heading level 5
///
/// Renders: <h5>text</h5>
pub fn h5(text: String) -> element.Element(msg) {
  html.h5([], [element.text(text)])
}

/// Heading level 6
///
/// Renders: <h6>text</h6>
pub fn h6(text: String) -> element.Element(msg) {
  html.h6([], [element.text(text)])
}

/// Heading with optional subtitle
///
/// Renders:
/// <div class="heading-group">
///   <h{level}>title</h{level}>
///   <p class="subtitle">subtitle</p>
/// </div>
pub fn heading_with_subtitle(
  level: Int,
  title: String,
  subtitle: Option(String),
) -> element.Element(msg) {
  let heading_element = case level {
    1 -> h1(title)
    2 -> h2(title)
    3 -> h3(title)
    4 -> h4(title)
    5 -> h5(title)
    6 -> h6(title)
    _ -> h1(title)
  }

  let children = case subtitle {
    option.Some(text) -> [
      heading_element,
      html.p([attribute.class("subtitle")], [element.text(text)]),
    ]
    option.None -> [heading_element]
  }

  html.div([attribute.class("heading-group")], children)
}

// ===================================================================
// BODY TEXT COMPONENTS
// ===================================================================

/// Body text (paragraph)
///
/// Renders: <p class="body-text">text</p>
pub fn body_text(text: String) -> element.Element(msg) {
  html.p([attribute.class("body-text")], [element.text(text)])
}

/// Small/secondary text
///
/// Renders: <small class="secondary-text">text</small>
pub fn secondary_text(text: String) -> element.Element(msg) {
  html.small([attribute.class("secondary-text")], [element.text(text)])
}

/// Label text (typically for forms)
///
/// Renders: <label for="for">text</label>
pub fn label_text(text: String, for: String) -> element.Element(msg) {
  html.label([attribute.for(for)], [element.text(text)])
}

// ===================================================================
// EMPHASIZED TEXT COMPONENTS
// ===================================================================

/// Text with semantic emphasis
///
/// Renders based on emphasis type:
/// - Normal: <span>text</span>
/// - Strong: <strong>text</strong>
/// - Italic: <em>text</em>
/// - Code: <code>text</code>
/// - Underline: <u>text</u>
pub fn emphasize_text(
  text: String,
  emphasis: ui_types.TextEmphasis,
) -> element.Element(msg) {
  case emphasis {
    ui_types.Normal -> html.span([], [element.text(text)])
    ui_types.Strong -> html.strong([], [element.text(text)])
    ui_types.Italic -> html.em([], [element.text(text)])
    ui_types.Code -> html.code([], [element.text(text)])
    ui_types.Underline -> html.u([], [element.text(text)])
  }
}

/// Monospace text (for code/numbers)
///
/// Renders: <code class="mono-text">text</code>
pub fn mono_text(text: String) -> element.Element(msg) {
  html.code([attribute.class("mono-text")], [element.text(text)])
}

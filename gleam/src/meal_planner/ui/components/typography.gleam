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
import meal_planner/ui/types/ui_types

// ===================================================================
// HEADING COMPONENTS
// ===================================================================

/// Heading level 1
///
/// Renders: <h1>text</h1>
pub fn h1(text: String) -> String {
  // CONTRACT: Returns HTML string for h1 heading
  // BODY: Implement as h1 element
  "<h1>" <> text <> "</h1>"
}

/// Heading level 2
///
/// Renders: <h2>text</h2>
pub fn h2(text: String) -> String {
  // CONTRACT: Returns HTML string for h2 heading
  // BODY: Implement as h2 element
  "<h2>" <> text <> "</h2>"
}

/// Heading level 3
///
/// Renders: <h3>text</h3>
pub fn h3(text: String) -> String {
  // CONTRACT: Returns HTML string for h3 heading
  // BODY: Implement as h3 element
  "<h3>" <> text <> "</h3>"
}

/// Heading level 4
///
/// Renders: <h4>text</h4>
pub fn h4(text: String) -> String {
  // CONTRACT: Returns HTML string for h4 heading
  // BODY: Implement as h4 element
  "<h4>" <> text <> "</h4>"
}

/// Heading level 5
///
/// Renders: <h5>text</h5>
pub fn h5(text: String) -> String {
  // CONTRACT: Returns HTML string for h5 heading
  // BODY: Implement as h5 element
  "<h5>" <> text <> "</h5>"
}

/// Heading level 6
///
/// Renders: <h6>text</h6>
pub fn h6(text: String) -> String {
  // CONTRACT: Returns HTML string for h6 heading
  // BODY: Implement as h6 element
  "<h6>" <> text <> "</h6>"
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
) -> String {
  // CONTRACT: Returns HTML string for heading with optional subtitle
  // BODY: Implement with dynamic heading level and conditional subtitle
  let heading_tag = case level {
    1 -> h1(title)
    2 -> h2(title)
    3 -> h3(title)
    4 -> h4(title)
    5 -> h5(title)
    6 -> h6(title)
    _ -> h1(title)
  }

  let subtitle_html = case subtitle {
    option.Some(text) -> "<p class=\"subtitle\">" <> text <> "</p>"
    option.None -> ""
  }

  "<div class=\"heading-group\">" <> heading_tag <> subtitle_html <> "</div>"
}

// ===================================================================
// BODY TEXT COMPONENTS
// ===================================================================

/// Body text (paragraph)
///
/// Renders: <p class="body-text">text</p>
pub fn body_text(text: String) -> String {
  // CONTRACT: Returns HTML string for body paragraph
  // BODY: Implement as p element with body-text class
  "<p class=\"body-text\">" <> text <> "</p>"
}

/// Small/secondary text
///
/// Renders: <small class="secondary-text">text</small>
pub fn secondary_text(text: String) -> String {
  // CONTRACT: Returns HTML string for secondary text
  // BODY: Implement as small element with secondary-text class
  "<small class=\"secondary-text\">" <> text <> "</small>"
}

/// Label text (typically for forms)
///
/// Renders: <label for="for">text</label>
pub fn label_text(text: String, for: String) -> String {
  // CONTRACT: Returns HTML string for label
  // BODY: Implement as label element with for attribute
  "<label for=\"" <> for <> "\">" <> text <> "</label>"
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
) -> String {
  // CONTRACT: Returns HTML string with semantic emphasis element
  // BODY: Implement with appropriate HTML element for each emphasis type
  case emphasis {
    ui_types.Normal -> "<span>" <> text <> "</span>"
    ui_types.Strong -> "<strong>" <> text <> "</strong>"
    ui_types.Italic -> "<em>" <> text <> "</em>"
    ui_types.Code -> "<code>" <> text <> "</code>"
    ui_types.Underline -> "<u>" <> text <> "</u>"
  }
}

/// Monospace text (for code/numbers)
///
/// Renders: <code class="mono-text">text</code>
pub fn mono_text(text: String) -> String {
  // CONTRACT: Returns HTML string for monospace text
  // BODY: Implement as code element with mono-text class
  "<code class=\"mono-text\">" <> text <> "</code>"
}

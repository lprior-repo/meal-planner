/// Typography Component Tests
///
/// This module defines tests for typography components.
/// Tests verify that typography components render correct HTML and CSS classes.
import gleam/option
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/ui/components/typography
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// Custom assertion for string containment
fn assert_contains(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    True -> Nil
    False -> {
      let _msg =
        string.concat([
          "\n",
          haystack,
          "\nshould contain\n",
          needle,
        ])
      should.fail()
    }
  }
}

// ===================================================================
// HEADING LEVEL TESTS
// ===================================================================

pub fn h1_renders_correct_tag_test() {
  let result = typography.h1("Main Title")
  assert_contains(result, "<h1>")
  assert_contains(result, "Main Title")
  assert_contains(result, "</h1>")
}

pub fn h2_renders_correct_tag_test() {
  let result = typography.h2("Subtitle")
  assert_contains(result, "<h2>")
  assert_contains(result, "Subtitle")
  assert_contains(result, "</h2>")
}

pub fn h3_renders_correct_tag_test() {
  let result = typography.h3("Section")
  assert_contains(result, "<h3>")
  assert_contains(result, "Section")
  assert_contains(result, "</h3>")
}

pub fn h4_renders_correct_tag_test() {
  let result = typography.h4("Subsection")
  assert_contains(result, "<h4>")
  assert_contains(result, "Subsection")
  assert_contains(result, "</h4>")
}

pub fn h5_renders_correct_tag_test() {
  let result = typography.h5("Minor heading")
  assert_contains(result, "<h5>")
  assert_contains(result, "Minor heading")
  assert_contains(result, "</h5>")
}

pub fn h6_renders_correct_tag_test() {
  let result = typography.h6("Smallest heading")
  assert_contains(result, "<h6>")
  assert_contains(result, "Smallest heading")
  assert_contains(result, "</h6>")
}

// ===================================================================
// HEADING WITH SUBTITLE TESTS
// ===================================================================

pub fn heading_with_subtitle_level_1_test() {
  let result =
    typography.heading_with_subtitle(1, "Title", option.Some("Subtitle"))
  assert_contains(result, "<h1>")
  assert_contains(result, "Title")
  assert_contains(result, "Subtitle")
}

pub fn heading_with_subtitle_level_2_test() {
  let result =
    typography.heading_with_subtitle(2, "Title", option.Some("Subtitle"))
  assert_contains(result, "<h2>")
  assert_contains(result, "Title")
  assert_contains(result, "Subtitle")
}

pub fn heading_with_subtitle_level_3_test() {
  let result =
    typography.heading_with_subtitle(3, "Title", option.Some("Subtitle"))
  assert_contains(result, "<h3>")
  assert_contains(result, "Title")
  assert_contains(result, "Subtitle")
}

pub fn heading_with_subtitle_level_4_test() {
  let result =
    typography.heading_with_subtitle(4, "Title", option.Some("Subtitle"))
  assert_contains(result, "<h4>")
  assert_contains(result, "Title")
  assert_contains(result, "Subtitle")
}

pub fn heading_with_subtitle_level_5_test() {
  let result =
    typography.heading_with_subtitle(5, "Title", option.Some("Subtitle"))
  assert_contains(result, "<h5>")
  assert_contains(result, "Title")
  assert_contains(result, "Subtitle")
}

pub fn heading_with_subtitle_level_6_test() {
  let result =
    typography.heading_with_subtitle(6, "Title", option.Some("Subtitle"))
  assert_contains(result, "<h6>")
  assert_contains(result, "Title")
  assert_contains(result, "Subtitle")
}

pub fn heading_with_subtitle_none_test() {
  let result = typography.heading_with_subtitle(1, "Title", option.None)
  assert_contains(result, "<h1>")
  assert_contains(result, "Title")
  assert_contains(result, "heading-group")
}

pub fn heading_with_subtitle_container_test() {
  let result =
    typography.heading_with_subtitle(1, "Title", option.Some("Subtitle"))
  assert_contains(result, "heading-group")
}

pub fn heading_with_subtitle_subtitle_class_test() {
  let result =
    typography.heading_with_subtitle(1, "Title", option.Some("Subtitle"))
  assert_contains(result, "subtitle")
}

pub fn heading_with_subtitle_invalid_level_test() {
  let result =
    typography.heading_with_subtitle(10, "Title", option.Some("Subtitle"))
  assert_contains(result, "<h1>")
}

// ===================================================================
// BODY TEXT TESTS
// ===================================================================

pub fn body_text_renders_paragraph_test() {
  let result = typography.body_text("This is body text")
  assert_contains(result, "<p")
  assert_contains(result, "This is body text")
  assert_contains(result, "</p>")
}

pub fn body_text_includes_class_test() {
  let result = typography.body_text("Content")
  assert_contains(result, "body-text")
}

pub fn body_text_with_special_characters_test() {
  let result = typography.body_text("Text with & special < characters >")
  assert_contains(result, "Text with & special < characters >")
}

// ===================================================================
// SECONDARY TEXT TESTS
// ===================================================================

pub fn secondary_text_renders_small_tag_test() {
  let result = typography.secondary_text("Small text")
  assert_contains(result, "<small")
  assert_contains(result, "Small text")
  assert_contains(result, "</small>")
}

pub fn secondary_text_includes_class_test() {
  let result = typography.secondary_text("Secondary")
  assert_contains(result, "secondary-text")
}

// ===================================================================
// LABEL TEXT TESTS
// ===================================================================

pub fn label_text_renders_label_tag_test() {
  let result = typography.label_text("Username", "username-input")
  assert_contains(result, "<label")
  assert_contains(result, "Username")
  assert_contains(result, "</label>")
}

pub fn label_text_includes_for_attribute_test() {
  let result = typography.label_text("Email", "email-field")
  assert_contains(result, "for=\"email-field\"")
}

pub fn label_text_with_different_ids_test() {
  let result1 = typography.label_text("Field 1", "field-1")
  let result2 = typography.label_text("Field 2", "field-2")
  assert_contains(result1, "for=\"field-1\"")
  assert_contains(result2, "for=\"field-2\"")
}

// ===================================================================
// EMPHASIS TEXT TESTS
// ===================================================================

pub fn emphasize_text_normal_test() {
  let result = typography.emphasize_text("normal text", ui_types.Normal)
  assert_contains(result, "<span>")
  assert_contains(result, "normal text")
  assert_contains(result, "</span>")
}

pub fn emphasize_text_strong_test() {
  let result = typography.emphasize_text("important", ui_types.Strong)
  assert_contains(result, "<strong>")
  assert_contains(result, "important")
  assert_contains(result, "</strong>")
}

pub fn emphasize_text_italic_test() {
  let result = typography.emphasize_text("emphasized", ui_types.Italic)
  assert_contains(result, "<em>")
  assert_contains(result, "emphasized")
  assert_contains(result, "</em>")
}

pub fn emphasize_text_code_test() {
  let result = typography.emphasize_text("variable", ui_types.Code)
  assert_contains(result, "<code>")
  assert_contains(result, "variable")
  assert_contains(result, "</code>")
}

pub fn emphasize_text_underline_test() {
  let result = typography.emphasize_text("underlined", ui_types.Underline)
  assert_contains(result, "<u>")
  assert_contains(result, "underlined")
  assert_contains(result, "</u>")
}

// ===================================================================
// MONOSPACE TEXT TESTS
// ===================================================================

pub fn mono_text_renders_code_tag_test() {
  let result = typography.mono_text("const x = 42")
  assert_contains(result, "<code")
  assert_contains(result, "const x = 42")
  assert_contains(result, "</code>")
}

pub fn mono_text_includes_class_test() {
  let result = typography.mono_text("monospace")
  assert_contains(result, "mono-text")
}

pub fn mono_text_preserves_whitespace_test() {
  let result = typography.mono_text("  spaced  content  ")
  assert_contains(result, "  spaced  content  ")
}

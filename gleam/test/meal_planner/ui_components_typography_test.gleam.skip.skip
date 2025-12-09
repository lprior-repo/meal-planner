/// Typography Component Tests
///
/// Tests for typography components including:
/// - Heading levels (h1-h6)
/// - Text variants (body, secondary, label)
/// - Text emphasis (strong, italic, code, underline)
/// - Accessibility and semantic markup
/// - Style application
import gleam/option
import gleeunit
import gleeunit/should
import meal_planner/ui/components/typography
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// HEADING LEVEL TESTS
// ===================================================================

pub fn h1_renders_correctly_test() {
  let result = typography.h1("Main Title")

  result
  |> should.equal("<h1>Main Title</h1>")
}

pub fn h1_handles_empty_text_test() {
  let result = typography.h1("")

  result
  |> should.equal("<h1></h1>")
}

pub fn h1_handles_special_characters_test() {
  let result = typography.h1("Title & Subtitle")

  result
  |> should.equal("<h1>Title & Subtitle</h1>")
}

pub fn h2_renders_correctly_test() {
  let result = typography.h2("Section Title")

  result
  |> should.equal("<h2>Section Title</h2>")
}

pub fn h2_handles_numbers_test() {
  let result = typography.h2("Chapter 1")

  result
  |> should.equal("<h2>Chapter 1</h2>")
}

pub fn h3_renders_correctly_test() {
  let result = typography.h3("Subsection")

  result
  |> should.equal("<h3>Subsection</h3>")
}

pub fn h3_handles_long_text_test() {
  let long_text = "This is a very long heading that spans multiple words"
  let result = typography.h3(long_text)

  result
  |> should.equal("<h3>" <> long_text <> "</h3>")
}

pub fn h4_renders_correctly_test() {
  let result = typography.h4("Detail Header")

  result
  |> should.equal("<h4>Detail Header</h4>")
}

pub fn h5_renders_correctly_test() {
  let result = typography.h5("Minor Heading")

  result
  |> should.equal("<h5>Minor Heading</h5>")
}

pub fn h6_renders_correctly_test() {
  let result = typography.h6("Smallest Heading")

  result
  |> should.equal("<h6>Smallest Heading</h6>")
}

// ===================================================================
// HEADING WITH SUBTITLE TESTS
// ===================================================================

pub fn heading_with_subtitle_h1_with_subtitle_test() {
  let result =
    typography.heading_with_subtitle(
      1,
      "Main Title",
      option.Some("Subtitle text"),
    )

  result
  |> should.equal(
    "<div class=\"heading-group\"><h1>Main Title</h1><p class=\"subtitle\">Subtitle text</p></div>",
  )
}

pub fn heading_with_subtitle_h1_without_subtitle_test() {
  let result = typography.heading_with_subtitle(1, "Main Title", option.None)

  result
  |> should.equal("<div class=\"heading-group\"><h1>Main Title</h1></div>")
}

pub fn heading_with_subtitle_h2_with_subtitle_test() {
  let result =
    typography.heading_with_subtitle(2, "Section", option.Some("Description"))

  result
  |> should.equal(
    "<div class=\"heading-group\"><h2>Section</h2><p class=\"subtitle\">Description</p></div>",
  )
}

pub fn heading_with_subtitle_h3_with_subtitle_test() {
  let result =
    typography.heading_with_subtitle(3, "Subsection", option.Some("Details"))

  result
  |> should.equal(
    "<div class=\"heading-group\"><h3>Subsection</h3><p class=\"subtitle\">Details</p></div>",
  )
}

pub fn heading_with_subtitle_h4_without_subtitle_test() {
  let result = typography.heading_with_subtitle(4, "Detail", option.None)

  result
  |> should.equal("<div class=\"heading-group\"><h4>Detail</h4></div>")
}

pub fn heading_with_subtitle_h5_with_subtitle_test() {
  let result = typography.heading_with_subtitle(5, "Minor", option.Some("Note"))

  result
  |> should.equal(
    "<div class=\"heading-group\"><h5>Minor</h5><p class=\"subtitle\">Note</p></div>",
  )
}

pub fn heading_with_subtitle_h6_with_subtitle_test() {
  let result =
    typography.heading_with_subtitle(6, "Smallest", option.Some("Tiny"))

  result
  |> should.equal(
    "<div class=\"heading-group\"><h6>Smallest</h6><p class=\"subtitle\">Tiny</p></div>",
  )
}

pub fn heading_with_subtitle_defaults_to_h1_for_invalid_level_test() {
  let result =
    typography.heading_with_subtitle(99, "Invalid Level", option.None)

  result
  |> should.equal("<div class=\"heading-group\"><h1>Invalid Level</h1></div>")
}

pub fn heading_with_subtitle_handles_zero_level_test() {
  let result = typography.heading_with_subtitle(0, "Zero Level", option.None)

  result
  |> should.equal("<div class=\"heading-group\"><h1>Zero Level</h1></div>")
}

pub fn heading_with_subtitle_handles_negative_level_test() {
  let result = typography.heading_with_subtitle(-1, "Negative", option.None)

  result
  |> should.equal("<div class=\"heading-group\"><h1>Negative</h1></div>")
}

// ===================================================================
// BODY TEXT TESTS
// ===================================================================

pub fn body_text_renders_correctly_test() {
  let result = typography.body_text("This is a paragraph.")

  result
  |> should.equal("<p class=\"body-text\">This is a paragraph.</p>")
}

pub fn body_text_handles_empty_test() {
  let result = typography.body_text("")

  result
  |> should.equal("<p class=\"body-text\"></p>")
}

pub fn body_text_handles_multiple_sentences_test() {
  let text = "First sentence. Second sentence. Third sentence."
  let result = typography.body_text(text)

  result
  |> should.equal("<p class=\"body-text\">" <> text <> "</p>")
}

pub fn body_text_has_correct_class_test() {
  let result = typography.body_text("Test")

  result
  |> should.contain("class=\"body-text\"")
}

// ===================================================================
// SECONDARY TEXT TESTS
// ===================================================================

pub fn secondary_text_renders_correctly_test() {
  let result = typography.secondary_text("Small text")

  result
  |> should.equal("<small class=\"secondary-text\">Small text</small>")
}

pub fn secondary_text_uses_small_element_test() {
  let result = typography.secondary_text("Test")

  result
  |> should.contain("<small")
  result
  |> should.contain("</small>")
}

pub fn secondary_text_has_correct_class_test() {
  let result = typography.secondary_text("Test")

  result
  |> should.contain("class=\"secondary-text\"")
}

pub fn secondary_text_handles_empty_test() {
  let result = typography.secondary_text("")

  result
  |> should.equal("<small class=\"secondary-text\"></small>")
}

// ===================================================================
// LABEL TEXT TESTS
// ===================================================================

pub fn label_text_renders_correctly_test() {
  let result = typography.label_text("Username", "username-input")

  result
  |> should.equal("<label for=\"username-input\">Username</label>")
}

pub fn label_text_has_correct_for_attribute_test() {
  let result = typography.label_text("Email", "email-field")

  result
  |> should.contain("for=\"email-field\"")
}

pub fn label_text_handles_empty_text_test() {
  let result = typography.label_text("", "field")

  result
  |> should.equal("<label for=\"field\"></label>")
}

pub fn label_text_handles_empty_for_test() {
  let result = typography.label_text("Label", "")

  result
  |> should.equal("<label for=\"\">Label</label>")
}

pub fn label_text_handles_complex_for_id_test() {
  let result = typography.label_text("Password", "user-password-field-123")

  result
  |> should.equal("<label for=\"user-password-field-123\">Password</label>")
}

// ===================================================================
// EMPHASIZED TEXT TESTS
// ===================================================================

pub fn emphasize_text_normal_renders_correctly_test() {
  let result = typography.emphasize_text("Normal text", ui_types.Normal)

  result
  |> should.equal("<span>Normal text</span>")
}

pub fn emphasize_text_strong_renders_correctly_test() {
  let result = typography.emphasize_text("Important", ui_types.Strong)

  result
  |> should.equal("<strong>Important</strong>")
}

pub fn emphasize_text_strong_uses_semantic_element_test() {
  let result = typography.emphasize_text("Bold", ui_types.Strong)

  result
  |> should.contain("<strong>")
  result
  |> should.contain("</strong>")
}

pub fn emphasize_text_italic_renders_correctly_test() {
  let result = typography.emphasize_text("Emphasized", ui_types.Italic)

  result
  |> should.equal("<em>Emphasized</em>")
}

pub fn emphasize_text_italic_uses_semantic_element_test() {
  let result = typography.emphasize_text("Italic", ui_types.Italic)

  result
  |> should.contain("<em>")
  result
  |> should.contain("</em>")
}

pub fn emphasize_text_code_renders_correctly_test() {
  let result = typography.emphasize_text("const x = 42", ui_types.Code)

  result
  |> should.equal("<code>const x = 42</code>")
}

pub fn emphasize_text_code_uses_semantic_element_test() {
  let result = typography.emphasize_text("code", ui_types.Code)

  result
  |> should.contain("<code>")
  result
  |> should.contain("</code>")
}

pub fn emphasize_text_underline_renders_correctly_test() {
  let result = typography.emphasize_text("Underlined", ui_types.Underline)

  result
  |> should.equal("<u>Underlined</u>")
}

pub fn emphasize_text_underline_uses_semantic_element_test() {
  let result = typography.emphasize_text("text", ui_types.Underline)

  result
  |> should.contain("<u>")
  result
  |> should.contain("</u>")
}

pub fn emphasize_text_handles_empty_normal_test() {
  let result = typography.emphasize_text("", ui_types.Normal)

  result
  |> should.equal("<span></span>")
}

pub fn emphasize_text_handles_empty_strong_test() {
  let result = typography.emphasize_text("", ui_types.Strong)

  result
  |> should.equal("<strong></strong>")
}

pub fn emphasize_text_handles_special_chars_in_code_test() {
  let result = typography.emphasize_text("x && y || z", ui_types.Code)

  result
  |> should.equal("<code>x && y || z</code>")
}

// ===================================================================
// MONOSPACE TEXT TESTS
// ===================================================================

pub fn mono_text_renders_correctly_test() {
  let result = typography.mono_text("123.45")

  result
  |> should.equal("<code class=\"mono-text\">123.45</code>")
}

pub fn mono_text_uses_code_element_test() {
  let result = typography.mono_text("test")

  result
  |> should.contain("<code")
  result
  |> should.contain("</code>")
}

pub fn mono_text_has_correct_class_test() {
  let result = typography.mono_text("test")

  result
  |> should.contain("class=\"mono-text\"")
}

pub fn mono_text_handles_numbers_test() {
  let result = typography.mono_text("42")

  result
  |> should.equal("<code class=\"mono-text\">42</code>")
}

pub fn mono_text_handles_code_snippet_test() {
  let result = typography.mono_text("const x = 10;")

  result
  |> should.equal("<code class=\"mono-text\">const x = 10;</code>")
}

pub fn mono_text_handles_empty_test() {
  let result = typography.mono_text("")

  result
  |> should.equal("<code class=\"mono-text\"></code>")
}

// ===================================================================
// SEMANTIC MARKUP TESTS (Accessibility)
// ===================================================================

pub fn headings_use_semantic_html_test() {
  // Verify all headings use proper semantic elements
  typography.h1("Test")
  |> should.contain("<h1>")

  typography.h2("Test")
  |> should.contain("<h2>")

  typography.h3("Test")
  |> should.contain("<h3>")

  typography.h4("Test")
  |> should.contain("<h4>")

  typography.h5("Test")
  |> should.contain("<h5>")

  typography.h6("Test")
  |> should.contain("<h6>")
}

pub fn emphasis_uses_semantic_html_test() {
  // Verify emphasis types use semantic elements
  typography.emphasize_text("Strong", ui_types.Strong)
  |> should.contain("<strong>")

  typography.emphasize_text("Italic", ui_types.Italic)
  |> should.contain("<em>")

  typography.emphasize_text("Code", ui_types.Code)
  |> should.contain("<code>")
}

pub fn label_has_for_attribute_test() {
  // Verify labels have proper for attribute for accessibility
  let result = typography.label_text("Field Label", "field-id")

  result
  |> should.contain("for=\"field-id\"")
}

pub fn body_text_uses_paragraph_element_test() {
  // Verify body text uses proper paragraph element
  let result = typography.body_text("Content")

  result
  |> should.contain("<p")
  result
  |> should.contain("</p>")
}

// ===================================================================
// STYLE APPLICATION TESTS
// ===================================================================

pub fn body_text_applies_class_test() {
  let result = typography.body_text("Test")

  result
  |> should.contain("class=\"body-text\"")
}

pub fn secondary_text_applies_class_test() {
  let result = typography.secondary_text("Test")

  result
  |> should.contain("class=\"secondary-text\"")
}

pub fn mono_text_applies_class_test() {
  let result = typography.mono_text("Test")

  result
  |> should.contain("class=\"mono-text\"")
}

pub fn heading_group_applies_class_test() {
  let result = typography.heading_with_subtitle(1, "Title", option.None)

  result
  |> should.contain("class=\"heading-group\"")
}

pub fn subtitle_applies_class_test() {
  let result =
    typography.heading_with_subtitle(1, "Title", option.Some("Subtitle"))

  result
  |> should.contain("class=\"subtitle\"")
}

// ===================================================================
// INTEGRATION TESTS
// ===================================================================

pub fn multiple_headings_render_independently_test() {
  let h1_result = typography.h1("Title 1")
  let h2_result = typography.h2("Title 2")

  h1_result
  |> should.not_equal(h2_result)

  h1_result
  |> should.contain("<h1>")

  h2_result
  |> should.contain("<h2>")
}

pub fn text_variants_render_independently_test() {
  let body = typography.body_text("Body")
  let secondary = typography.secondary_text("Secondary")
  let mono = typography.mono_text("Mono")

  body
  |> should.not_equal(secondary)

  body
  |> should.not_equal(mono)

  secondary
  |> should.not_equal(mono)
}

pub fn emphasis_variants_render_independently_test() {
  let normal = typography.emphasize_text("Text", ui_types.Normal)
  let strong = typography.emphasize_text("Text", ui_types.Strong)
  let italic = typography.emphasize_text("Text", ui_types.Italic)

  normal
  |> should.not_equal(strong)

  normal
  |> should.not_equal(italic)

  strong
  |> should.not_equal(italic)
}

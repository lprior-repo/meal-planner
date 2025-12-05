/// Tests for UI Layout Components
///
/// This module tests:
/// - Flex container rendering with direction, alignment, justification
/// - Grid container rendering with responsive columns
/// - Spacing containers
/// - Max-width containers
/// - Page sections
/// - CSS class generation
/// - Accessibility (semantic HTML)
import gleam/string
import gleeunit
import gleeunit/should
import lustre/element
import meal_planner/ui/components/layout
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// ===================================================================
// FLEX COMPONENT TESTS
// ===================================================================

/// Test basic flex container with row direction
pub fn flex_row_basic_test() {
  let result =
    layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyBetween, 4, [
      element.text("<span>Item 1</span>"),
      element.text("<span>Item 2</span>"),
    ])
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"flex flex-row items-center justify-between gap-4\"><span>Item 1</span><span>Item 2</span></div>",
  )
}

/// Test flex container with column direction
pub fn flex_column_test() {
  let result =
    layout.flex(ui_types.Column, ui_types.AlignStart, ui_types.JustifyStart, 2, [
      element.text("<p>First</p>"),
      element.text("<p>Second</p>"),
    ])
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"flex flex-col items-start justify-start gap-2\"><p>First</p><p>Second</p></div>",
  )
}

/// Test flex container with row-reverse direction
pub fn flex_row_reverse_test() {
  let result =
    layout.flex(ui_types.RowReverse, ui_types.AlignEnd, ui_types.JustifyEnd, 8, [
      element.text("<div>A</div>"),
    ])
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"flex flex-row-reverse items-end justify-end gap-8\"><div>A</div></div>",
  )
}

/// Test flex container with column-reverse direction
pub fn flex_column_reverse_test() {
  let result =
    layout.flex(
      ui_types.ColumnReverse,
      ui_types.Stretch,
      ui_types.JustifyCenter,
      6,
      [],
    )
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"flex flex-col-reverse items-stretch justify-center gap-6\"></div>",
  )
}

/// Test flex container with all alignment options
pub fn flex_align_variations_test() {
  // AlignBetween
  layout.flex(ui_types.Row, ui_types.AlignBetween, ui_types.JustifyStart, 0, [])
  |> element.to_string
  |> string.contains("items-between")
  |> should.be_true()

  // AlignAround
  layout.flex(ui_types.Row, ui_types.AlignAround, ui_types.JustifyStart, 0, [])
  |> element.to_string
  |> string.contains("items-around")
  |> should.be_true()
}

/// Test flex container with all justify options
pub fn flex_justify_variations_test() {
  // JustifyAround
  layout.flex(ui_types.Row, ui_types.AlignStart, ui_types.JustifyAround, 0, [])
  |> element.to_string
  |> string.contains("justify-around")
  |> should.be_true()

  // Even (evenly)
  layout.flex(ui_types.Row, ui_types.AlignStart, ui_types.Even, 0, [])
  |> element.to_string
  |> string.contains("justify-evenly")
  |> should.be_true()
}

/// Test flex container with various gap sizes
pub fn flex_gap_variations_test() {
  // Gap 0
  layout.flex(ui_types.Row, ui_types.AlignStart, ui_types.JustifyStart, 0, [])
  |> element.to_string
  |> string.contains("gap-0")
  |> should.be_true()

  // Gap 16
  layout.flex(ui_types.Row, ui_types.AlignStart, ui_types.JustifyStart, 16, [])
  |> element.to_string
  |> string.contains("gap-16")
  |> should.be_true()
}

/// Test flex container with empty children
pub fn flex_empty_children_test() {
  let result =
    layout.flex(
      ui_types.Row,
      ui_types.AlignCenter,
      ui_types.JustifyCenter,
      4,
      [],
    )
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"flex flex-row items-center justify-center gap-4\"></div>",
  )
}

/// Test flex container with multiple children
pub fn flex_multiple_children_test() {
  let result =
    layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyBetween, 4, [
      element.text("<button>Cancel</button>"),
      element.text("<button>Submit</button>"),
      element.text("<button>Delete</button>"),
    ])
    |> element.to_string

  result |> string.contains("<button>Cancel</button>") |> should.be_true()
  result |> string.contains("<button>Submit</button>") |> should.be_true()
  result |> string.contains("<button>Delete</button>") |> should.be_true()
}

// ===================================================================
// GRID COMPONENT TESTS
// ===================================================================

/// Test basic grid container with fixed columns
pub fn grid_fixed_columns_test() {
  let result =
    layout.grid(ui_types.Fixed(4), 4, [
      element.text("<div>Item 1</div>"),
      element.text("<div>Item 2</div>"),
    ])
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"grid grid-cols-4 gap-4\"><div>Item 1</div><div>Item 2</div></div>",
  )
}

/// Test grid container with auto columns
pub fn grid_auto_columns_test() {
  let result =
    layout.grid(ui_types.Auto, 2, [element.text("<span>A</span>")])
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"grid grid-cols-auto gap-2\"><span>A</span></div>",
  )
}

/// Test grid container with repeat columns
pub fn grid_repeat_columns_test() {
  let result = layout.grid(ui_types.Repeat(3), 6, []) |> element.to_string

  result
  |> should.equal("<div class=\"grid grid-cols-3 gap-6\"></div>")
}

/// Test grid container with responsive columns
pub fn grid_responsive_columns_test() {
  let result =
    layout.grid(ui_types.Responsive, 4, [
      element.text("<div>Card 1</div>"),
      element.text("<div>Card 2</div>"),
      element.text("<div>Card 3</div>"),
    ])
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"grid grid-cols-responsive gap-4\"><div>Card 1</div><div>Card 2</div><div>Card 3</div></div>",
  )
}

/// Test grid container with no gap
pub fn grid_no_gap_test() {
  let result =
    layout.grid(ui_types.Fixed(2), 0, [element.text("<div>A</div>")])
    |> element.to_string

  result |> string.contains("gap-0") |> should.be_true()
}

/// Test grid container with large gap
pub fn grid_large_gap_test() {
  let result = layout.grid(ui_types.Fixed(3), 12, []) |> element.to_string

  result |> string.contains("gap-12") |> should.be_true()
}

/// Test grid container with empty children
pub fn grid_empty_children_test() {
  let result = layout.grid(ui_types.Fixed(4), 4, []) |> element.to_string

  result
  |> should.equal("<div class=\"grid grid-cols-4 gap-4\"></div>")
}

/// Test grid container with many children
pub fn grid_many_children_test() {
  let children = [
    element.text("<div>1</div>"),
    element.text("<div>2</div>"),
    element.text("<div>3</div>"),
    element.text("<div>4</div>"),
    element.text("<div>5</div>"),
    element.text("<div>6</div>"),
  ]
  let result = layout.grid(ui_types.Fixed(3), 4, children) |> element.to_string

  result |> string.contains("<div>1</div>") |> should.be_true()
  result |> string.contains("<div>6</div>") |> should.be_true()
  result |> string.contains("grid-cols-3") |> should.be_true()
}

// ===================================================================
// SPACING COMPONENT TESTS
// ===================================================================

/// Test space_around with basic padding
pub fn space_around_basic_test() {
  let result =
    layout.space_around(16, [
      element.text("<div>Content</div>"),
      element.text("<p>More content</p>"),
    ])
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"space-around p-16\"><div>Content</div><p>More content</p></div>",
  )
}

/// Test space_around with zero padding
pub fn space_around_zero_padding_test() {
  let result =
    layout.space_around(0, [element.text("<span>Test</span>")])
    |> element.to_string

  result
  |> should.equal("<div class=\"space-around p-0\"><span>Test</span></div>")
}

/// Test space_around with large padding
pub fn space_around_large_padding_test() {
  let result = layout.space_around(32, []) |> element.to_string

  result |> string.contains("p-32") |> should.be_true()
}

/// Test space_around with empty children
pub fn space_around_empty_children_test() {
  let result = layout.space_around(8, []) |> element.to_string

  result |> should.equal("<div class=\"space-around p-8\"></div>")
}

/// Test space_around semantic HTML
pub fn space_around_semantic_html_test() {
  let result =
    layout.space_around(4, [element.text("<p>Text</p>")])
    |> element.to_string

  // Should use div element
  result |> string.starts_with("<div") |> should.be_true()
  result |> string.ends_with("</div>") |> should.be_true()
}

// ===================================================================
// CONTAINER COMPONENT TESTS
// ===================================================================

/// Test container with basic max-width
pub fn container_basic_test() {
  let result =
    layout.container(1200, [element.text("<main>Page content</main>")])
    |> element.to_string

  result
  |> should.equal(
    "<div class=\"container mx-auto\" style=\"max-width: 1200px\"><main>Page content</main></div>",
  )
}

/// Test container with small max-width
pub fn container_small_width_test() {
  let result =
    layout.container(600, [element.text("<div>Narrow content</div>")])
    |> element.to_string

  result |> string.contains("max-width: 600px") |> should.be_true()
  result |> string.contains("container mx-auto") |> should.be_true()
}

/// Test container with large max-width
pub fn container_large_width_test() {
  let result = layout.container(1920, []) |> element.to_string

  result |> string.contains("max-width: 1920px") |> should.be_true()
}

/// Test container with empty children
pub fn container_empty_children_test() {
  let result = layout.container(1200, []) |> element.to_string

  result
  |> should.equal(
    "<div class=\"container mx-auto\" style=\"max-width: 1200px\"></div>",
  )
}

/// Test container with multiple children
pub fn container_multiple_children_test() {
  let result =
    layout.container(1000, [
      element.text("<header>Header</header>"),
      element.text("<main>Main</main>"),
      element.text("<footer>Footer</footer>"),
    ])
    |> element.to_string

  result |> string.contains("<header>Header</header>") |> should.be_true()
  result |> string.contains("<main>Main</main>") |> should.be_true()
  result |> string.contains("<footer>Footer</footer>") |> should.be_true()
}

/// Test container semantic HTML
pub fn container_semantic_html_test() {
  let result =
    layout.container(1200, [element.text("<p>Test</p>")])
    |> element.to_string

  // Should use div element with appropriate classes
  result |> string.starts_with("<div") |> should.be_true()
  result |> string.contains("container") |> should.be_true()
  result |> string.contains("mx-auto") |> should.be_true()
}

// ===================================================================
// SECTION COMPONENT TESTS
// ===================================================================

/// Test section with basic content
pub fn section_basic_test() {
  let result =
    layout.section([
      element.text("<h2>Section Title</h2>"),
      element.text("<p>Content</p>"),
    ])
    |> element.to_string

  result
  |> should.equal(
    "<section class=\"section\"><h2>Section Title</h2><p>Content</p></section>",
  )
}

/// Test section with empty children
pub fn section_empty_children_test() {
  let result = layout.section([]) |> element.to_string

  result |> should.equal("<section class=\"section\"></section>")
}

/// Test section with single child
pub fn section_single_child_test() {
  let result =
    layout.section([element.text("<div>Single element</div>")])
    |> element.to_string

  result
  |> should.equal(
    "<section class=\"section\"><div>Single element</div></section>",
  )
}

/// Test section semantic HTML
pub fn section_semantic_html_test() {
  let result =
    layout.section([element.text("<p>Test</p>")]) |> element.to_string

  // Should use section element (semantic HTML)
  result |> string.starts_with("<section") |> should.be_true()
  result |> string.ends_with("</section>") |> should.be_true()
}

/// Test section with complex nested content
pub fn section_nested_content_test() {
  let result =
    layout.section([
      element.text("<article>"),
      element.text("<header><h1>Title</h1></header>"),
      element.text("<div><p>Paragraph</p></div>"),
      element.text("</article>"),
    ])
    |> element.to_string

  result |> string.contains("<article>") |> should.be_true()
  result |> string.contains("<header>") |> should.be_true()
  result |> string.contains("</article>") |> should.be_true()
}

// ===================================================================
// INTEGRATION TESTS - NESTED LAYOUTS
// ===================================================================

/// Test flex inside container
pub fn nested_flex_in_container_test() {
  let flex_content =
    layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyBetween, 4, [
      element.text("<button>Left</button>"),
      element.text("<button>Right</button>"),
    ])

  let result = layout.container(1200, [flex_content]) |> element.to_string

  result |> string.contains("container mx-auto") |> should.be_true()
  result |> string.contains("flex flex-row") |> should.be_true()
  result |> string.contains("<button>Left</button>") |> should.be_true()
}

/// Test grid inside section
pub fn nested_grid_in_section_test() {
  let grid_content =
    layout.grid(ui_types.Fixed(3), 4, [
      element.text("<div>Card 1</div>"),
      element.text("<div>Card 2</div>"),
      element.text("<div>Card 3</div>"),
    ])

  let result = layout.section([grid_content]) |> element.to_string

  result |> string.contains("<section") |> should.be_true()
  result |> string.contains("grid grid-cols-3") |> should.be_true()
}

/// Test space_around inside flex
pub fn nested_space_in_flex_test() {
  let spaced_content =
    layout.space_around(8, [element.text("<p>Padded content</p>")])

  let result =
    layout.flex(ui_types.Column, ui_types.AlignStart, ui_types.JustifyStart, 0, [
      spaced_content,
    ])
    |> element.to_string

  result |> string.contains("flex flex-col") |> should.be_true()
  result |> string.contains("space-around p-8") |> should.be_true()
}

/// Test complex nested layout structure
pub fn complex_nested_layout_test() {
  // Build from inside out: grid -> section -> container
  let grid =
    layout.grid(ui_types.Responsive, 4, [
      element.text("<div>Item</div>"),
      element.text("<div>Item</div>"),
    ])

  let section_with_grid = layout.section([grid])

  let final_layout =
    layout.container(1200, [section_with_grid]) |> element.to_string

  // Verify all layers are present
  final_layout |> string.contains("container mx-auto") |> should.be_true()
  final_layout |> string.contains("<section") |> should.be_true()
  final_layout
  |> string.contains("grid grid-cols-responsive")
  |> should.be_true()
}

// ===================================================================
// ACCESSIBILITY TESTS - SEMANTIC HTML
// ===================================================================

/// Test that section uses semantic HTML element
pub fn accessibility_section_semantic_test() {
  let result =
    layout.section([element.text("<p>Content</p>")]) |> element.to_string

  // Should use <section> tag for semantic HTML
  result |> string.contains("<section") |> should.be_true()
  result |> string.contains("</section>") |> should.be_true()
}

/// Test that container uses appropriate structure
pub fn accessibility_container_structure_test() {
  let result =
    layout.container(1200, [element.text("<main>Content</main>")])
    |> element.to_string

  // Container should allow semantic children
  result |> string.contains("<main>") |> should.be_true()
}

/// Test that layouts preserve semantic children
pub fn accessibility_preserve_semantic_children_test() {
  let result =
    layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyStart, 4, [
      element.text("<nav>Navigation</nav>"),
      element.text("<main>Main content</main>"),
      element.text("<aside>Sidebar</aside>"),
    ])
    |> element.to_string

  result |> string.contains("<nav>") |> should.be_true()
  result |> string.contains("<main>") |> should.be_true()
  result |> string.contains("<aside>") |> should.be_true()
}

// ===================================================================
// RESPONSIVE DESIGN TESTS
// ===================================================================

/// Test responsive grid class generation
pub fn responsive_grid_class_test() {
  let result = layout.grid(ui_types.Responsive, 4, []) |> element.to_string

  result |> string.contains("grid-cols-responsive") |> should.be_true()
}

/// Test that fixed columns generate correct classes
pub fn responsive_fixed_columns_range_test() {
  // Test various column counts
  layout.grid(ui_types.Fixed(1), 4, [])
  |> element.to_string
  |> string.contains("grid-cols-1")
  |> should.be_true()

  layout.grid(ui_types.Fixed(6), 4, [])
  |> element.to_string
  |> string.contains("grid-cols-6")
  |> should.be_true()

  layout.grid(ui_types.Fixed(12), 4, [])
  |> element.to_string
  |> string.contains("grid-cols-12")
  |> should.be_true()
}

/// Test that container supports different breakpoint widths
pub fn responsive_container_widths_test() {
  // Mobile-first width
  layout.container(640, [])
  |> element.to_string
  |> string.contains("max-width: 640px")
  |> should.be_true()

  // Tablet width
  layout.container(768, [])
  |> element.to_string
  |> string.contains("max-width: 768px")
  |> should.be_true()

  // Desktop width
  layout.container(1024, [])
  |> element.to_string
  |> string.contains("max-width: 1024px")
  |> should.be_true()

  // Large desktop width
  layout.container(1280, [])
  |> element.to_string
  |> string.contains("max-width: 1280px")
  |> should.be_true()
}

// ===================================================================
// CHILD COMPONENT PLACEMENT TESTS
// ===================================================================

/// Test that children maintain order in flex
pub fn child_placement_flex_order_test() {
  let result =
    layout.flex(ui_types.Row, ui_types.AlignStart, ui_types.JustifyStart, 0, [
      element.text("<div>First</div>"),
      element.text("<div>Second</div>"),
      element.text("<div>Third</div>"),
    ])
    |> element.to_string

  // Verify expected concatenated order
  result
  |> should.equal(
    "<div class=\"flex flex-row items-start justify-start gap-0\"><div>First</div><div>Second</div><div>Third</div></div>",
  )
}

/// Test that children maintain order in grid
pub fn child_placement_grid_order_test() {
  let result =
    layout.grid(ui_types.Fixed(2), 4, [
      element.text("<div>A</div>"),
      element.text("<div>B</div>"),
      element.text("<div>C</div>"),
    ])
    |> element.to_string

  // Verify expected concatenated order
  result
  |> should.equal(
    "<div class=\"grid grid-cols-2 gap-4\"><div>A</div><div>B</div><div>C</div></div>",
  )
}

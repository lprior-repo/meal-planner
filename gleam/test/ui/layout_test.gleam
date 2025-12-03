/// Layout Component Tests
///
/// This module defines tests that verify the layout components render correct HTML and CSS classes.
/// Tests cover flex layouts, grids, spacing, containers, and sections.

import gleeunit
import gleeunit/should
import gleam/string
import meal_planner/ui/components/layout
import meal_planner/ui/types/ui_types

pub fn main() {
  gleeunit.main()
}

// Custom assertion for string containment
fn assert_contains(haystack: String, needle: String) -> Nil {
  case string.contains(haystack, needle) {
    True -> Nil
    False -> {
      let _msg = string.concat([
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
// FLEX DIRECTION TESTS
// ===================================================================

pub fn flex_row_direction_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "flex-row")
}

pub fn flex_column_direction_test() {
  let result = layout.flex(ui_types.Column, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "flex-col")
}

pub fn flex_row_reverse_direction_test() {
  let result = layout.flex(ui_types.RowReverse, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "flex-row-reverse")
}

pub fn flex_column_reverse_direction_test() {
  let result = layout.flex(ui_types.ColumnReverse, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "flex-col-reverse")
}

// ===================================================================
// FLEX ALIGNMENT TESTS
// ===================================================================

pub fn flex_align_start_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignStart, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "items-start")
}

pub fn flex_align_center_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "items-center")
}

pub fn flex_align_end_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignEnd, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "items-end")
}

pub fn flex_align_stretch_test() {
  let result = layout.flex(ui_types.Row, ui_types.Stretch, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "items-stretch")
}

pub fn flex_align_between_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignBetween, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "items-between")
}

pub fn flex_align_around_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignAround, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "items-around")
}

// ===================================================================
// FLEX JUSTIFICATION TESTS
// ===================================================================

pub fn flex_justify_start_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyStart, 4, [])
  assert_contains(result, "justify-start")
}

pub fn flex_justify_center_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "justify-center")
}

pub fn flex_justify_end_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyEnd, 4, [])
  assert_contains(result, "justify-end")
}

pub fn flex_justify_between_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyBetween, 4, [])
  assert_contains(result, "justify-between")
}

pub fn flex_justify_around_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyAround, 4, [])
  assert_contains(result, "justify-around")
}

pub fn flex_justify_evenly_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.Even, 4, [])
  assert_contains(result, "justify-evenly")
}

// ===================================================================
// FLEX GAP TESTS
// ===================================================================

pub fn flex_gap_small_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 2, [])
  assert_contains(result, "gap-2")
}

pub fn flex_gap_medium_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "gap-4")
}

pub fn flex_gap_large_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 8, [])
  assert_contains(result, "gap-8")
}

// ===================================================================
// FLEX CONTAINER STRUCTURE TESTS
// ===================================================================

pub fn flex_is_div_element_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "<div")
}

pub fn flex_has_flex_class_test() {
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [])
  assert_contains(result, "class=\"flex")
}

pub fn flex_contains_children_test() {
  let children = ["<span>Item 1</span>", "<span>Item 2</span>"]
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 4, children)
  assert_contains(result, "Item 1")
  assert_contains(result, "Item 2")
}

pub fn flex_combines_all_classes_test() {
  let result = layout.flex(ui_types.Column, ui_types.AlignCenter, ui_types.JustifyBetween, 6, [])
  assert_contains(result, "flex")
  assert_contains(result, "flex-col")
  assert_contains(result, "items-center")
  assert_contains(result, "justify-between")
  assert_contains(result, "gap-6")
}

// ===================================================================
// GRID COLUMN TYPE TESTS
// ===================================================================

pub fn grid_auto_columns_test() {
  let result = layout.grid(ui_types.Auto, 4, [])
  assert_contains(result, "grid-cols-auto")
}

pub fn grid_fixed_columns_test() {
  let result = layout.grid(ui_types.Fixed(3), 4, [])
  assert_contains(result, "grid-cols-3")
}

pub fn grid_repeat_columns_test() {
  let result = layout.grid(ui_types.Repeat(4), 4, [])
  assert_contains(result, "grid-cols-4")
}

pub fn grid_responsive_columns_test() {
  let result = layout.grid(ui_types.Responsive, 4, [])
  assert_contains(result, "grid-cols-responsive")
}

// ===================================================================
// GRID GAP TESTS
// ===================================================================

pub fn grid_gap_small_test() {
  let result = layout.grid(ui_types.Fixed(2), 2, [])
  assert_contains(result, "gap-2")
}

pub fn grid_gap_medium_test() {
  let result = layout.grid(ui_types.Fixed(3), 4, [])
  assert_contains(result, "gap-4")
}

pub fn grid_gap_large_test() {
  let result = layout.grid(ui_types.Fixed(4), 6, [])
  assert_contains(result, "gap-6")
}

// ===================================================================
// GRID CONTAINER STRUCTURE TESTS
// ===================================================================

pub fn grid_is_div_element_test() {
  let result = layout.grid(ui_types.Fixed(3), 4, [])
  assert_contains(result, "<div")
}

pub fn grid_has_grid_class_test() {
  let result = layout.grid(ui_types.Fixed(3), 4, [])
  assert_contains(result, "class=\"grid")
}

pub fn grid_contains_children_test() {
  let children = ["<div>Item 1</div>", "<div>Item 2</div>", "<div>Item 3</div>"]
  let result = layout.grid(ui_types.Fixed(3), 4, children)
  assert_contains(result, "Item 1")
  assert_contains(result, "Item 2")
  assert_contains(result, "Item 3")
}

pub fn grid_combines_all_classes_test() {
  let result = layout.grid(ui_types.Fixed(4), 6, [])
  assert_contains(result, "grid")
  assert_contains(result, "grid-cols-4")
  assert_contains(result, "gap-6")
}

// ===================================================================
// SPACE AROUND TESTS
// ===================================================================

pub fn space_around_small_padding_test() {
  let result = layout.space_around(2, [])
  assert_contains(result, "p-2")
}

pub fn space_around_medium_padding_test() {
  let result = layout.space_around(4, [])
  assert_contains(result, "p-4")
}

pub fn space_around_large_padding_test() {
  let result = layout.space_around(8, [])
  assert_contains(result, "p-8")
}

pub fn space_around_is_div_element_test() {
  let result = layout.space_around(4, [])
  assert_contains(result, "<div")
}

pub fn space_around_has_space_class_test() {
  let result = layout.space_around(4, [])
  assert_contains(result, "space-around")
}

pub fn space_around_contains_children_test() {
  let children = ["<p>Content</p>"]
  let result = layout.space_around(4, children)
  assert_contains(result, "Content")
}

pub fn space_around_combines_classes_test() {
  let result = layout.space_around(6, [])
  assert_contains(result, "space-around")
  assert_contains(result, "p-6")
}

// ===================================================================
// CONTAINER TESTS
// ===================================================================

pub fn container_small_max_width_test() {
  let result = layout.container(600, [])
  assert_contains(result, "max-width: 600px")
}

pub fn container_medium_max_width_test() {
  let result = layout.container(1024, [])
  assert_contains(result, "max-width: 1024px")
}

pub fn container_large_max_width_test() {
  let result = layout.container(1200, [])
  assert_contains(result, "max-width: 1200px")
}

pub fn container_is_div_element_test() {
  let result = layout.container(1200, [])
  assert_contains(result, "<div")
}

pub fn container_has_container_class_test() {
  let result = layout.container(1200, [])
  assert_contains(result, "container")
}

pub fn container_has_mx_auto_test() {
  let result = layout.container(1200, [])
  assert_contains(result, "mx-auto")
}

pub fn container_has_style_attribute_test() {
  let result = layout.container(1200, [])
  assert_contains(result, "style=\"")
}

pub fn container_contains_children_test() {
  let children = ["<div>Main content</div>"]
  let result = layout.container(1200, children)
  assert_contains(result, "Main content")
}

pub fn container_combines_all_attributes_test() {
  let result = layout.container(960, [])
  assert_contains(result, "class=\"container mx-auto\"")
  assert_contains(result, "style=\"max-width: 960px\"")
}

// ===================================================================
// SECTION TESTS
// ===================================================================

pub fn section_is_section_element_test() {
  let result = layout.section([])
  assert_contains(result, "<section")
}

pub fn section_has_section_class_test() {
  let result = layout.section([])
  assert_contains(result, "class=\"section\"")
}

pub fn section_contains_children_test() {
  let children = ["<h1>Title</h1>", "<p>Description</p>"]
  let result = layout.section(children)
  assert_contains(result, "Title")
  assert_contains(result, "Description")
}

pub fn section_with_empty_children_test() {
  let result = layout.section([])
  assert_contains(result, "<section class=\"section\"></section>")
}

pub fn section_maintains_children_order_test() {
  let children = ["<p>First</p>", "<p>Second</p>", "<p>Third</p>"]
  let result = layout.section(children)
  let first_pos = string.find_first(result, "First")
  let second_pos = string.find_first(result, "Second")
  let third_pos = string.find_first(result, "Third")
  case first_pos, second_pos, third_pos {
    Ok(f), Ok(s), Ok(t) if f < s && s < t -> Nil
    _, _, _ -> should.fail()
  }
}

// ===================================================================
// INTEGRATION TESTS
// ===================================================================

pub fn flex_with_multiple_children_test() {
  let children = [
    "<div>Child 1</div>",
    "<div>Child 2</div>",
    "<div>Child 3</div>",
  ]
  let result = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyBetween, 4, children)
  assert_contains(result, "Child 1")
  assert_contains(result, "Child 2")
  assert_contains(result, "Child 3")
}

pub fn grid_in_section_test() {
  let grid_content = layout.grid(ui_types.Fixed(3), 4, [
    "<div>Item 1</div>",
    "<div>Item 2</div>",
  ])
  let result = layout.section([grid_content])
  assert_contains(result, "<section")
  assert_contains(result, "grid")
  assert_contains(result, "Item 1")
}

pub fn flex_in_container_test() {
  let flex_content = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 4, [
    "<button>Click</button>",
  ])
  let result = layout.container(1200, [flex_content])
  assert_contains(result, "container")
  assert_contains(result, "flex")
  assert_contains(result, "Click")
}

pub fn nested_layouts_test() {
  let inner_flex = layout.flex(ui_types.Row, ui_types.AlignCenter, ui_types.JustifyCenter, 2, [
    "<span>Item</span>",
  ])
  let grid_with_flex = layout.grid(ui_types.Fixed(2), 4, [inner_flex, inner_flex])
  let result = layout.container(1200, [grid_with_flex])
  assert_contains(result, "container")
  assert_contains(result, "grid")
  assert_contains(result, "flex")
  assert_contains(result, "Item")
}

pub fn section_with_padded_content_test() {
  let spaced_content = layout.space_around(6, ["<p>Padded content</p>"])
  let result = layout.section([spaced_content])
  assert_contains(result, "<section")
  assert_contains(result, "space-around")
  assert_contains(result, "p-6")
  assert_contains(result, "Padded content")
}

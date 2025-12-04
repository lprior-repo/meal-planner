/// Layout Components Module
///
/// This module provides layout utility components:
/// - Flex containers with direction, alignment, justification
/// - Grid containers with responsive columns
/// - Spacing containers
/// - Max-width containers
/// - Page sections with padding
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Layout)
import gleam/int
import gleam/list
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/ui/types/ui_types

// ===================================================================
// HELPER FUNCTIONS - FLEX
// ===================================================================

/// Convert FlexDirection to CSS class string
fn direction_to_class(direction: ui_types.FlexDirection) -> String {
  case direction {
    ui_types.Row -> "flex-row"
    ui_types.Column -> "flex-col"
    ui_types.RowReverse -> "flex-row-reverse"
    ui_types.ColumnReverse -> "flex-col-reverse"
  }
}

/// Convert FlexAlign to CSS class string
fn align_to_class(align: ui_types.FlexAlign) -> String {
  case align {
    ui_types.AlignStart -> "items-start"
    ui_types.AlignCenter -> "items-center"
    ui_types.AlignEnd -> "items-end"
    ui_types.Stretch -> "items-stretch"
    ui_types.AlignBetween -> "items-between"
    ui_types.AlignAround -> "items-around"
  }
}

/// Convert FlexJustify to CSS class string
fn justify_to_class(justify: ui_types.FlexJustify) -> String {
  case justify {
    ui_types.JustifyStart -> "justify-start"
    ui_types.JustifyCenter -> "justify-center"
    ui_types.JustifyEnd -> "justify-end"
    ui_types.JustifyBetween -> "justify-between"
    ui_types.JustifyAround -> "justify-around"
    ui_types.Even -> "justify-evenly"
  }
}

/// Convert gap integer to CSS class string
fn gap_to_class(gap: Int) -> String {
  "gap-" <> int.to_string(gap)
}

// ===================================================================
// HELPER FUNCTIONS - GRID
// ===================================================================

/// Convert GridColumns to CSS class string
fn columns_to_class(columns: ui_types.GridColumns) -> String {
  case columns {
    ui_types.Auto -> "grid-cols-auto"
    ui_types.Fixed(n) -> "grid-cols-" <> int.to_string(n)
    ui_types.Repeat(n) -> "grid-cols-" <> int.to_string(n)
    ui_types.Responsive -> "grid-cols-responsive"
  }
}

// ===================================================================
// HELPER FUNCTION - PADDING
// ===================================================================

/// Convert padding amount to CSS class string
fn padding_to_class(padding: Int) -> String {
  "p-" <> int.to_string(padding)
}

// ===================================================================
// FLEX COMPONENT
// ===================================================================

/// Flex container
///
/// Renders: <div class="flex flex-row items-center justify-between gap-4">children</div>
pub fn flex(
  direction: ui_types.FlexDirection,
  align: ui_types.FlexAlign,
  justify: ui_types.FlexJustify,
  gap: Int,
  children: List(element.Element(msg)),
) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for flex container
  let direction_class = direction_to_class(direction)
  let align_class = align_to_class(align)
  let justify_class = justify_to_class(justify)
  let gap_class = gap_to_class(gap)

  let classes =
    "flex "
    <> direction_class
    <> " "
    <> align_class
    <> " "
    <> justify_class
    <> " "
    <> gap_class

  html.div([attribute.class(classes)], children)
}

// ===================================================================
// GRID COMPONENT
// ===================================================================

/// Grid container
///
/// Renders: <div class="grid grid-cols-4 gap-4">children</div>
pub fn grid(
  columns: ui_types.GridColumns,
  gap: Int,
  children: List(element.Element(msg)),
) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for grid container
  let columns_class = columns_to_class(columns)
  let gap_class = gap_to_class(gap)

  let classes = "grid " <> columns_class <> " " <> gap_class

  html.div([attribute.class(classes)], children)
}

// ===================================================================
// SPACING COMPONENTS
// ===================================================================

/// Spacing container (padding around children)
///
/// Renders: <div class="space-around p-16">children</div>
pub fn space_around(
  amount: Int,
  children: List(element.Element(msg)),
) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for spaced container
  let padding_class = padding_to_class(amount)
  let classes = "space-around " <> padding_class

  html.div([attribute.class(classes)], children)
}

/// Container with max-width
///
/// Renders: <div class="container mx-auto" style="max-width: 1200px">children</div>
pub fn container(
  max_width: Int,
  children: List(element.Element(msg)),
) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for max-width container
  let max_width_px = int.to_string(max_width) <> "px"

  html.div(
    [
      attribute.class("container mx-auto"),
      attribute("style", "max-width: " <> max_width_px),
    ],
    children,
  )
}

/// Page section with padding
///
/// Renders: <section class="section">children</section>
pub fn section(children: List(element.Element(msg))) -> element.Element(msg) {
  // CONTRACT: Returns Lustre element for page section
  html.section([attribute.class("section")], children)
}

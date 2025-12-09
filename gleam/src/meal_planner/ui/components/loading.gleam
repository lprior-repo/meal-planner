/// Loading State Components Module
///
/// This module provides loading state components for async operations:
/// - Spinners (inline and full-page)
/// - Skeleton loaders (for content placeholders)
/// - Loading overlays
/// - Progress indicators
///
/// All components render as Lustre HTML elements suitable for SSR.
///
/// See: docs/component_signatures.md (section: Loading States)
import lustre/attribute
import lustre/element
import lustre/element/html

// ===================================================================
// PUBLIC COMPONENT FUNCTIONS
// ===================================================================

/// Inline spinner - small loading indicator for buttons/inline content
///
/// Usage:
/// ```gleam
/// html.button([attribute.class("btn"), attribute.disabled(True)], [
///   spinner_inline(),
///   element.text(" Loading...")
/// ])
/// ```
pub fn spinner_inline() -> element.Element(msg) {
  html.span([attribute.class("spinner spinner-inline")], [
    html.span([attribute.class("spinner-dot")], []),
    html.span([attribute.class("spinner-dot")], []),
    html.span([attribute.class("spinner-dot")], []),
  ])
}

/// Standard spinner - medium-sized loading indicator
///
/// Usage:
/// ```gleam
/// html.div([attribute.class("loading-container")], [
///   spinner(),
///   html.p([], [element.text("Loading recipes...")])
/// ])
/// ```
pub fn spinner() -> element.Element(msg) {
  html.div([attribute.class("spinner spinner-standard")], [])
}

/// Large spinner - for full-page or major section loading
///
/// Usage:
/// ```gleam
/// html.div([attribute.class("page-loading")], [
///   spinner_large(),
///   html.p([], [element.text("Loading data...")])
/// ])
/// ```
pub fn spinner_large() -> element.Element(msg) {
  html.div([attribute.class("spinner spinner-large")], [])
}

/// Loading overlay - covers content while loading
///
/// Usage:
/// ```gleam
/// html.div([attribute.class("relative")], [
///   // Your content
///   loading_overlay("Saving recipe...")
/// ])
/// ```
pub fn loading_overlay(message: String) -> element.Element(msg) {
  html.div([attribute.class("loading-overlay")], [
    html.div([attribute.class("loading-overlay-content")], [
      spinner(),
      html.p([attribute.class("loading-message")], [element.text(message)]),
    ]),
  ])
}

/// Full page loading screen
///
/// Usage:
/// ```gleam
/// loading_page("Loading dashboard...")
/// ```
pub fn loading_page(message: String) -> element.Element(msg) {
  html.div([attribute.class("loading-page")], [
    html.div([attribute.class("loading-page-content")], [
      spinner_large(),
      html.h2([attribute.class("loading-title")], [element.text(message)]),
      html.p([attribute.class("loading-subtitle")], [
        element.text("Please wait..."),
      ]),
    ]),
  ])
}

// ===================================================================
// SKELETON LOADERS
// ===================================================================

/// Skeleton text line - placeholder for loading text
///
/// Usage:
/// ```gleam
/// skeleton_text(SkeletonWidth.Full)
/// ```
pub fn skeleton_text(width: SkeletonWidth) -> element.Element(msg) {
  let width_class = case width {
    Full -> "skeleton-text-full"
    ThreeQuarters -> "skeleton-text-3/4"
    Half -> "skeleton-text-1/2"
    Quarter -> "skeleton-text-1/4"
  }

  html.div([attribute.class("skeleton-text " <> width_class)], [])
}

/// Skeleton card - placeholder for recipe/food cards
///
/// Usage:
/// ```gleam
/// html.div([attribute.class("recipe-grid")], [
///   skeleton_card(),
///   skeleton_card(),
///   skeleton_card(),
/// ])
/// ```
pub fn skeleton_card() -> element.Element(msg) {
  html.div([attribute.class("skeleton-card")], [
    html.div([attribute.class("skeleton-image")], []),
    html.div([attribute.class("skeleton-content")], [
      skeleton_text(Full),
      skeleton_text(Half),
      html.div([attribute.class("skeleton-badges")], [
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
        html.div([attribute.class("skeleton-badge")], []),
      ]),
    ]),
  ])
}

/// Skeleton list item - placeholder for food search results
///
/// Usage:
/// ```gleam
/// html.div([attribute.class("food-list")], [
///   skeleton_list_item(),
///   skeleton_list_item(),
///   skeleton_list_item(),
/// ])
/// ```
pub fn skeleton_list_item() -> element.Element(msg) {
  html.div([attribute.class("skeleton-list-item")], [
    skeleton_text(ThreeQuarters),
    skeleton_text(Quarter),
  ])
}

/// Skeleton table row - placeholder for nutrient tables
///
/// Usage:
/// ```gleam
/// html.tbody([], [
///   skeleton_table_row(2),
///   skeleton_table_row(2),
/// ])
/// ```
pub fn skeleton_table_row(columns: Int) -> element.Element(msg) {
  html.tr([attribute.class("skeleton-table-row")], [
    html.td([attribute.attribute("colspan", int_to_string(columns))], [
      skeleton_text(Full),
    ]),
  ])
}

/// Skeleton progress bar - placeholder for macro bars
///
/// Usage:
/// ```gleam
/// html.div([attribute.class("macro-bars")], [
///   skeleton_progress_bar(),
///   skeleton_progress_bar(),
///   skeleton_progress_bar(),
/// ])
/// ```
pub fn skeleton_progress_bar() -> element.Element(msg) {
  html.div([attribute.class("skeleton-progress-bar")], [
    skeleton_text(Quarter),
    html.div([attribute.class("skeleton-bar")], []),
  ])
}

// ===================================================================
// LOADING WITH CONTENT (Progressive Enhancement)
// ===================================================================

/// Show loading state or content based on loading flag
///
/// Usage:
/// ```gleam
/// loading_or_content(
///   is_loading: True,
///   loading: spinner(),
///   content: recipe_list(recipes)
/// )
/// ```
pub fn loading_or_content(
  is_loading is_loading: Bool,
  loading skeleton: element.Element(msg),
  content content: element.Element(msg),
) -> element.Element(msg) {
  case is_loading {
    True -> skeleton
    False -> content
  }
}

/// Wrapper that dims content while loading
///
/// Usage:
/// ```gleam
/// loading_wrapper(
///   is_loading: True,
///   content: recipe_form()
/// )
/// ```
pub fn loading_wrapper(
  is_loading is_loading: Bool,
  content content: element.Element(msg),
) -> element.Element(msg) {
  case is_loading {
    True ->
      html.div([attribute.class("relative")], [
        html.div([attribute.class("is-loading")], [content]),
        loading_overlay("Processing..."),
      ])
    False -> content
  }
}

// ===================================================================
// TYPES
// ===================================================================

/// Skeleton text width options
pub type SkeletonWidth {
  Full
  ThreeQuarters
  Half
  Quarter
}

// ===================================================================
// HELPERS
// ===================================================================

@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(i: Int) -> String

/// Lazy Loading Components Module
///
/// This module provides components for progressive loading of heavy content:
/// - Skeleton loaders for deferred components
/// - Intersection Observer wrappers for lazy rendering
/// - Progressive enhancement patterns
/// - Loading state management
///
/// Performance optimizations:
/// - Defer non-critical components below the fold
/// - Load heavy visualization components on-demand
/// - Virtual scrolling for long lists
/// - Progressive image loading
///
/// See: meal-planner-e0v (Performance optimization)
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute.{attribute, class, id}
import lustre/element.{type Element, text}
import lustre/element/html.{div, img, link, span}
import meal_planner/nutrition_constants

// Helper function to create inline style attribute from CSS property list
fn inline_style(properties: List(#(String, String))) -> attribute.Attribute(msg) {
  let css_string =
    properties
    |> list.map(fn(prop) {
      let #(key, value) = prop
      key <> ": " <> value
    })
    |> string.join("; ")

  attribute("style", css_string)
}

// ===================================================================
// SKELETON LOADER COMPONENTS
// ===================================================================

/// Skeleton loader for macro progress bars
/// Shows animated placeholder while actual data loads
pub fn macro_bar_skeleton() -> Element(msg) {
  div([class("macro-bar skeleton")], [
    div(
      [
        class("macro-bar-header skeleton-text"),
        inline_style([
          #("width", "120px"),
          #("height", "16px"),
        ]),
      ],
      [],
    ),
    div([class("progress-bar skeleton-bar")], [
      div([class("skeleton-shimmer")], []),
    ]),
  ])
}

/// Skeleton loader for calorie summary card
pub fn calorie_card_skeleton() -> Element(msg) {
  div([class("calorie-summary skeleton")], [
    div(
      [
        class("skeleton-text"),
        inline_style([
          #(
            "width",
            int.to_string(nutrition_constants.skeleton_label_width) <> "px",
          ),
          #("height", "24px"),
          #("margin-bottom", "8px"),
        ]),
      ],
      [],
    ),
    div(
      [
        class("skeleton-text"),
        inline_style([
          #(
            "width",
            int.to_string(nutrition_constants.skeleton_calorie_width) <> "px",
          ),
          #("height", "48px"),
        ]),
      ],
      [],
    ),
  ])
}

/// Skeleton loader for meal entry item
pub fn meal_entry_skeleton() -> Element(msg) {
  div([class("meal-entry-item skeleton")], [
    div(
      [class("skeleton-text"), inline_style([#("width", "60px"), #("height", "16px")])],
      [],
    ),
    div(
      [
        class("skeleton-text"),
        inline_style([#("width", "180px"), #("height", "20px")]),
      ],
      [],
    ),
    div(
      [
        class("skeleton-text"),
        inline_style([#("width", "140px"), #("height", "16px")]),
      ],
      [],
    ),
    div(
      [class("skeleton-text"), inline_style([#("width", "80px"), #("height", "16px")])],
      [],
    ),
  ])
}

/// Skeleton loader for micronutrient panel
pub fn micronutrient_panel_skeleton() -> Element(msg) {
  div([class("micronutrient-panel skeleton")], [
    div(
      [
        class("skeleton-text"),
        inline_style([
          #("width", "120px"),
          #("height", "20px"),
          #("margin-bottom", "16px"),
        ]),
      ],
      [],
    ),
    ..list.map([1, 2, 3, 4, 5], fn(_) {
      div(
        [
          class("micronutrient-bar skeleton"),
          inline_style([#("margin-bottom", "12px")]),
        ],
        [
          div(
            [
              class("skeleton-text"),
              inline_style([#("width", "100px"), #("height", "14px")]),
            ],
            [],
          ),
          div(
            [
              class("skeleton-bar"),
              inline_style([#("height", "8px"), #("margin", "8px 0")]),
            ],
            [],
          ),
          div(
            [
              class("skeleton-text"),
              inline_style([#("width", "60px"), #("height", "12px")]),
            ],
            [],
          ),
        ],
      )
    })
  ])
}

/// Skeleton loader for recipe card
pub fn recipe_card_skeleton() -> Element(msg) {
  div([class("recipe-card skeleton")], [
    div(
      [
        class("skeleton-image"),
        inline_style([#("width", "100%"), #("height", "160px")]),
      ],
      [],
    ),
    div([class("recipe-card-content")], [
      div(
        [
          class("skeleton-text"),
          inline_style([
            #("width", "180px"),
            #("height", "20px"),
            #("margin-bottom", "8px"),
          ]),
        ],
        [],
      ),
      div(
        [
          class("skeleton-text"),
          inline_style([
            #("width", "80px"),
            #("height", "14px"),
            #("margin-bottom", "12px"),
          ]),
        ],
        [],
      ),
      div(
        [
          class("skeleton-text"),
          inline_style([#("width", "140px"), #("height", "14px")]),
        ],
        [],
      ),
    ]),
  ])
}

/// Skeleton loader for food search results
pub fn search_results_skeleton(count: Int) -> Element(msg) {
  div(
    [class("search-results skeleton")],
    list.map(list.range(1, count), fn(_) {
      div([class("food-item skeleton"), inline_style([#("margin-bottom", "8px")])], [
        div(
          [
            class("skeleton-text"),
            inline_style([
              #(
                "width",
                int.to_string(
                  nutrition_constants.skeleton_main_text_width_percent,
                )
                  <> "%",
              ),
              #("height", "18px"),
              #("margin-bottom", "4px"),
            ]),
          ],
          [],
        ),
        div(
          [
            class("skeleton-text"),
            inline_style([
              #(
                "width",
                int.to_string(
                  nutrition_constants.skeleton_secondary_text_width_percent,
                )
                  <> "%",
              ),
              #("height", "14px"),
            ]),
          ],
          [],
        ),
      ])
    }),
  )
}

// ===================================================================
// LAZY LOADING WRAPPER COMPONENTS
// ===================================================================

/// Lazy load wrapper with Intersection Observer
///
/// Wraps content that should only be loaded when scrolled into view
/// Uses the `data-lazy-load` attribute to trigger loading
///
/// Parameters:
/// - id_str: Unique identifier for this lazy-loaded section
/// - placeholder: Skeleton loader element to show while loading
/// - content_src: API endpoint or data attribute with content
pub fn lazy_section(
  id_str: String,
  placeholder: Element(msg),
  content_src: String,
) -> Element(msg) {
  div(
    [
      class("lazy-section"),
      id("lazy-" <> id_str),
      attribute("data-lazy-load", "true"),
      attribute("data-content-src", content_src),
      attribute("data-loaded", "false"),
    ],
    [
      div([class("lazy-placeholder"), attribute("data-placeholder", "true")], [
        placeholder,
      ]),
      div([class("lazy-content"), inline_style([#("display", "none")])], []),
    ],
  )
}

/// Defer rendering of heavy component
///
/// Component will be rendered client-side after page load
/// Useful for charts, visualizations, or other expensive components
pub fn deferred_component(
  id_str: String,
  component_type: String,
  data_json: String,
) -> Element(msg) {
  div(
    [
      class("deferred-component"),
      id("deferred-" <> id_str),
      attribute("data-component-type", component_type),
      attribute("data-component-data", encode_json(data_json)),
      attribute("data-rendered", "false"),
    ],
    [get_skeleton_for_component(component_type)],
  )
}

/// Get appropriate skeleton for component type
fn get_skeleton_for_component(component_type: String) -> Element(msg) {
  case component_type {
    "micronutrient-panel" -> micronutrient_panel_skeleton()
    "macro-bars" ->
      div([], [macro_bar_skeleton(), macro_bar_skeleton(), macro_bar_skeleton()])
    "calorie-card" -> calorie_card_skeleton()
    "meal-entries" ->
      div([], [
        meal_entry_skeleton(),
        meal_entry_skeleton(),
        meal_entry_skeleton(),
      ])
    "recipe-grid" ->
      div([], [
        recipe_card_skeleton(),
        recipe_card_skeleton(),
        recipe_card_skeleton(),
      ])
    _ ->
      div(
        [
          class("skeleton-text"),
          inline_style([
            #("width", "100%"),
            #(
              "height",
              int.to_string(nutrition_constants.skeleton_large_height) <> "px",
            ),
          ]),
        ],
        [],
      )
  }
}

// ===================================================================
// VIRTUAL SCROLLING COMPONENTS
// ===================================================================

/// Virtual scroll container for long lists
///
/// Only renders visible items + buffer zone
/// Significantly reduces DOM nodes for lists with 100+ items
///
/// Parameters:
/// - id_str: Container ID
/// - item_height: Fixed height per item (in pixels)
/// - total_items: Total number of items
/// - visible_count: Number of items to keep in DOM
pub fn virtual_scroll_container(
  id_str: String,
  item_height: Int,
  total_items: Int,
  visible_count: Int,
) -> Element(msg) {
  let total_height = item_height * total_items

  div(
    [
      class("virtual-scroll-container"),
      id(id_str),
      attribute("data-virtual-scroll", "true"),
      attribute("data-item-height", int.to_string(item_height)),
      attribute("data-total-items", int.to_string(total_items)),
      attribute("data-visible-count", int.to_string(visible_count)),
      inline_style([
        #("height", "600px"),
        #("overflow-y", "auto"),
        #("position", "relative"),
      ]),
    ],
    [
      div(
        [
          class("virtual-scroll-spacer"),
          inline_style([
            #("height", int.to_string(total_height) <> "px"),
          ]),
        ],
        [],
      ),
      div(
        [
          class("virtual-scroll-content"),
          inline_style([
            #("position", "absolute"),
            #("top", "0"),
            #("width", "100%"),
          ]),
        ],
        [],
      ),
    ],
  )
}

// ===================================================================
// PROGRESSIVE IMAGE LOADING
// ===================================================================

/// Lazy-loaded image with blur-up placeholder
///
/// Shows low-quality placeholder while high-res image loads
pub fn lazy_image(
  src: String,
  alt: String,
  placeholder: Option(String),
) -> Element(msg) {
  let placeholder_src = case placeholder {
    Some(p) -> p
    None -> {
      // Generic placeholder SVG (400x300 gray rectangle)
      "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 400 300'%3E%3Crect fill='%23f0f0f0' width='400' height='300'/%3E%3C/svg%3E"
    }
  }

  div([class("lazy-image-wrapper")], [
    img([
      class("lazy-image-placeholder"),
      attribute("src", placeholder_src),
      attribute("alt", alt <> " (loading)"),
      attribute("aria-hidden", "true"),
      inline_style([#("filter", "blur(10px)"), #("transition", "opacity 0.3s")]),
    ]),
    img([
      class("lazy-image"),
      attribute("data-src", src),
      attribute("alt", alt),
      attribute("loading", "lazy"),
      inline_style([
        #("opacity", "0"),
        #("position", "absolute"),
        #("top", "0"),
        #("left", "0"),
        #("width", "100%"),
        #("height", "100%"),
      ]),
    ]),
  ])
}

// ===================================================================
// LOADING STATE INDICATORS
// ===================================================================

/// Animated spinner for loading states
pub fn loading_spinner(size: String) -> Element(msg) {
  div(
    [
      class("loading-spinner loading-spinner-" <> size),
      attribute("role", "status"),
      attribute("aria-label", "Loading"),
    ],
    [
      div([class("spinner-circle")], []),
      span([class("visually-hidden")], [text("Loading...")]),
    ],
  )
}

/// Inline loading indicator for buttons
pub fn button_loading_state() -> Element(msg) {
  span([class("button-loader")], [
    span([class("loader-dot")], []),
    span([class("loader-dot")], []),
    span([class("loader-dot")], []),
  ])
}

/// Progress bar for multi-step loading
pub fn loading_progress_bar(percentage: Float, label: String) -> Element(msg) {
  let pct_str = percentage |> float_to_int |> int.to_string

  div(
    [
      class("loading-progress"),
      attribute("role", "progressbar"),
      attribute("aria-valuenow", pct_str),
      attribute("aria-valuemin", "0"),
      attribute("aria-valuemax", "100"),
      attribute("aria-label", label),
    ],
    [
      div([class("progress-label")], [text(label <> " (" <> pct_str <> "%)")]),
      div([class("progress-track")], [
        div([class("progress-fill"), inline_style([#("width", pct_str <> "%")])], []),
      ]),
    ],
  )
}

// ===================================================================
// UTILITY FUNCTIONS
// ===================================================================

/// Convert float to int for display
fn float_to_int(f: Float) -> Int {
  case f {
    f if f >=. 0.0 -> {
      let rounded = f +. 0.5
      truncate_float(rounded)
    }
    f -> {
      let rounded = f -. 0.5
      truncate_float(rounded)
    }
  }
}

@external(erlang, "erlang", "trunc")
fn truncate_float(f: Float) -> Int

/// Encode JSON string for HTML attribute
fn encode_json(json: String) -> String {
  json
  |> string.replace("\"", "&quot;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
}

// ===================================================================
// PERFORMANCE HINTS
// ===================================================================

/// Add resource hints for preloading critical assets
pub fn resource_hints(critical_images: List(String)) -> Element(msg) {
  let preload_links =
    list.map(critical_images, fn(url) {
      link([
        attribute("rel", "preload"),
        attribute("href", url),
        attribute("as", "image"),
      ])
    })

  element.fragment([
    element.fragment(preload_links),
    link([
      attribute("rel", "dns-prefetch"),
      attribute("href", "https://api.nal.usda.gov"),
    ]),
    link([
      attribute("rel", "preconnect"),
      attribute("href", "https://api.nal.usda.gov"),
      attribute("crossorigin", ""),
    ]),
  ])
}

/// Content visibility hint for off-screen content
pub fn content_visibility_hint(
  id_str: String,
  estimated_height: Int,
) -> attribute.Attribute(msg) {
  inline_style([
    #("content-visibility", "auto"),
    #("contain-intrinsic-size", int.to_string(estimated_height) <> "px"),
  ])
}

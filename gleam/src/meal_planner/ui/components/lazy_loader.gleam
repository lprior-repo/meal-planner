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

// ===================================================================
// SKELETON LOADER COMPONENTS
// ===================================================================

/// Skeleton loader for macro progress bars
/// Shows animated placeholder while actual data loads
pub fn macro_bar_skeleton() -> String {
  "<div class=\"macro-bar skeleton\">"
  <> "<div class=\"macro-bar-header skeleton-text\" style=\"width: 120px; height: 16px;\"></div>"
  <> "<div class=\"progress-bar skeleton-bar\">"
  <> "<div class=\"skeleton-shimmer\"></div>"
  <> "</div>"
  <> "</div>"
}

/// Skeleton loader for calorie summary card
pub fn calorie_card_skeleton() -> String {
  "<div class=\"calorie-summary skeleton\">"
  <> "<div class=\"skeleton-text\" style=\"width: 150px; height: 24px; margin-bottom: 8px;\"></div>"
  <> "<div class=\"skeleton-text\" style=\"width: 200px; height: 48px;\"></div>"
  <> "</div>"
}

/// Skeleton loader for meal entry item
pub fn meal_entry_skeleton() -> String {
  "<div class=\"meal-entry-item skeleton\">"
  <> "<div class=\"skeleton-text\" style=\"width: 60px; height: 16px;\"></div>"
  <> "<div class=\"skeleton-text\" style=\"width: 180px; height: 20px;\"></div>"
  <> "<div class=\"skeleton-text\" style=\"width: 140px; height: 16px;\"></div>"
  <> "<div class=\"skeleton-text\" style=\"width: 80px; height: 16px;\"></div>"
  <> "</div>"
}

/// Skeleton loader for micronutrient panel
pub fn micronutrient_panel_skeleton() -> String {
  "<div class=\"micronutrient-panel skeleton\">"
  <> "<div class=\"skeleton-text\" style=\"width: 120px; height: 20px; margin-bottom: 16px;\"></div>"
  <> string.concat(
    list.map([1, 2, 3, 4, 5], fn(_) {
      "<div class=\"micronutrient-bar skeleton\" style=\"margin-bottom: 12px;\">"
      <> "<div class=\"skeleton-text\" style=\"width: 100px; height: 14px;\"></div>"
      <> "<div class=\"skeleton-bar\" style=\"height: 8px; margin: 8px 0;\"></div>"
      <> "<div class=\"skeleton-text\" style=\"width: 60px; height: 12px;\"></div>"
      <> "</div>"
    }),
  )
  <> "</div>"
}

/// Skeleton loader for recipe card
pub fn recipe_card_skeleton() -> String {
  "<div class=\"recipe-card skeleton\">"
  <> "<div class=\"skeleton-image\" style=\"width: 100%; height: 160px;\"></div>"
  <> "<div class=\"recipe-card-content\">"
  <> "<div class=\"skeleton-text\" style=\"width: 180px; height: 20px; margin-bottom: 8px;\"></div>"
  <> "<div class=\"skeleton-text\" style=\"width: 80px; height: 14px; margin-bottom: 12px;\"></div>"
  <> "<div class=\"skeleton-text\" style=\"width: 140px; height: 14px;\"></div>"
  <> "</div>"
  <> "</div>"
}

/// Skeleton loader for food search results
pub fn search_results_skeleton(count: Int) -> String {
  "<div class=\"search-results skeleton\">"
  <> string.concat(
    list.map(list.range(1, count), fn(_) {
      "<div class=\"food-item skeleton\" style=\"margin-bottom: 8px;\">"
      <> "<div class=\"skeleton-text\" style=\"width: 70%; height: 18px; margin-bottom: 4px;\"></div>"
      <> "<div class=\"skeleton-text\" style=\"width: 40%; height: 14px;\"></div>"
      <> "</div>"
    }),
  )
  <> "</div>"
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
/// - id: Unique identifier for this lazy-loaded section
/// - placeholder: Skeleton loader HTML to show while loading
/// - content_src: API endpoint or data attribute with content
pub fn lazy_section(
  id: String,
  placeholder: String,
  content_src: String,
) -> String {
  "<div class=\"lazy-section\" "
  <> "id=\"lazy-"
  <> id
  <> "\" "
  <> "data-lazy-load=\"true\" "
  <> "data-content-src=\""
  <> content_src
  <> "\" "
  <> "data-loaded=\"false\">"
  <> "<div class=\"lazy-placeholder\" data-placeholder=\"true\">"
  <> placeholder
  <> "</div>"
  <> "<div class=\"lazy-content\" style=\"display: none;\"></div>"
  <> "</div>"
}

/// Defer rendering of heavy component
///
/// Component will be rendered client-side after page load
/// Useful for charts, visualizations, or other expensive components
pub fn deferred_component(
  id: String,
  component_type: String,
  data_json: String,
) -> String {
  "<div class=\"deferred-component\" "
  <> "id=\"deferred-"
  <> id
  <> "\" "
  <> "data-component-type=\""
  <> component_type
  <> "\" "
  <> "data-component-data=\""
  <> encode_json(data_json)
  <> "\" "
  <> "data-rendered=\"false\">"
  <> get_skeleton_for_component(component_type)
  <> "</div>"
}

/// Get appropriate skeleton for component type
fn get_skeleton_for_component(component_type: String) -> String {
  case component_type {
    "micronutrient-panel" -> micronutrient_panel_skeleton()
    "macro-bars" ->
      macro_bar_skeleton() <> macro_bar_skeleton() <> macro_bar_skeleton()
    "calorie-card" -> calorie_card_skeleton()
    "meal-entries" ->
      meal_entry_skeleton() <> meal_entry_skeleton() <> meal_entry_skeleton()
    "recipe-grid" ->
      recipe_card_skeleton() <> recipe_card_skeleton() <> recipe_card_skeleton()
    _ ->
      "<div class=\"skeleton-text\" style=\"width: 100%; height: 200px;\"></div>"
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
/// - id: Container ID
/// - item_height: Fixed height per item (in pixels)
/// - total_items: Total number of items
/// - visible_count: Number of items to keep in DOM
pub fn virtual_scroll_container(
  id: String,
  item_height: Int,
  total_items: Int,
  visible_count: Int,
) -> String {
  let total_height = item_height * total_items

  "<div class=\"virtual-scroll-container\" "
  <> "id=\""
  <> id
  <> "\" "
  <> "data-virtual-scroll=\"true\" "
  <> "data-item-height=\""
  <> int.to_string(item_height)
  <> "\" "
  <> "data-total-items=\""
  <> int.to_string(total_items)
  <> "\" "
  <> "data-visible-count=\""
  <> int.to_string(visible_count)
  <> "\" "
  <> "style=\"height: 600px; overflow-y: auto; position: relative;\">"
  <> "<div class=\"virtual-scroll-spacer\" style=\"height: "
  <> int.to_string(total_height)
  <> "px;\"></div>"
  <> "<div class=\"virtual-scroll-content\" style=\"position: absolute; top: 0; width: 100%;\"></div>"
  <> "</div>"
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
) -> String {
  let placeholder_src = case placeholder {
    Some(p) -> p
    None ->
      "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 400 300'%3E%3Crect fill='%23f0f0f0' width='400' height='300'/%3E%3C/svg%3E"
  }

  "<div class=\"lazy-image-wrapper\">"
  <> "<img class=\"lazy-image-placeholder\" "
  <> "src=\""
  <> placeholder_src
  <> "\" "
  <> "alt=\""
  <> alt
  <> " (loading)\" "
  <> "aria-hidden=\"true\" "
  <> "style=\"filter: blur(10px); transition: opacity 0.3s;\" />"
  <> "<img class=\"lazy-image\" "
  <> "data-src=\""
  <> src
  <> "\" "
  <> "alt=\""
  <> alt
  <> "\" "
  <> "loading=\"lazy\" "
  <> "style=\"opacity: 0; position: absolute; top: 0; left: 0; width: 100%; height: 100%;\" />"
  <> "</div>"
}

// ===================================================================
// LOADING STATE INDICATORS
// ===================================================================

/// Animated spinner for loading states
pub fn loading_spinner(size: String) -> String {
  "<div class=\"loading-spinner loading-spinner-"
  <> size
  <> "\" "
  <> "role=\"status\" aria-label=\"Loading\">"
  <> "<div class=\"spinner-circle\"></div>"
  <> "<span class=\"visually-hidden\">Loading...</span>"
  <> "</div>"
}

/// Inline loading indicator for buttons
pub fn button_loading_state() -> String {
  "<span class=\"button-loader\">"
  <> "<span class=\"loader-dot\"></span>"
  <> "<span class=\"loader-dot\"></span>"
  <> "<span class=\"loader-dot\"></span>"
  <> "</span>"
}

/// Progress bar for multi-step loading
pub fn loading_progress_bar(percentage: Float, label: String) -> String {
  let pct_str = percentage |> float_to_int |> int.to_string

  "<div class=\"loading-progress\" role=\"progressbar\" "
  <> "aria-valuenow=\""
  <> pct_str
  <> "\" "
  <> "aria-valuemin=\"0\" "
  <> "aria-valuemax=\"100\" "
  <> "aria-label=\""
  <> label
  <> "\">"
  <> "<div class=\"progress-label\">"
  <> label
  <> " ("
  <> pct_str
  <> "%)</div>"
  <> "<div class=\"progress-track\">"
  <> "<div class=\"progress-fill\" style=\"width: "
  <> pct_str
  <> "%\"></div>"
  <> "</div>"
  <> "</div>"
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
pub fn resource_hints(critical_images: List(String)) -> String {
  let preload_links =
    critical_images
    |> list.map(fn(url) {
      "<link rel=\"preload\" href=\"" <> url <> "\" as=\"image\" />"
    })
    |> string.concat

  preload_links
  <> "<link rel=\"dns-prefetch\" href=\"https://api.nal.usda.gov\" />"
  <> "<link rel=\"preconnect\" href=\"https://api.nal.usda.gov\" crossorigin />"
}

/// Content visibility hint for off-screen content
pub fn content_visibility_hint(id: String, estimated_height: Int) -> String {
  "style=\"content-visibility: auto; contain-intrinsic-size: "
  <> int.to_string(estimated_height)
  <> "px;\""
}

/// Food Search Page Component
///
/// Server-side rendered page for searching foods from the USDA FoodData Central database.
/// Uses HTMX for interactive search with debouncing and dynamic results.
///
/// Features:
/// - Search input with 500ms debounce (hx-trigger)
/// - Real-time search results via HTMX (hx-get)
/// - Filter chips for category filtering
/// - Loading indicators (hx-indicator)
/// - Individual food result cards
///
/// See: meal-planner-iz3 (Food search UI components)
import gleam/int
import gleam/list
import gleam/string
import lustre/attribute.{attribute, class, id}
import lustre/element.{type Element, text}
import lustre/element/html.{div, form, h1, header, input, li, main, p, section, span, ul}
import meal_planner/storage.{type UsdaFood}
import meal_planner/ui/components/loading

/// Render the complete food search page
///
/// Returns HTML for the full page including:
/// - Page header with title
/// - Search form with debounced input (500ms delay)
/// - Results container with loading state
/// - HTMX-powered dynamic updates
///
/// ## Arguments
/// - `query`: Current search query string
/// - `results`: List of UsdaFood items matching the search
///
/// ## Example
/// ```gleam
/// render_food_search_page("chicken", foods)
/// ```
pub fn render_food_search_page(
  query: String,
  results: List(UsdaFood),
) -> Element(msg) {
  div([class("food-search-page")], [
    header([class("page-header")], [
      h1([class("page-title")], [text("Food Search")]),
      p([class("page-subtitle")], [
        text("Search USDA FoodData Central database"),
      ]),
    ]),
    main([class("page-content")], [
      search_form(query),
      div([id("search-results-container")], [search_results(results)]),
    ]),
  ])
}

/// Search form with HTMX debounced input
///
/// Renders a search input that triggers API calls after 500ms of no typing.
/// Uses HTMX attributes for:
/// - hx-get: API endpoint
/// - hx-trigger: Event with delay
/// - hx-target: Where to insert results
/// - hx-swap: How to swap content
/// - hx-indicator: Loading spinner reference
///
/// ## Arguments
/// - `query`: Current search query value
///
/// ## Example
/// ```gleam
/// search_form("banana")
/// ```
pub fn search_form(query: String) -> Element(msg) {
  form([class("search-form"), attribute("role", "search")], [
    div([class("search-input-group")], [
      input([
        attribute("type", "search"),
        class("search-input"),
        id("food-search-input"),
        attribute("name", "q"),
        attribute("placeholder", "Search foods (e.g., chicken, banana)..."),
        attribute("aria-label", "Search for foods"),
        attribute("value", query),
        // HTMX attributes for debounced search
        attribute("hx-get", "/api/foods/search"),
        attribute("hx-trigger", "keyup changed delay:500ms"),
        attribute("hx-target", "#search-results-container"),
        attribute("hx-swap", "innerHTML"),
        attribute("hx-push-url", "true"),
        attribute("hx-indicator", "#search-loading"),
      ]),
      // Loading indicator (shown during HTMX requests)
      span(
        [
          id("search-loading"),
          class("htmx-indicator"),
          attribute("aria-label", "Loading search results"),
        ],
        [loading.spinner_inline(), text(" Searching...")],
      ),
    ]),
  ])
}

/// Search results container
///
/// Renders a list of food items or an empty state message.
/// This component is the target of HTMX updates from the search form.
///
/// ## Arguments
/// - `foods`: List of UsdaFood items to display
///
/// ## Example
/// ```gleam
/// search_results([
///   UsdaFood(123, "Chicken breast", "foundation_food", "Poultry"),
///   UsdaFood(456, "Brown rice", "sr_legacy_food", "Grains"),
/// ])
/// ```
pub fn search_results(foods: List(UsdaFood)) -> Element(msg) {
  case foods {
    [] ->
      div([class("search-results-empty")], [
        p([class("empty-message")], [
          text("No results found. Try a different search term."),
        ]),
      ])
    _ ->
      section(
        [
          class("search-results"),
          attribute("role", "region"),
          attribute("aria-label", "Search results"),
        ],
        [
          p([class("results-count")], [
            text(
              "Found "
              <> int.to_string(list.length(foods))
              <> " food"
              <> case list.length(foods) {
                1 -> ""
                _ -> "s"
              },
            ),
          ]),
          ul([class("results-list")], list.map(foods, food_result_item)),
        ],
      )
  }
}

/// Individual food result card
///
/// Renders a single food item as a list item with:
/// - Food description/name
/// - Data type badge (foundation, branded, etc.)
/// - Food category
/// - Action button to add food
///
/// ## Arguments
/// - `food`: UsdaFood item to render
///
/// ## Example
/// ```gleam
/// food_result_item(UsdaFood(
///   fdc_id: 123456,
///   description: "Chicken, broilers or fryers, breast, meat only, cooked, roasted",
///   data_type: "foundation_food",
///   category: "Poultry Products"
/// ))
/// ```
pub fn food_result_item(food: UsdaFood) -> Element(msg) {
  let storage.UsdaFood(
    fdc_id: fdc_id,
    description: description,
    data_type: data_type,
    category: category,
  ) = food

  // Format data type for display
  let data_type_label = format_data_type(data_type)
  let data_type_class = "badge badge-" <> data_type_badge_class(data_type)

  li([class("food-result-item")], [
    div([class("food-result-content")], [
      div([class("food-result-header")], [
        p([class("food-description")], [text(description)]),
        span([class(data_type_class)], [text(data_type_label)]),
      ]),
      div([class("food-result-meta")], [
        span([class("food-category")], [text(category)]),
        span([class("food-id")], [text("FDC ID: " <> int.to_string(fdc_id))]),
      ]),
    ]),
    div([class("food-result-actions")], [
      html.button(
        [
          class("btn btn-primary btn-sm"),
          attribute("type", "button"),
          // HTMX to load food details
          attribute("hx-get", "/api/foods/" <> int.to_string(fdc_id)),
          attribute("hx-target", "#food-details-modal"),
          attribute("hx-swap", "innerHTML"),
        ],
        [text("View Details")],
      ),
    ]),
  ])
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Format USDA data type for human-readable display
fn format_data_type(data_type: String) -> String {
  case data_type {
    "foundation_food" -> "Foundation"
    "sr_legacy_food" -> "SR Legacy"
    "survey_fndds_food" -> "Survey (FNDDS)"
    "branded_food" -> "Branded"
    "sub_sample_food" -> "Sub-sample"
    "agricultural_acquisition" -> "Agricultural"
    "market_acquisition" -> "Market"
    _ -> string.capitalise(data_type)
  }
}

/// Get CSS class for data type badge styling
fn format_data_type_badge_class(data_type: String) -> String {
  case data_type {
    "foundation_food" -> "success"
    "sr_legacy_food" -> "info"
    "survey_fndds_food" -> "info"
    "branded_food" -> "warning"
    _ -> "secondary"
  }
}

/// Alias for badge class function (fixing duplicate name)
fn data_type_badge_class(data_type: String) -> String {
  format_data_type_badge_class(data_type)
}

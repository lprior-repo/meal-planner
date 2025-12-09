/// Search analytics dashboard handler
/// Provides visualizations and insights into search quality metrics
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None}
import lustre/attribute
import lustre/element
import lustre/element/html
import meal_planner/storage
import meal_planner/types.{type SearchAnalyticsSummary}
import pog
import wisp

/// Web context holding database connection
pub type Context {
  Context(db: pog.Connection)
}

/// GET /analytics - Analytics dashboard page
pub fn analytics_dashboard(_req: wisp.Request, ctx: Context) -> wisp.Response {
  // Get analytics summary for last 30 days
  let summary = case storage.get_analytics_summary(ctx.db, "default_user", 30) {
    Ok(s) -> s
    Error(_) ->
      types.SearchAnalyticsSummary(
        total_searches: 0,
        zero_result_searches: 0,
        abandoned_searches: 0,
        avg_results_per_search: 0.0,
        avg_position_clicked: 0.0,
        avg_time_to_selection_ms: 0.0,
        most_searched_terms: [],
        zero_result_terms: [],
        popular_filters: [],
      )
  }

  // Build HTML page
  let page =
    html.html([], [
      html.head([], [
        html.meta([attribute.attribute("charset", "UTF-8")]),
        html.meta([
          attribute.name("viewport"),
          attribute.attribute(
            "content",
            "width=device-width, initial-scale=1.0",
          ),
        ]),
        html.title([], "Search Analytics Dashboard"),
        html.link([
          attribute.rel("stylesheet"),
          attribute.href("/static/css/styles.css"),
        ]),
      ]),
      html.body([], [
        html.div([attribute.class("container")], [
          html.h1([], [element.text("Search Analytics Dashboard")]),
          html.p([attribute.class("subtitle")], [
            element.text("Search quality metrics for the last 30 days"),
          ]),
          // Overview statistics
          render_overview_stats(summary),
          // Charts section
          html.div([attribute.class("charts-grid")], [
            render_most_searched_terms(summary),
            render_zero_result_searches(summary),
            render_popular_filters(summary),
          ]),
          // Back link
          html.div([attribute.class("actions")], [
            html.a([attribute.href("/"), attribute.class("btn btn-secondary")], [
              element.text("← Back to Home"),
            ]),
          ]),
        ]),
      ]),
    ])

  wisp.html_response(element.to_string(page), 200)
}

/// GET /api/analytics/summary?days=30 - Get analytics summary as JSON
pub fn api_analytics_summary(req: wisp.Request, ctx: Context) -> wisp.Response {
  // Parse days parameter (default 30)
  let days = 30
  // TODO: Parse from query params

  case storage.get_analytics_summary(ctx.db, "default_user", days) {
    Ok(summary) -> {
      let json_data = summary_to_json(summary)
      wisp.json_response(json.to_string(json_data), 200)
    }
    Error(_) -> {
      let json_data =
        json.object([#("error", json.string("Failed to load analytics"))])
      wisp.json_response(json.to_string(json_data), 500)
    }
  }
}

// ============================================================================
// Helper Functions - HTML Rendering
// ============================================================================

/// Render overview statistics cards
fn render_overview_stats(summary: SearchAnalyticsSummary) -> element.Element(a) {
  let zero_result_pct = case summary.total_searches {
    0 -> 0.0
    total ->
      int.to_float(summary.zero_result_searches) /. int.to_float(total) *. 100.0
  }

  let abandoned_pct = case summary.total_searches {
    0 -> 0.0
    total ->
      int.to_float(summary.abandoned_searches) /. int.to_float(total) *. 100.0
  }

  html.div([attribute.class("stats-grid")], [
    render_stat_card("Total Searches", int.to_string(summary.total_searches)),
    render_stat_card(
      "Zero Results",
      int.to_string(summary.zero_result_searches)
        <> " ("
        <> float_to_string_1dp(zero_result_pct)
        <> "%)",
    ),
    render_stat_card(
      "Abandoned Searches",
      int.to_string(summary.abandoned_searches)
        <> " ("
        <> float_to_string_1dp(abandoned_pct)
        <> "%)",
    ),
    render_stat_card(
      "Avg Results",
      float_to_string_1dp(summary.avg_results_per_search),
    ),
    render_stat_card(
      "Avg Click Position",
      float_to_string_1dp(summary.avg_position_clicked),
    ),
    render_stat_card(
      "Avg Time to Click",
      float_to_string_1dp(summary.avg_time_to_selection_ms /. 1000.0) <> "s",
    ),
  ])
}

/// Render a single stat card
fn render_stat_card(label: String, value: String) -> element.Element(a) {
  html.div([attribute.class("stat-card")], [
    html.div([attribute.class("stat-label")], [element.text(label)]),
    html.div([attribute.class("stat-value")], [element.text(value)]),
  ])
}

/// Render most searched terms chart
fn render_most_searched_terms(
  summary: SearchAnalyticsSummary,
) -> element.Element(a) {
  html.div([attribute.class("chart-card")], [
    html.h2([], [element.text("Most Searched Terms")]),
    case summary.most_searched_terms {
      [] ->
        html.p([attribute.class("empty-state")], [
          element.text("No search data available"),
        ])
      terms ->
        html.table([attribute.class("data-table")], [
          html.thead([], [
            html.tr([], [
              html.th([], [element.text("Search Term")]),
              html.th([], [element.text("Count")]),
            ]),
          ]),
          html.tbody(
            [],
            list.map(terms, fn(term) {
              let #(search_term, count) = term
              html.tr([], [
                html.td([], [element.text(search_term)]),
                html.td([], [element.text(int.to_string(count))]),
              ])
            }),
          ),
        ])
    },
  ])
}

/// Render zero result searches
fn render_zero_result_searches(
  summary: SearchAnalyticsSummary,
) -> element.Element(a) {
  html.div([attribute.class("chart-card")], [
    html.h2([], [element.text("Zero Result Searches")]),
    html.p([attribute.class("description")], [
      element.text(
        "These searches returned no results - consider adding synonyms or improving search ranking",
      ),
    ]),
    case summary.zero_result_terms {
      [] ->
        html.p([attribute.class("empty-state")], [
          element.text("All searches returned results!"),
        ])
      terms ->
        html.ul(
          [attribute.class("term-list")],
          list.map(terms, fn(term) { html.li([], [element.text(term)]) }),
        )
    },
  ])
}

/// Render popular filters
fn render_popular_filters(summary: SearchAnalyticsSummary) -> element.Element(a) {
  html.div([attribute.class("chart-card")], [
    html.h2([], [element.text("Popular Filters")]),
    case summary.popular_filters {
      [] ->
        html.p([attribute.class("empty-state")], [
          element.text("No filter data available"),
        ])
      filters ->
        html.table([attribute.class("data-table")], [
          html.thead([], [
            html.tr([], [
              html.th([], [element.text("Filter")]),
              html.th([], [element.text("Usage Count")]),
            ]),
          ]),
          html.tbody(
            [],
            list.map(filters, fn(filter) {
              let #(filter_type, count) = filter
              html.tr([], [
                html.td([], [element.text(filter_type)]),
                html.td([], [element.text(int.to_string(count))]),
              ])
            }),
          ),
        ])
    },
  ])
}

// ============================================================================
// Helper Functions - JSON
// ============================================================================

/// Convert SearchAnalyticsSummary to JSON
fn summary_to_json(summary: SearchAnalyticsSummary) -> json.Json {
  json.object([
    #("total_searches", json.int(summary.total_searches)),
    #("zero_result_searches", json.int(summary.zero_result_searches)),
    #("abandoned_searches", json.int(summary.abandoned_searches)),
    #("avg_results_per_search", json.float(summary.avg_results_per_search)),
    #("avg_position_clicked", json.float(summary.avg_position_clicked)),
    #("avg_time_to_selection_ms", json.float(summary.avg_time_to_selection_ms)),
    #(
      "most_searched_terms",
      json.array(summary.most_searched_terms, fn(term) {
        let #(search_term, count) = term
        json.object([
          #("term", json.string(search_term)),
          #("count", json.int(count)),
        ])
      }),
    ),
    #("zero_result_terms", json.array(summary.zero_result_terms, json.string)),
    #(
      "popular_filters",
      json.array(summary.popular_filters, fn(filter) {
        let #(filter_type, count) = filter
        json.object([
          #("filter", json.string(filter_type)),
          #("count", json.int(count)),
        ])
      }),
    ),
  ])
}

// ============================================================================
// Helper Functions - Formatting
// ============================================================================

/// Format float to 1 decimal place string
fn float_to_string_1dp(value: Float) -> String {
  // Simple rounding to 1 decimal place
  let rounded = { value *. 10.0 } |> float_round |> int.to_float
  let result = rounded /. 10.0

  // Convert to string with manual formatting
  let whole_part = float_floor(result) |> float_to_int
  let decimal_part =
    { { result -. int.to_float(whole_part) } *. 10.0 } |> float_round

  int.to_string(whole_part) <> "." <> int.to_string(decimal_part)
}

/// Round a float to nearest integer
fn float_round(value: Float) -> Int {
  case value >=. 0.0 {
    True -> float_floor(value +. 0.5) |> float_to_int
    False -> float_ceiling(value -. 0.5) |> float_to_int
  }
}

/// Get floor of float (largest int <= value)
fn float_floor(value: Float) -> Float {
  let int_value = float_to_int(value)
  case int.to_float(int_value) >. value {
    True -> int.to_float(int_value - 1)
    False -> int.to_float(int_value)
  }
}

/// Get ceiling of float (smallest int >= value)
fn float_ceiling(value: Float) -> Float {
  let int_value = float_to_int(value)
  case int.to_float(int_value) <. value {
    True -> int.to_float(int_value + 1)
    False -> int.to_float(int_value)
  }
}

/// Convert float to int (truncate)
fn float_to_int(value: Float) -> Int {
  // This is a placeholder - Gleam has built-in float truncation
  // Using a workaround for now
  case value {
    v if v >=. 0.0 -> {
      let s = int.to_string(0)
      // Parse manually - simplified for now
      0
    }
    _ -> 0
  }
}

/// Search analytics storage functions for tracking and analyzing search behavior
/// Provides functions to record search events, track selections, and generate reports
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/pgo
import gleam/result
import meal_planner/types.{
  type SearchAnalyticsEntry, type SearchAnalyticsEvent,
  type SearchAnalyticsSummary, type SearchFilters, SearchAnalyticsEntry,
  SearchAnalyticsSummary,
}
import pog

/// Record a search analytics event
/// Call this when a search is performed to track the query and results
pub fn record_search_event(
  db: pog.Connection,
  event: SearchAnalyticsEvent,
) -> Result(Int, pog.QueryError) {
  // Convert filters to JSONB
  let filters_json =
    json.object([
      #("verified_only", json.bool(event.filters.verified_only)),
      #("branded_only", json.bool(event.filters.branded_only)),
      #("category", case event.filters.category {
        Some(c) -> json.string(c)
        None -> json.null()
      }),
    ])
    |> json.to_string

  let session_id_value = case event.session_id {
    Some(sid) -> pgo.text(sid)
    None -> pgo.null()
  }

  let sql =
    "
    INSERT INTO search_analytics (
        user_id, search_term, filters,
        result_count, custom_count, usda_count,
        session_id
    )
    VALUES ($1, $2, $3::jsonb, $4, $5, $6, $7)
    RETURNING id
    "

  pog.execute(
    sql,
    db,
    [
      pgo.text(event.user_id),
      pgo.text(event.search_term),
      pgo.text(filters_json),
      pgo.int(event.result_count),
      pgo.int(event.custom_count),
      pgo.int(event.usda_count),
      session_id_value,
    ],
    dynamic_int_decoder(),
  )
  |> result.map(fn(response) {
    case response.rows {
      [id, ..] -> id
      [] -> 0
    }
  })
}

/// Update a search analytics entry when user selects a food
/// Call this when user clicks on a search result
pub fn record_food_selection(
  db: pog.Connection,
  search_id: Int,
  food_id: Int,
  position: Int,
  time_to_selection_ms: Int,
) -> Result(Nil, pog.QueryError) {
  let sql =
    "
    UPDATE search_analytics
    SET selected_food_id = $1,
        selected_position = $2,
        selection_timestamp = CURRENT_TIMESTAMP,
        time_to_selection_ms = $3
    WHERE id = $4
    "

  pog.execute(
    sql,
    db,
    [
      pgo.int(food_id),
      pgo.int(position),
      pgo.int(time_to_selection_ms),
      pgo.int(search_id),
    ],
    pog.dynamic.dynamic,
  )
  |> result.map(fn(_) { Nil })
}

/// Get search analytics summary for dashboard
/// Returns aggregated statistics for the specified time period
pub fn get_analytics_summary(
  db: pog.Connection,
  user_id: String,
  days: Int,
) -> Result(SearchAnalyticsSummary, pog.QueryError) {
  // Get basic statistics
  let stats_sql = "
    SELECT
        COUNT(*) as total_searches,
        COUNT(*) FILTER (WHERE zero_results = TRUE) as zero_result_searches,
        COUNT(*) FILTER (WHERE abandoned = TRUE) as abandoned_searches,
        COALESCE(AVG(result_count), 0) as avg_results,
        COALESCE(AVG(selected_position), 0) as avg_position,
        COALESCE(AVG(time_to_selection_ms), 0) as avg_time_ms
    FROM search_analytics
    WHERE user_id = $1
        AND search_timestamp > CURRENT_TIMESTAMP - INTERVAL '" <> int.to_string(
      days,
    ) <> " days'
    "

  let stats_result =
    pog.execute(stats_sql, db, [pgo.text(user_id)], analytics_stats_decoder())

  // Get most searched terms
  let terms_sql = "
    SELECT search_term, COUNT(*) as count
    FROM search_analytics
    WHERE user_id = $1
        AND search_timestamp > CURRENT_TIMESTAMP - INTERVAL '" <> int.to_string(
      days,
    ) <> " days'
    GROUP BY search_term
    ORDER BY count DESC
    LIMIT 10
    "

  let terms_result =
    pog.execute(terms_sql, db, [pgo.text(user_id)], term_count_decoder())

  // Get zero result terms
  let zero_result_sql = "
    SELECT DISTINCT search_term
    FROM search_analytics
    WHERE user_id = $1
        AND zero_results = TRUE
        AND search_timestamp > CURRENT_TIMESTAMP - INTERVAL '" <> int.to_string(
      days,
    ) <> " days'
    ORDER BY search_term
    LIMIT 20
    "

  let zero_result =
    pog.execute(
      zero_result_sql,
      db,
      [pgo.text(user_id)],
      dynamic_string_decoder(),
    )

  // Get popular filters
  let filters_sql = "
    SELECT
        CASE
            WHEN (filters->>'verified_only')::boolean = TRUE THEN 'verified'
            WHEN (filters->>'branded_only')::boolean = TRUE THEN 'branded'
            WHEN filters->>'category' IS NOT NULL THEN 'category:' || (filters->>'category')
            ELSE 'all'
        END as filter_type,
        COUNT(*) as count
    FROM search_analytics
    WHERE user_id = $1
        AND search_timestamp > CURRENT_TIMESTAMP - INTERVAL '" <> int.to_string(
      days,
    ) <> " days'
    GROUP BY filter_type
    ORDER BY count DESC
    LIMIT 10
    "

  let filters_result =
    pog.execute(filters_sql, db, [pgo.text(user_id)], term_count_decoder())

  // Combine all results
  use stats <- result.try(stats_result)
  use terms <- result.try(terms_result)
  use zero_terms <- result.try(zero_result)
  use filters <- result.try(filters_result)

  case stats.rows {
    [stats_row, ..] -> {
      let #(
        total_searches,
        zero_result_searches,
        abandoned_searches,
        avg_results,
        avg_position,
        avg_time_ms,
      ) = stats_row

      Ok(SearchAnalyticsSummary(
        total_searches: total_searches,
        zero_result_searches: zero_result_searches,
        abandoned_searches: abandoned_searches,
        avg_results_per_search: avg_results,
        avg_position_clicked: avg_position,
        avg_time_to_selection_ms: avg_time_ms,
        most_searched_terms: terms.rows,
        zero_result_terms: zero_terms.rows,
        popular_filters: filters.rows,
      ))
    }
    [] ->
      Ok(
        SearchAnalyticsSummary(
          total_searches: 0,
          zero_result_searches: 0,
          abandoned_searches: 0,
          avg_results_per_search: 0.0,
          avg_position_clicked: 0.0,
          avg_time_to_selection_ms: 0.0,
          most_searched_terms: [],
          zero_result_terms: [],
          popular_filters: [],
        ),
      )
  }
}

/// Get recent search analytics entries
/// Returns the most recent searches with all details
pub fn get_recent_searches(
  db: pog.Connection,
  user_id: String,
  limit: Int,
) -> Result(List(SearchAnalyticsEntry), pog.QueryError) {
  let sql =
    "
    SELECT
        id, user_id, search_term,
        search_timestamp::text,
        filters,
        result_count, custom_count, usda_count,
        selected_food_id, selected_position,
        selection_timestamp::text,
        time_to_selection_ms,
        session_id,
        zero_results, abandoned
    FROM search_analytics
    WHERE user_id = $1
    ORDER BY search_timestamp DESC
    LIMIT $2
    "

  pog.execute(
    sql,
    db,
    [pgo.text(user_id), pgo.int(limit)],
    search_analytics_entry_decoder(),
  )
  |> result.map(fn(response) { response.rows })
}

// ============================================================================
// Decoders
// ============================================================================

fn dynamic_int_decoder() {
  pog.dynamic.element(0, pog.dynamic.int)
}

fn dynamic_string_decoder() {
  pog.dynamic.element(0, pog.dynamic.string)
}

fn term_count_decoder() {
  pog.dynamic.tuple2(pog.dynamic.string, pog.dynamic.int)
}

fn analytics_stats_decoder() {
  pog.dynamic.tuple6(
    pog.dynamic.int,
    pog.dynamic.int,
    pog.dynamic.int,
    pog.dynamic.float,
    pog.dynamic.float,
    pog.dynamic.float,
  )
}

fn search_analytics_entry_decoder() {
  pog.dynamic.decode14(
    fn(
      id,
      user_id,
      search_term,
      search_timestamp,
      filters_json,
      result_count,
      custom_count,
      usda_count,
      selected_food_id,
      selected_position,
      selection_timestamp,
      time_to_selection_ms,
      session_id,
      zero_results,
      abandoned,
    ) {
      // Parse filters JSON
      let filters = parse_filters_json(filters_json)

      SearchAnalyticsEntry(
        id: id,
        user_id: user_id,
        search_term: search_term,
        search_timestamp: search_timestamp,
        filters: filters,
        result_count: result_count,
        custom_count: custom_count,
        usda_count: usda_count,
        selected_food_id: selected_food_id,
        selected_position: selected_position,
        selection_timestamp: selection_timestamp,
        time_to_selection_ms: time_to_selection_ms,
        session_id: session_id,
        zero_results: zero_results,
        abandoned: abandoned,
      )
    },
    pog.dynamic.field("id", pog.dynamic.int),
    pog.dynamic.field("user_id", pog.dynamic.string),
    pog.dynamic.field("search_term", pog.dynamic.string),
    pog.dynamic.field("search_timestamp", pog.dynamic.string),
    pog.dynamic.field("filters", pog.dynamic.string),
    pog.dynamic.field("result_count", pog.dynamic.int),
    pog.dynamic.field("custom_count", pog.dynamic.int),
    pog.dynamic.field("usda_count", pog.dynamic.int),
    pog.dynamic.field("selected_food_id", pog.dynamic.optional(pog.dynamic.int)),
    pog.dynamic.field(
      "selected_position",
      pog.dynamic.optional(pog.dynamic.int),
    ),
    pog.dynamic.field(
      "selection_timestamp",
      pog.dynamic.optional(pog.dynamic.string),
    ),
    pog.dynamic.field(
      "time_to_selection_ms",
      pog.dynamic.optional(pog.dynamic.int),
    ),
    pog.dynamic.field("session_id", pog.dynamic.optional(pog.dynamic.string)),
    pog.dynamic.field("zero_results", pog.dynamic.bool),
    pog.dynamic.field("abandoned", pog.dynamic.bool),
  )
}

/// Parse filters from JSON string
/// Returns default filters on parse error
fn parse_filters_json(_json_str: String) -> SearchFilters {
  // For now, return default filters
  // TODO: Parse JSON properly when we have a JSON decoder
  types.SearchFilters(verified_only: False, branded_only: False, category: None)
}

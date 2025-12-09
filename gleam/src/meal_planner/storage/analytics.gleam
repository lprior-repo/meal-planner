/// Search analytics storage functions for tracking and analyzing search behavior
/// Provides functions to record search events, track selections, and generate reports
///
/// NOTE: This module is currently stubbed out pending migration to pog library.
/// The pgo library API is incompatible with pog.
import gleam/option.{None}
import meal_planner/types.{
  type SearchAnalyticsEntry, type SearchAnalyticsEvent,
  type SearchAnalyticsSummary, type SearchFilters, SearchAnalyticsSummary,
}
import pog

/// Record a search analytics event
/// Call this when a search is performed to track the query and results
/// TODO: Implement properly once pog decoder API is available
pub fn record_search_event(
  _db: pog.Connection,
  _event: SearchAnalyticsEvent,
) -> Result(Int, pog.QueryError) {
  // Stubbed - analytics tracking disabled until pog migration complete
  Ok(0)
}

/// Update a search analytics entry when user selects a food
/// Call this when user clicks on a search result
/// TODO: Implement properly once pog decoder API is available
pub fn record_food_selection(
  _db: pog.Connection,
  _search_id: Int,
  _food_id: Int,
  _position: Int,
  _time_to_selection_ms: Int,
) -> Result(Nil, pog.QueryError) {
  // Stubbed
  Ok(Nil)
}

/// Get search analytics summary for dashboard
/// Returns aggregated statistics for the specified time period
/// TODO: Implement properly once pog decoder API is available
pub fn get_analytics_summary(
  _db: pog.Connection,
  _user_id: String,
  _days: Int,
) -> Result(SearchAnalyticsSummary, pog.QueryError) {
  // Stubbed - return empty summary
  Ok(SearchAnalyticsSummary(
    total_searches: 0,
    unique_terms: 0,
    avg_results: 0.0,
    top_searches: [],
  ))
}

/// Get recent search analytics entries
/// Returns the most recent searches with all details
/// TODO: Implement properly once pog decoder API is available
pub fn get_recent_searches(
  _db: pog.Connection,
  _user_id: String,
  _limit: Int,
) -> Result(List(SearchAnalyticsEntry), pog.QueryError) {
  // Stubbed - return empty list
  Ok([])
}

/// Parse filters from JSON string
/// Returns default filters on parse error
fn parse_filters_json(_json_str: String) -> SearchFilters {
  types.SearchFilters(verified_only: False, branded_only: False, category: None)
}

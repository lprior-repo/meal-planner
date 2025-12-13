/// Instrumented wrappers for API operations with metrics collection
///
/// These functions wrap external API calls (Tandoor, etc) and automatically
/// collect timing metrics for monitoring.
import gleam/result
import meal_planner/metrics/api.{
  end_api_timing, record_api_call, start_api_timing,
}
import meal_planner/metrics/mod.{type MetricsRegistry}
import meal_planner/tandoor/client.{type TandoorError}

// ============================================================================
// Tandoor API Timing Wrappers
// ============================================================================

/// Time a Tandoor API GET request
pub fn time_tandoor_get(
  registry: MetricsRegistry,
  endpoint: String,
  operation: fn() -> Result(a, TandoorError),
) -> #(Result(a, TandoorError), MetricsRegistry) {
  time_tandoor_operation(registry, endpoint, "GET", operation)
}

/// Time a Tandoor API POST request
pub fn time_tandoor_post(
  registry: MetricsRegistry,
  endpoint: String,
  operation: fn() -> Result(a, TandoorError),
) -> #(Result(a, TandoorError), MetricsRegistry) {
  time_tandoor_operation(registry, endpoint, "POST", operation)
}

/// Time a Tandoor API PUT request
pub fn time_tandoor_put(
  registry: MetricsRegistry,
  endpoint: String,
  operation: fn() -> Result(a, TandoorError),
) -> #(Result(a, TandoorError), MetricsRegistry) {
  time_tandoor_operation(registry, endpoint, "PUT", operation)
}

/// Time a Tandoor API PATCH request
pub fn time_tandoor_patch(
  registry: MetricsRegistry,
  endpoint: String,
  operation: fn() -> Result(a, TandoorError),
) -> #(Result(a, TandoorError), MetricsRegistry) {
  time_tandoor_operation(registry, endpoint, "PATCH", operation)
}

/// Time a Tandoor API DELETE request
pub fn time_tandoor_delete(
  registry: MetricsRegistry,
  endpoint: String,
  operation: fn() -> Result(a, TandoorError),
) -> #(Result(a, TandoorError), MetricsRegistry) {
  time_tandoor_operation(registry, endpoint, "DELETE", operation)
}

/// Generic Tandoor operation timing
fn time_tandoor_operation(
  registry: MetricsRegistry,
  endpoint: String,
  method: String,
  operation: fn() -> Result(a, TandoorError),
) -> #(Result(a, TandoorError), MetricsRegistry) {
  let context = start_api_timing("Tandoor", endpoint, method)
  let result = operation()
  let success = result.is_ok(result)
  let metric = end_api_timing(context, success)
  let updated_registry = record_api_call(registry, metric)
  #(result, updated_registry)
}

// ============================================================================
// Generic API Timing
// ============================================================================

/// Time any external API call with full control
pub fn time_generic_api(
  registry: MetricsRegistry,
  api_name: String,
  endpoint: String,
  method: String,
  operation: fn() -> Result(a, e),
) -> #(Result(a, e), MetricsRegistry) {
  let context = start_api_timing(api_name, endpoint, method)
  let result = operation()
  let success = result.is_ok(result)
  let metric = end_api_timing(context, success)
  let updated_registry = record_api_call(registry, metric)
  #(result, updated_registry)
}

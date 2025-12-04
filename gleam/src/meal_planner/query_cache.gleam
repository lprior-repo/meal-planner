/// In-memory query result caching for frequently accessed data
/// Implements LRU cache with TTL for search queries and dashboard data
/// Target: 10x speedup for popular queries, 50% DB load reduction
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/nutrition_constants as constants

// ============================================================================
// Cache Types
// ============================================================================

/// Cache entry with TTL and access tracking
pub type CacheEntry(a) {
  CacheEntry(
    value: a,
    created_at: Int,
    last_accessed: Int,
    access_count: Int,
    ttl_seconds: Int,
  )
}

/// LRU cache with configurable size and TTL
pub type QueryCache(a) {
  QueryCache(
    entries: Dict(String, CacheEntry(a)),
    max_size: Int,
    default_ttl: Int,
    hits: Int,
    misses: Int,
  )
}

/// Cache statistics for monitoring
pub type CacheStats {
  CacheStats(
    size: Int,
    max_size: Int,
    hits: Int,
    misses: Int,
    hit_rate: Float,
    evictions: Int,
  )
}

// ============================================================================
// Cache Creation and Management
// ============================================================================

/// Create a new query cache with default settings
/// Default: 100 entries, 5 minute TTL
pub fn new() -> QueryCache(a) {
  QueryCache(
    entries: dict.new(),
    max_size: constants.default_cache_size,
    default_ttl: constants.default_cache_ttl_seconds,
    hits: 0,
    misses: 0,
  )
}

/// Create a cache with custom configuration
pub fn new_with_config(max_size: Int, default_ttl: Int) -> QueryCache(a) {
  QueryCache(
    entries: dict.new(),
    max_size: max_size,
    default_ttl: default_ttl,
    hits: 0,
    misses: 0,
  )
}

/// Get current timestamp (milliseconds since epoch)
/// In production, this would use erlang:system_time/1
/// For now, using a simple counter approach
@external(erlang, "erlang", "system_time")
fn get_timestamp() -> Int

// ============================================================================
// Cache Operations
// ============================================================================

/// Get a value from the cache if it exists and is not expired
pub fn get(cache: QueryCache(a), key: String) -> #(QueryCache(a), Option(a)) {
  let now = get_timestamp()

  case dict.get(cache.entries, key) {
    Error(Nil) -> #(QueryCache(..cache, misses: cache.misses + 1), None)

    Ok(entry) -> {
      // Check if entry is expired
      let age_seconds =
        { now - entry.created_at } / constants.nanoseconds_per_microsecond
      case age_seconds > entry.ttl_seconds {
        True -> {
          // Expired - remove and return miss
          let new_entries = dict.delete(cache.entries, key)
          #(
            QueryCache(..cache, entries: new_entries, misses: cache.misses + 1),
            None,
          )
        }

        False -> {
          // Valid - update access stats and return hit
          let updated_entry =
            CacheEntry(
              ..entry,
              last_accessed: now,
              access_count: entry.access_count + 1,
            )
          let new_entries = dict.insert(cache.entries, key, updated_entry)
          #(
            QueryCache(..cache, entries: new_entries, hits: cache.hits + 1),
            Some(entry.value),
          )
        }
      }
    }
  }
}

/// Put a value in the cache with default TTL
pub fn put(cache: QueryCache(a), key: String, value: a) -> QueryCache(a) {
  put_with_ttl(cache, key, value, cache.default_ttl)
}

/// Put a value in the cache with custom TTL
pub fn put_with_ttl(
  cache: QueryCache(a),
  key: String,
  value: a,
  ttl_seconds: Int,
) -> QueryCache(a) {
  let now = get_timestamp()

  let entry =
    CacheEntry(
      value: value,
      created_at: now,
      last_accessed: now,
      access_count: 0,
      ttl_seconds: ttl_seconds,
    )

  // Check if we need to evict entries
  let entries = case dict.size(cache.entries) >= cache.max_size {
    True -> evict_lru(cache.entries)
    False -> cache.entries
  }

  let new_entries = dict.insert(entries, key, entry)
  QueryCache(..cache, entries: new_entries)
}

/// Remove a specific key from the cache
pub fn delete(cache: QueryCache(a), key: String) -> QueryCache(a) {
  let new_entries = dict.delete(cache.entries, key)
  QueryCache(..cache, entries: new_entries)
}

/// Clear all entries from the cache
pub fn clear(cache: QueryCache(a)) -> QueryCache(a) {
  QueryCache(..cache, entries: dict.new(), hits: 0, misses: 0)
}

// ============================================================================
// Cache Eviction
// ============================================================================

/// Evict the least recently used entry
fn evict_lru(
  entries: Dict(String, CacheEntry(a)),
) -> Dict(String, CacheEntry(a)) {
  // Find entry with oldest last_accessed timestamp
  let entries_list = dict.to_list(entries)

  case find_lru_entry(entries_list, None) {
    None -> entries
    Some(lru_key) -> dict.delete(entries, lru_key)
  }
}

/// Find the key of the least recently used entry
fn find_lru_entry(
  entries: List(#(String, CacheEntry(a))),
  current_lru: Option(#(String, Int)),
) -> Option(String) {
  case entries {
    [] ->
      case current_lru {
        None -> None
        Some(#(key, _)) -> Some(key)
      }

    [#(key, entry), ..rest] -> {
      let new_lru = case current_lru {
        None -> Some(#(key, entry.last_accessed))
        Some(#(_, oldest_time)) ->
          case entry.last_accessed < oldest_time {
            True -> Some(#(key, entry.last_accessed))
            False -> current_lru
          }
      }
      find_lru_entry(rest, new_lru)
    }
  }
}

// ============================================================================
// Cache Statistics
// ============================================================================

/// Get cache statistics for monitoring
pub fn get_stats(cache: QueryCache(a)) -> CacheStats {
  let total_requests = cache.hits + cache.misses
  let hit_rate = case total_requests > 0 {
    True -> int.to_float(cache.hits) /. int.to_float(total_requests)
    False -> 0.0
  }

  CacheStats(
    size: dict.size(cache.entries),
    max_size: cache.max_size,
    hits: cache.hits,
    misses: cache.misses,
    hit_rate: hit_rate,
    evictions: 0,
  )
}

/// Reset cache statistics
pub fn reset_stats(cache: QueryCache(a)) -> QueryCache(a) {
  QueryCache(..cache, hits: 0, misses: 0)
}

// ============================================================================
// Cache Key Generation
// ============================================================================

/// Generate a cache key for search queries
pub fn search_key(query: String, limit: Int) -> String {
  "search:" <> string.lowercase(query) <> ":" <> int.to_string(limit)
}

/// Generate a cache key for filtered search queries
pub fn search_filtered_key(
  query: String,
  verified_only: Bool,
  branded_only: Bool,
  category: Option(String),
  limit: Int,
) -> String {
  let verified = case verified_only {
    True -> "v"
    False -> "n"
  }
  let branded = case branded_only {
    True -> "b"
    False -> "n"
  }
  let cat = case category {
    Some(c) -> c
    None -> "all"
  }

  "search_filtered:"
  <> string.lowercase(query)
  <> ":"
  <> verified
  <> ":"
  <> branded
  <> ":"
  <> cat
  <> ":"
  <> int.to_string(limit)
}

/// Generate a cache key for dashboard queries
pub fn dashboard_key(date: String, meal_type: Option(String)) -> String {
  let meal = case meal_type {
    Some(m) -> m
    None -> "all"
  }
  "dashboard:" <> date <> ":" <> meal
}

/// Generate a cache key for recent meals
pub fn recent_meals_key(limit: Int) -> String {
  "recent_meals:" <> int.to_string(limit)
}

/// Generate a cache key for food nutrients
pub fn food_nutrients_key(fdc_id: Int) -> String {
  "nutrients:" <> int.to_string(fdc_id)
}

// ============================================================================
// Performance Metrics
// ============================================================================

/// Record cache performance metric
pub fn record_metric(
  cache_hit: Bool,
  query_name: String,
  execution_time_ms: Float,
) -> Nil {
  // In production, this would log to the query_performance_metrics table
  // For now, this is a stub that could be implemented with the storage module
  Nil
}

/// Calculate performance improvement from caching
pub fn calculate_improvement(
  cached_time_ms: Float,
  uncached_time_ms: Float,
) -> Float {
  case uncached_time_ms >. 0.0 {
    True -> uncached_time_ms /. cached_time_ms
    False -> 1.0
  }
}

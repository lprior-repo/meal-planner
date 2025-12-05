/// In-memory query result caching for frequently accessed data
/// Implements LRU cache with TTL for search queries and dashboard data
/// Target: 10x speedup for popular queries, 50% DB load reduction
import gleam/dict.{type Dict}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string

// ============================================================================
// Cache Types
// ============================================================================

/// Cache entry with TTL
pub type CacheEntry(a) {
  CacheEntry(value: a, created_at: Int, last_accessed: Int, ttl_seconds: Int)
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
  CacheStats(size: Int, max_size: Int, hits: Int, misses: Int, hit_rate: Float)
}

// ============================================================================
// Cache Creation and Management
// ============================================================================

/// Create a new query cache with default settings
/// Default: 100 entries, 5 minute TTL
pub fn new() -> QueryCache(a) {
  QueryCache(
    entries: dict.new(),
    max_size: 100,
    default_ttl: 300,
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
      let age_seconds = { now - entry.created_at } / 1000
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
          let updated_entry = CacheEntry(..entry, last_accessed: now)
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
  )
}

// ============================================================================
// Cache Key Generation
// ============================================================================

/// Generate a cache key for search queries
pub fn search_key(query: String, limit: Int) -> String {
  "search:" <> string.lowercase(query) <> ":" <> int.to_string(limit)
}

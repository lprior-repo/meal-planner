/// In-memory query result caching for frequently accessed data
/// Implements LRU cache with TTL for search queries and dashboard data
/// Target: 10x speedup for popular queries, 50% DB load reduction
///
/// This module implements an OTP GenServer actor for thread-safe caching
import gleam/dict.{type Dict}
import gleam/dynamic
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervision
import gleam/string
import pog

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

/// Generate a cache key for filtered search queries
pub fn search_filtered_key(
  query: String,
  vegetarian: Bool,
  bio: Bool,
  category: Option(String),
  limit: Int,
) -> String {
  let veg_str = case vegetarian {
    True -> "v"
    False -> "n"
  }
  let bio_str = case bio {
    True -> "b"
    False -> "n"
  }
  let cat_str = case category {
    Some(c) -> c
    None -> "all"
  }
  "search_filtered:"
  <> string.lowercase(query)
  <> ":"
  <> veg_str
  <> ":"
  <> bio_str
  <> ":"
  <> cat_str
  <> ":"
  <> int.to_string(limit)
}

/// Generate a cache key for dashboard data
pub fn dashboard_key(date: String, meal_type: Option(String)) -> String {
  let meal_str = case meal_type {
    Some(m) -> m
    None -> "all"
  }
  "dashboard:" <> date <> ":" <> meal_str
}

/// Generate a cache key for recent meals
pub fn recent_meals_key(limit: Int) -> String {
  "recent_meals:" <> int.to_string(limit)
}

/// Generate a cache key for food nutrients
pub fn food_nutrients_key(food_id: Int) -> String {
  "nutrients:" <> int.to_string(food_id)
}

/// Delete a key from the cache
pub fn delete(cache: QueryCache(a), key: String) -> QueryCache(a) {
  QueryCache(..cache, entries: dict.delete(cache.entries, key))
}

/// Reset statistics counters while keeping cache entries
pub fn reset_stats(cache: QueryCache(a)) -> QueryCache(a) {
  QueryCache(..cache, hits: 0, misses: 0)
}

// ============================================================================
// OTP Actor Implementation
// ============================================================================

/// Internal state for the cache actor
pub type State {
  State(cache: QueryCache(dynamic.Dynamic), db_conn: pog.Connection)
}

/// Messages the cache actor can receive
pub type Message {
  /// Get a value from the cache
  Get(key: String, reply_with: Subject(Option(dynamic.Dynamic)))
  /// Put a value in the cache with default TTL
  Put(key: String, value: dynamic.Dynamic, reply_with: Subject(Nil))
  /// Put a value with custom TTL
  PutWithTtl(
    key: String,
    value: dynamic.Dynamic,
    ttl: Int,
    reply_with: Subject(Nil),
  )
  /// Clear all cache entries
  Clear(reply_with: Subject(Nil))
  /// Get cache statistics
  GetStats(reply_with: Subject(CacheStats))
  /// Shutdown the actor
  Shutdown
}

/// Start the cache actor with database connection
pub fn start(db_conn: pog.Connection) -> actor.StartResult(Subject(Message)) {
  let initial_state = State(cache: new(), db_conn: db_conn)

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start
}

/// Create a child specification for supervision
pub fn supervised(
  db_conn: pog.Connection,
) -> supervision.ChildSpecification(Subject(Message)) {
  supervision.worker(fn() { start(db_conn) })
}

/// Handle incoming messages
fn handle_message(state: State, message: Message) -> actor.Next(State, Message) {
  case message {
    Get(key, reply_with) -> {
      let #(new_cache, result) = get(state.cache, key)
      process.send(reply_with, result)
      actor.continue(State(..state, cache: new_cache))
    }

    Put(key, value, reply_with) -> {
      let new_cache = put(state.cache, key, value)
      process.send(reply_with, Nil)
      actor.continue(State(..state, cache: new_cache))
    }

    PutWithTtl(key, value, ttl, reply_with) -> {
      let new_cache = put_with_ttl(state.cache, key, value, ttl)
      process.send(reply_with, Nil)
      actor.continue(State(..state, cache: new_cache))
    }

    Clear(reply_with) -> {
      let new_cache = clear(state.cache)
      process.send(reply_with, Nil)
      actor.continue(State(..state, cache: new_cache))
    }

    GetStats(reply_with) -> {
      let stats = get_stats(state.cache)
      process.send(reply_with, stats)
      actor.continue(state)
    }

    Shutdown -> {
      actor.stop()
    }
  }
}

// ============================================================================
// Client API
// ============================================================================

/// Get a value from the cache (sync call)
pub fn cache_get(
  actor: Subject(Message),
  key: String,
) -> Option(dynamic.Dynamic) {
  process.call(actor, 1000, fn(reply) { Get(key, reply) })
}

/// Put a value in the cache (async)
pub fn cache_put(
  actor: Subject(Message),
  key: String,
  value: dynamic.Dynamic,
) -> Nil {
  process.call(actor, 1000, fn(reply) { Put(key, value, reply) })
}

/// Put a value with custom TTL (async)
pub fn cache_put_with_ttl(
  actor: Subject(Message),
  key: String,
  value: dynamic.Dynamic,
  ttl: Int,
) -> Nil {
  process.call(actor, 1000, fn(reply) { PutWithTtl(key, value, ttl, reply) })
}

/// Clear the cache
pub fn cache_clear(actor: Subject(Message)) -> Nil {
  process.call(actor, 1000, fn(reply) { Clear(reply) })
}

/// Get cache statistics
pub fn cache_stats(actor: Subject(Message)) -> CacheStats {
  process.call(actor, 1000, fn(reply) { GetStats(reply) })
}

/// Shutdown the cache actor
pub fn cache_shutdown(actor: Subject(Message)) -> Nil {
  process.send(actor, Shutdown)
}

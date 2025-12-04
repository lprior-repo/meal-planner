/// In-memory TTL-based cache for search results
///
/// This module provides a simple time-to-live (TTL) based caching layer
/// for expensive database operations like food searches and recipe queries.
///
/// Cache entries expire after their TTL and are automatically cleaned up.
/// The cache uses Gleam's Dict for O(1) lookups.
import gleam/dict.{type Dict}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string

/// Cache entry with value and expiration timestamp
pub type CacheEntry(value) {
  CacheEntry(value: value, expires_at: Int)
}

/// In-memory cache with TTL support
pub type Cache(value) {
  Cache(entries: Dict(String, CacheEntry(value)))
}

/// Cache statistics for monitoring
pub type CacheStats {
  CacheStats(
    total_entries: Int,
    expired_entries: Int,
    hit_rate: Float,
    total_hits: Int,
    total_misses: Int,
  )
}

/// Create a new empty cache
pub fn new() -> Cache(a) {
  Cache(entries: dict.new())
}

/// Get current Unix timestamp in seconds
fn now() -> Int {
  // Use Erlang's system time in seconds
  system_time_seconds()
}

@external(erlang, "erlang", "system_time")
fn system_time_seconds() -> Int

/// Generate cache key from query parameters
/// This ensures consistent keys for the same query
pub fn make_key(prefix: String, query: String, limit: Int) -> String {
  prefix <> ":" <> query <> ":" <> int.to_string(limit)
}

/// Get a value from the cache if it exists and hasn't expired
/// Returns None if the key doesn't exist or has expired
pub fn get(cache: Cache(a), key: String) -> #(Cache(a), Option(a)) {
  let current_time = now()

  case dict.get(cache.entries, key) {
    Ok(entry) -> {
      // Check if entry has expired
      case entry.expires_at > current_time {
        True -> #(cache, Some(entry.value))
        False -> {
          // Entry expired, remove it and return None
          let cleaned_cache = Cache(entries: dict.delete(cache.entries, key))
          #(cleaned_cache, None)
        }
      }
    }
    Error(_) -> #(cache, None)
  }
}

/// Set a value in the cache with a TTL in seconds
/// If the key already exists, it will be overwritten
pub fn set(cache: Cache(a), key: String, value: a, ttl_seconds: Int) -> Cache(a) {
  let expires_at = now() + ttl_seconds
  let entry = CacheEntry(value: value, expires_at: expires_at)
  Cache(entries: dict.insert(cache.entries, key, entry))
}

/// Invalidate (remove) a specific key from the cache
pub fn invalidate(cache: Cache(a), key: String) -> Cache(a) {
  Cache(entries: dict.delete(cache.entries, key))
}

/// Invalidate all keys matching a prefix pattern
/// Useful for invalidating all related queries (e.g., all food searches)
pub fn invalidate_prefix(cache: Cache(a), prefix: String) -> Cache(a) {
  let filtered_entries =
    dict.filter(cache.entries, fn(key, _entry) { !starts_with(key, prefix) })
  Cache(entries: filtered_entries)
}

/// Clear all entries from the cache
pub fn clear(cache: Cache(a)) -> Cache(a) {
  Cache(entries: dict.new())
}

/// Remove all expired entries from the cache
/// Returns the cleaned cache and the number of entries removed
pub fn cleanup_expired(cache: Cache(a)) -> #(Cache(a), Int) {
  let current_time = now()
  let before_size = dict.size(cache.entries)

  let cleaned_entries =
    dict.filter(cache.entries, fn(_key, entry) {
      entry.expires_at > current_time
    })

  let after_size = dict.size(cleaned_entries)
  let removed = before_size - after_size

  #(Cache(entries: cleaned_entries), removed)
}

/// Get the number of entries currently in the cache
/// Note: This includes expired entries until cleanup is called
pub fn size(cache: Cache(a)) -> Int {
  dict.size(cache.entries)
}

/// Check if the cache is empty
pub fn is_empty(cache: Cache(a)) -> Bool {
  dict.is_empty(cache.entries)
}

/// Check if a key exists in the cache (regardless of expiration)
pub fn has_key(cache: Cache(a), key: String) -> Bool {
  case dict.get(cache.entries, key) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Get cache statistics for monitoring
/// This includes hit/miss tracking which would need to be implemented
/// in the calling code
pub fn stats(cache: Cache(a)) -> CacheStats {
  let total = dict.size(cache.entries)
  let current_time = now()

  let expired =
    dict.fold(cache.entries, 0, fn(acc, _key, entry) {
      case entry.expires_at <= current_time {
        True -> acc + 1
        False -> acc
      }
    })

  // Hit rate would be tracked externally
  CacheStats(
    total_entries: total,
    expired_entries: expired,
    hit_rate: 0.0,
    total_hits: 0,
    total_misses: 0,
  )
}

/// Helper function to check if a string starts with a prefix
fn starts_with(str: String, prefix: String) -> Bool {
  string.starts_with(str, prefix)
}

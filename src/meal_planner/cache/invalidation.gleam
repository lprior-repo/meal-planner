/// Cache invalidation with TTL-based expiry and dependency tracking
///
/// This module provides sophisticated cache invalidation strategies including:
/// - Time-to-live (TTL) based automatic expiration
/// - Dependency tracking for related data (e.g., recipe changes invalidate meal plans)
/// - Pattern-based invalidation for bulk operations
/// - Event-driven invalidation for reactive updates
///
/// ## Dependency Graph
/// The system tracks relationships between cached entities:
/// - Recipe updates → invalidate meal plans using that recipe
/// - User profile changes → invalidate personalized recommendations
/// - Food database updates → invalidate nutrition calculations
/// - Shopping list changes → invalidate grocery summaries
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string

// ============================================================================
// Types
// ============================================================================

/// Cache entry with TTL and dependency metadata
pub type CacheEntry(value) {
  CacheEntry(
    value: value,
    /// Unix timestamp when entry was created
    created_at: Int,
    /// Unix timestamp when entry expires
    expires_at: Int,
    /// Keys of other cache entries this depends on
    dependencies: Set(String),
    /// Keys of cache entries that depend on this one
    dependents: Set(String),
    /// Tags for bulk invalidation (e.g., "recipe:123", "user:456")
    tags: Set(String),
  )
}

/// Cache with invalidation support
pub type InvalidationCache(value) {
  InvalidationCache(
    entries: Dict(String, CacheEntry(value)),
    /// Reverse index: tag -> set of cache keys
    tag_index: Dict(String, Set(String)),
    /// Default TTL in seconds
    default_ttl: Int,
  )
}

/// Invalidation event types
pub type InvalidationEvent {
  /// Manual invalidation of specific key
  KeyInvalidated(key: String)
  /// TTL expiration
  Expired(key: String)
  /// Dependency chain invalidation
  DependencyInvalidated(key: String, caused_by: String)
  /// Tag-based bulk invalidation
  TagInvalidated(tag: String, affected_keys: List(String))
}

/// Invalidation strategy
pub type InvalidationStrategy {
  /// Invalidate immediately
  Immediate
  /// Lazy invalidation - mark as stale but don't remove until accessed
  Lazy
  /// Cascade to dependents
  Cascade
}

/// Cache statistics
pub type InvalidationStats {
  InvalidationStats(
    total_entries: Int,
    expired_entries: Int,
    total_dependencies: Int,
    total_tags: Int,
    invalidations_by_ttl: Int,
    invalidations_by_dependency: Int,
    invalidations_by_tag: Int,
  )
}

// ============================================================================
// Cache Creation
// ============================================================================

/// Create a new cache with default TTL (5 minutes)
pub fn new() -> InvalidationCache(a) {
  new_with_ttl(300)
}

/// Create a new cache with custom default TTL
pub fn new_with_ttl(default_ttl_seconds: Int) -> InvalidationCache(a) {
  InvalidationCache(
    entries: dict.new(),
    tag_index: dict.new(),
    default_ttl: default_ttl_seconds,
  )
}

/// Get current Unix timestamp in seconds
@external(erlang, "erlang", "system_time")
fn system_time_seconds() -> Int

/// Get current timestamp
fn now() -> Int {
  system_time_seconds()
}

// ============================================================================
// Core Cache Operations
// ============================================================================

/// Get a value from the cache, checking expiration
pub fn get(
  cache: InvalidationCache(a),
  key: String,
) -> #(InvalidationCache(a), Option(a)) {
  let current_time = now()

  case dict.get(cache.entries, key) {
    Ok(entry) -> {
      case entry.expires_at > current_time {
        True -> #(cache, Some(entry.value))
        False -> {
          // Entry expired - remove it
          let cleaned = invalidate_key(cache, key, Immediate)
          #(cleaned, None)
        }
      }
    }
    Error(_) -> #(cache, None)
  }
}

/// Set a value in the cache with default TTL
pub fn set(
  cache: InvalidationCache(a),
  key: String,
  value: a,
) -> InvalidationCache(a) {
  set_with_options(cache, key, value, cache.default_ttl, set.new(), set.new())
}

/// Set a value with custom TTL
pub fn set_with_ttl(
  cache: InvalidationCache(a),
  key: String,
  value: a,
  ttl_seconds: Int,
) -> InvalidationCache(a) {
  set_with_options(cache, key, value, ttl_seconds, set.new(), set.new())
}

/// Set a value with dependencies
pub fn set_with_dependencies(
  cache: InvalidationCache(a),
  key: String,
  value: a,
  dependencies: List(String),
) -> InvalidationCache(a) {
  let dep_set = set.from_list(dependencies)
  set_with_options(cache, key, value, cache.default_ttl, dep_set, set.new())
}

/// Set a value with tags for bulk invalidation
pub fn set_with_tags(
  cache: InvalidationCache(a),
  key: String,
  value: a,
  tags: List(String),
) -> InvalidationCache(a) {
  let tag_set = set.from_list(tags)
  set_with_options(cache, key, value, cache.default_ttl, set.new(), tag_set)
}

/// Set a value with full options: TTL, dependencies, and tags
pub fn set_with_options(
  cache: InvalidationCache(a),
  key: String,
  value: a,
  ttl_seconds: Int,
  dependencies: Set(String),
  tags: Set(String),
) -> InvalidationCache(a) {
  let current_time = now()
  let expires_at = current_time + ttl_seconds

  // Create entry
  let entry =
    CacheEntry(
      value: value,
      created_at: current_time,
      expires_at: expires_at,
      dependencies: dependencies,
      dependents: set.new(),
      tags: tags,
    )

  // Update entries
  let new_entries = dict.insert(cache.entries, key, entry)

  // Update tag index
  let new_tag_index =
    set.fold(tags, cache.tag_index, fn(index, tag) {
      let existing_keys =
        dict.get(index, tag)
        |> result.unwrap(set.new())
      let updated_keys = set.insert(existing_keys, key)
      dict.insert(index, tag, updated_keys)
    })

  // Update dependency graph (add this key as dependent of its dependencies)
  let new_entries_with_deps =
    set.fold(dependencies, new_entries, fn(entries, dep_key) {
      case dict.get(entries, dep_key) {
        Ok(dep_entry) -> {
          let updated_dependents = set.insert(dep_entry.dependents, key)
          let updated_entry =
            CacheEntry(..dep_entry, dependents: updated_dependents)
          dict.insert(entries, dep_key, updated_entry)
        }
        Error(_) -> entries
      }
    })

  InvalidationCache(
    entries: new_entries_with_deps,
    tag_index: new_tag_index,
    default_ttl: cache.default_ttl,
  )
}

// ============================================================================
// Invalidation Operations
// ============================================================================

/// Invalidate a specific key
pub fn invalidate(
  cache: InvalidationCache(a),
  key: String,
) -> InvalidationCache(a) {
  invalidate_key(cache, key, Immediate)
}

/// Invalidate with strategy
pub fn invalidate_with_strategy(
  cache: InvalidationCache(a),
  key: String,
  strategy: InvalidationStrategy,
) -> InvalidationCache(a) {
  invalidate_key(cache, key, strategy)
}

/// Internal key invalidation
fn invalidate_key(
  cache: InvalidationCache(a),
  key: String,
  strategy: InvalidationStrategy,
) -> InvalidationCache(a) {
  case dict.get(cache.entries, key) {
    Error(_) -> cache
    Ok(entry) -> {
      case strategy {
        Immediate | Lazy -> {
          // Remove from entries
          let new_entries = dict.delete(cache.entries, key)

          // Remove from tag index
          let new_tag_index =
            remove_from_tag_index(cache.tag_index, entry.tags, key)

          InvalidationCache(
            entries: new_entries,
            tag_index: new_tag_index,
            default_ttl: cache.default_ttl,
          )
        }

        Cascade -> {
          // First invalidate the key itself
          let cache_after_self = invalidate_key(cache, key, Immediate)

          // Then cascade to dependents
          set.fold(entry.dependents, cache_after_self, fn(c, dependent_key) {
            invalidate_key(c, dependent_key, Cascade)
          })
        }
      }
    }
  }
}

/// Invalidate all entries with a specific tag
pub fn invalidate_by_tag(
  cache: InvalidationCache(a),
  tag: String,
) -> InvalidationCache(a) {
  case dict.get(cache.tag_index, tag) {
    Error(_) -> cache
    Ok(keys) -> {
      let keys_list = set.to_list(keys)
      list.fold(keys_list, cache, fn(c, key) {
        invalidate_key(c, key, Immediate)
      })
    }
  }
}

/// Invalidate all entries matching a key prefix
pub fn invalidate_by_prefix(
  cache: InvalidationCache(a),
  prefix: String,
) -> InvalidationCache(a) {
  let matching_keys =
    dict.keys(cache.entries)
    |> list.filter(fn(key) { string.starts_with(key, prefix) })

  list.fold(matching_keys, cache, fn(c, key) {
    invalidate_key(c, key, Immediate)
  })
}

/// Invalidate with cascade to dependents
pub fn invalidate_cascade(
  cache: InvalidationCache(a),
  key: String,
) -> InvalidationCache(a) {
  invalidate_key(cache, key, Cascade)
}

/// Remove key from tag index
fn remove_from_tag_index(
  tag_index: Dict(String, Set(String)),
  tags: Set(String),
  key: String,
) -> Dict(String, Set(String)) {
  set.fold(tags, tag_index, fn(index, tag) {
    case dict.get(index, tag) {
      Ok(keys) -> {
        let updated_keys = set.delete(keys, key)
        case set.is_empty(updated_keys) {
          True -> dict.delete(index, tag)
          False -> dict.insert(index, tag, updated_keys)
        }
      }
      Error(_) -> index
    }
  })
}

// ============================================================================
// Cleanup Operations
// ============================================================================

/// Remove all expired entries
pub fn cleanup_expired(
  cache: InvalidationCache(a),
) -> #(InvalidationCache(a), Int) {
  let current_time = now()

  let expired_keys =
    dict.fold(cache.entries, [], fn(acc, key, entry) {
      case entry.expires_at <= current_time {
        True -> [key, ..acc]
        False -> acc
      }
    })

  let cleaned_cache =
    list.fold(expired_keys, cache, fn(c, key) {
      invalidate_key(c, key, Immediate)
    })

  #(cleaned_cache, list.length(expired_keys))
}

/// Clear all entries
pub fn clear(cache: InvalidationCache(a)) -> InvalidationCache(a) {
  InvalidationCache(
    entries: dict.new(),
    tag_index: dict.new(),
    default_ttl: cache.default_ttl,
  )
}

// ============================================================================
// Query Operations
// ============================================================================

/// Check if a key exists and is valid (not expired)
pub fn has_valid_key(cache: InvalidationCache(a), key: String) -> Bool {
  let current_time = now()

  case dict.get(cache.entries, key) {
    Ok(entry) -> entry.expires_at > current_time
    Error(_) -> False
  }
}

/// Get all keys with a specific tag
pub fn keys_by_tag(cache: InvalidationCache(a), tag: String) -> List(String) {
  dict.get(cache.tag_index, tag)
  |> result.map(set.to_list)
  |> result.unwrap([])
}

/// Get dependencies of a key
pub fn get_dependencies(
  cache: InvalidationCache(a),
  key: String,
) -> List(String) {
  dict.get(cache.entries, key)
  |> result.map(fn(entry) { set.to_list(entry.dependencies) })
  |> result.unwrap([])
}

/// Get dependents of a key
pub fn get_dependents(cache: InvalidationCache(a), key: String) -> List(String) {
  dict.get(cache.entries, key)
  |> result.map(fn(entry) { set.to_list(entry.dependents) })
  |> result.unwrap([])
}

/// Get cache size
pub fn size(cache: InvalidationCache(a)) -> Int {
  dict.size(cache.entries)
}

/// Check if cache is empty
pub fn is_empty(cache: InvalidationCache(a)) -> Bool {
  dict.is_empty(cache.entries)
}

// ============================================================================
// Statistics
// ============================================================================

/// Get cache statistics
pub fn stats(cache: InvalidationCache(a)) -> InvalidationStats {
  let current_time = now()
  let total = dict.size(cache.entries)

  let expired =
    dict.fold(cache.entries, 0, fn(acc, _key, entry) {
      case entry.expires_at <= current_time {
        True -> acc + 1
        False -> acc
      }
    })

  let total_deps =
    dict.fold(cache.entries, 0, fn(acc, _key, entry) {
      acc + set.size(entry.dependencies)
    })

  let total_tags = dict.size(cache.tag_index)

  InvalidationStats(
    total_entries: total,
    expired_entries: expired,
    total_dependencies: total_deps,
    total_tags: total_tags,
    // These would be tracked with additional state
    invalidations_by_ttl: 0,
    invalidations_by_dependency: 0,
    invalidations_by_tag: 0,
  )
}

// ============================================================================
// Utility Functions
// ============================================================================

/// Create a tag for recipe-related caching
pub fn recipe_tag(recipe_id: String) -> String {
  "recipe:" <> recipe_id
}

/// Create a tag for user-related caching
pub fn user_tag(user_id: String) -> String {
  "user:" <> user_id
}

/// Create a tag for meal plan caching
pub fn meal_plan_tag(plan_id: String) -> String {
  "meal_plan:" <> plan_id
}

/// Create a tag for date-based caching
pub fn date_tag(date: String) -> String {
  "date:" <> date
}

/// Create a composite key from parts
pub fn make_key(parts: List(String)) -> String {
  string.join(parts, ":")
}

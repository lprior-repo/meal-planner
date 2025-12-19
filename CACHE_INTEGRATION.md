# CLI Cache Integration Guide

## Overview

The `meal_planner/cli/cache` module provides persistent file-based caching for CLI operations with TTL support, pattern-based invalidation, and offline mode detection.

## Architecture

- **Storage**: `~/.meal-planner/cache/` (fallback: `/tmp/meal-planner-cache`)
- **Format**: JSON files with `{value: String, expires_at: Int}`
- **Key Sanitization**: Replaces `:`, `/`, `\` with `_` for filesystem safety

## Basic Usage

```gleam
import meal_planner/cli/cache
import gleam/option.{Some, None}

pub fn search_foods(query: String) -> Result(String, String) {
  let cache_dir = cache.default_cache_dir()
  let cache_key = "food:search:" <> query

  // Try to get cached result
  case cache.get_cached(cache_dir, cache_key) {
    Some(cached_value) -> {
      // Return cached data (consider adding offline warning)
      Ok(cached_value)
    }
    None -> {
      // Make API call
      case api.search_foods(query) {
        Ok(result) -> {
          // Cache the result for 24 hours
          let _ = cache.cache_response(
            cache_dir,
            cache_key,
            result,
            cache.food_search_ttl_hours,
          )
          Ok(result)
        }
        Error(err) -> Error(err)
      }
    }
  }
}
```

## TTL Configurations

```gleam
cache.food_search_ttl_hours = 24   // Food searches: 24 hours
cache.recipe_ttl_hours = 24        // Recipes: 24 hours
cache.diary_ttl_hours = 4          // Diary/personal data: 4 hours
cache.usda_food_ttl_hours = 720    // USDA foods: 30 days
```

## Offline Mode Support

```gleam
import meal_planner/cli/cache

pub fn handle_command(cmd: String) -> Result(String, String) {
  case cache.is_offline() {
    True -> {
      io.println("⚠️  Offline mode: showing cached data only")
      // Only return cached data, don't attempt network calls
      get_from_cache_only(cmd)
    }
    False -> {
      // Normal operation with cache + network
      normal_operation(cmd)
    }
  }
}
```

## Cache Invalidation

### Clear by Pattern

```gleam
// Clear all food search caches
cache.clear_cache(cache_dir, "food:")

// Clear all recipe caches
cache.clear_cache(cache_dir, "recipe:")

// Clear specific search
cache.clear_cache(cache_dir, "food:search:chicken")
```

### Auto-Cleanup on Startup

```gleam
pub fn main() {
  let cache_dir = cache.default_cache_dir()

  // Cleanup expired entries on startup
  case cache.cleanup_expired(cache_dir) {
    Ok(count) -> io.println("Cleaned up " <> int.to_string(count) <> " expired cache entries")
    Error(_) -> Nil
  }

  // Run CLI application
  run_cli()
}
```

## --refresh Flag Implementation

```gleam
pub fn handle_search(query: String, refresh: Bool) -> Result(String, String) {
  let cache_dir = cache.default_cache_dir()
  let cache_key = "food:search:" <> query

  case refresh {
    True -> {
      // Bypass cache, make fresh API call
      make_api_call_and_cache(cache_dir, cache_key, query)
    }
    False -> {
      // Normal cache-first behavior
      case cache.get_cached(cache_dir, cache_key) {
        Some(value) -> Ok(value)
        None -> make_api_call_and_cache(cache_dir, cache_key, query)
      }
    }
  }
}
```

## Key Naming Conventions

Use prefixes for easy pattern-based invalidation:

```gleam
"food:search:{query}:{limit}"       // Food searches
"food:usda:{id}"                    // USDA food details
"recipe:search:{query}"             // Recipe searches
"recipe:detail:{id}"                // Recipe details
"diary:entry:{date}"                // Diary entries
"diary:summary:{date_range}"        // Diary summaries
```

## Error Handling

All cache operations return `Result` types:

```gleam
// cache_response returns Result(Nil, String)
case cache.cache_response(cache_dir, key, value, 24) {
  Ok(_) -> io.println("Cached successfully")
  Error(msg) -> io.println("Cache error: " <> msg)
}

// clear_cache returns Result(Int, String) - count of deleted entries
case cache.clear_cache(cache_dir, "food:") {
  Ok(count) -> io.println("Cleared " <> int.to_string(count) <> " entries")
  Error(msg) -> io.println("Clear error: " <> msg)
}

// cleanup_expired returns Result(Int, String)
case cache.cleanup_expired(cache_dir) {
  Ok(count) -> io.println("Removed " <> int.to_string(count) <> " expired entries")
  Error(msg) -> io.println("Cleanup error: " <> msg)
}
```

## Testing

The cache module includes comprehensive tests in `test/cli/cache_test.gleam`:

```bash
# Run cache tests
gleam test --target erlang

# The tests cover:
# - Directory creation
# - Cache and retrieval
# - Expiration handling
# - Pattern-based clearing
# - Auto-cleanup of expired entries
# - Network connectivity detection
```

## Integration Checklist

- [ ] Add cache directory creation on CLI startup
- [ ] Add `--refresh` flag to bypass cache
- [ ] Add auto-cleanup on startup
- [ ] Add offline mode detection and warnings
- [ ] Update command handlers to use cache
- [ ] Add cache statistics/monitoring
- [ ] Document cache behavior in CLI help

## Performance Considerations

- **Cache hit**: O(1) file read + JSON decode
- **Cache miss**: O(1) file check
- **Pattern clear**: O(n) where n = total cache entries
- **Cleanup expired**: O(n) where n = total cache entries

Recommendation: Run `cleanup_expired()` on startup to maintain cache size.

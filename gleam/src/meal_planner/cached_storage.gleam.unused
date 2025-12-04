/// Cached storage layer for performance optimization
///
/// This module wraps the storage module's database operations with
/// an in-memory TTL-based cache to reduce database load and improve
/// response times for frequently accessed data.
///
/// Cache TTLs:
/// - Food searches: 5 minutes (300 seconds)
/// - Recipe queries: 10 minutes (600 seconds)

import gleam/int
import gleam/option.{None, Some}
import meal_planner/cache
import meal_planner/storage.{type StorageError, type UsdaFood}
import meal_planner/types.{type Recipe}
import pog

/// Cache TTL constants
const food_search_ttl = 300

const recipe_query_ttl = 600

/// Cached storage state with separate caches for different data types
/// Note: food_search_cache uses storage_optimized.SearchCache for database-level optimizations
pub type CachedStorage {
  CachedStorage(
    food_cache: cache.Cache(List(UsdaFood)),
    recipe_cache: cache.Cache(List(Recipe)),
    recipe_by_id_cache: cache.Cache(Recipe),
    food_search_cache: storage_optimized.SearchCache,
  )
}

/// Create a new cached storage instance
pub fn new() -> CachedStorage {
  CachedStorage(
    food_cache: cache.new(),
    recipe_cache: cache.new(),
    recipe_by_id_cache: cache.new(),
    food_search_cache: storage_optimized.new_search_cache(),
  )
}

/// Search for foods with optimized caching using storage_optimized
/// Uses covering indexes and database-level query cache for 10x speedup
pub fn search_foods(
  cached: CachedStorage,
  conn: pog.Connection,
  query: String,
  limit: Int,
) -> #(CachedStorage, Result(List(UsdaFood), StorageError)) {
  // Use storage_optimized for database-level caching and covering indexes
  let #(updated_search_cache, result) =
    storage_optimized.search_foods_cached(
      conn,
      cached.food_search_cache,
      query,
      limit,
    )

  let updated_cached =
    CachedStorage(..cached, food_search_cache: updated_search_cache)

  #(updated_cached, result)
}

/// Search for foods with filters using optimized partial indexes
/// Uses idx_foods_verified_search or idx_foods_branded_search for 5-10x speedup
pub fn search_foods_filtered(
  cached: CachedStorage,
  conn: pog.Connection,
  query: String,
  filters: types.SearchFilters,
  limit: Int,
) -> #(CachedStorage, Result(List(UsdaFood), StorageError)) {
  // Use storage_optimized for database-level caching and partial indexes
  let #(updated_search_cache, result) =
    storage_optimized.search_foods_filtered_cached(
      conn,
      cached.food_search_cache,
      query,
      filters,
      limit,
    )

  let updated_cached =
    CachedStorage(..cached, food_search_cache: updated_search_cache)

  #(updated_cached, result)
}

/// Get all recipes with caching (10-minute TTL)
/// Cache key: "recipes_all:0"
pub fn get_all_recipes(
  cached: CachedStorage,
  conn: pog.Connection,
) -> #(CachedStorage, Result(List(Recipe), StorageError)) {
  let cache_key = cache.make_key("recipes_all", "", 0)

  let #(updated_recipe_cache, cached_result) =
    cache.get(cached.recipe_cache, cache_key)

  case cached_result {
    Some(recipes) -> {
      let updated_cached =
        CachedStorage(..cached, recipe_cache: updated_recipe_cache)
      #(updated_cached, Ok(recipes))
    }
    None -> {
      case storage.get_all_recipes(conn) {
        Ok(recipes) -> {
          let new_cache =
            cache.set(
              updated_recipe_cache,
              cache_key,
              recipes,
              recipe_query_ttl,
            )
          let updated_cached = CachedStorage(..cached, recipe_cache: new_cache)
          #(updated_cached, Ok(recipes))
        }
        Error(e) -> {
          let updated_cached =
            CachedStorage(..cached, recipe_cache: updated_recipe_cache)
          #(updated_cached, Error(e))
        }
      }
    }
  }
}

/// Get recipes by category with caching (10-minute TTL)
/// Cache key format: "recipes_category:{category}:0"
pub fn get_recipes_by_category(
  cached: CachedStorage,
  conn: pog.Connection,
  category: String,
) -> #(CachedStorage, Result(List(Recipe), StorageError)) {
  let cache_key = cache.make_key("recipes_category", category, 0)

  let #(updated_recipe_cache, cached_result) =
    cache.get(cached.recipe_cache, cache_key)

  case cached_result {
    Some(recipes) -> {
      let updated_cached =
        CachedStorage(..cached, recipe_cache: updated_recipe_cache)
      #(updated_cached, Ok(recipes))
    }
    None -> {
      case storage.get_recipes_by_category(conn, category) {
        Ok(recipes) -> {
          let new_cache =
            cache.set(
              updated_recipe_cache,
              cache_key,
              recipes,
              recipe_query_ttl,
            )
          let updated_cached = CachedStorage(..cached, recipe_cache: new_cache)
          #(updated_cached, Ok(recipes))
        }
        Error(e) -> {
          let updated_cached =
            CachedStorage(..cached, recipe_cache: updated_recipe_cache)
          #(updated_cached, Error(e))
        }
      }
    }
  }
}

/// Get recipe by ID with caching (10-minute TTL)
/// Cache key format: "recipe_by_id:{id}:0"
pub fn get_recipe_by_id(
  cached: CachedStorage,
  conn: pog.Connection,
  recipe_id: String,
) -> #(CachedStorage, Result(Recipe, StorageError)) {
  let cache_key = cache.make_key("recipe_by_id", recipe_id, 0)

  let #(updated_cache, cached_result) =
    cache.get(cached.recipe_by_id_cache, cache_key)

  case cached_result {
    Some(recipe) -> {
      let updated_cached =
        CachedStorage(..cached, recipe_by_id_cache: updated_cache)
      #(updated_cached, Ok(recipe))
    }
    None -> {
      case storage.get_recipe_by_id(conn, recipe_id) {
        Ok(recipe) -> {
          let new_cache =
            cache.set(updated_cache, cache_key, recipe, recipe_query_ttl)
          let updated_cached =
            CachedStorage(..cached, recipe_by_id_cache: new_cache)
          #(updated_cached, Ok(recipe))
        }
        Error(e) -> {
          let updated_cached =
            CachedStorage(..cached, recipe_by_id_cache: updated_cache)
          #(updated_cached, Error(e))
        }
      }
    }
  }
}

/// Invalidate food search cache
/// Call this when food data is modified
pub fn invalidate_food_cache(cached: CachedStorage) -> CachedStorage {
  let cleared_cache = cache.invalidate_prefix(cached.food_cache, "food_search")
  let cleared_search_cache = storage_optimized.clear_cache(cached.food_search_cache)
  CachedStorage(..cached, food_cache: cleared_cache, food_search_cache: cleared_search_cache)
}

/// Invalidate recipe cache
/// Call this when recipe data is modified
pub fn invalidate_recipe_cache(cached: CachedStorage) -> CachedStorage {
  let cleared_list_cache =
    cache.invalidate_prefix(cached.recipe_cache, "recipes_")
  let cleared_id_cache =
    cache.invalidate_prefix(cached.recipe_by_id_cache, "recipe_by_id")
  CachedStorage(
    ..cached,
    recipe_cache: cleared_list_cache,
    recipe_by_id_cache: cleared_id_cache,
  )
}

/// Invalidate a specific recipe by ID
pub fn invalidate_recipe_by_id(
  cached: CachedStorage,
  recipe_id: String,
) -> CachedStorage {
  let cache_key = cache.make_key("recipe_by_id", recipe_id, 0)
  let updated_cache = cache.invalidate(cached.recipe_by_id_cache, cache_key)
  // Also invalidate recipe lists as they may contain this recipe
  let cleared_list_cache = cache.clear(cached.recipe_cache)
  CachedStorage(
    ..cached,
    recipe_cache: cleared_list_cache,
    recipe_by_id_cache: updated_cache,
  )
}

/// Clear all caches
pub fn clear_all(cached: CachedStorage) -> CachedStorage {
  CachedStorage(
    food_cache: cache.clear(cached.food_cache),
    recipe_cache: cache.clear(cached.recipe_cache),
    recipe_by_id_cache: cache.clear(cached.recipe_by_id_cache),
    food_search_cache: storage_optimized.clear_cache(cached.food_search_cache),
  )
}

/// Cleanup expired entries from all caches
/// Returns the updated storage and total number of entries removed
pub fn cleanup_expired(cached: CachedStorage) -> #(CachedStorage, Int) {
  let #(cleaned_food, food_removed) = cache.cleanup_expired(cached.food_cache)
  let #(cleaned_recipe, recipe_removed) =
    cache.cleanup_expired(cached.recipe_cache)
  let #(cleaned_recipe_id, recipe_id_removed) =
    cache.cleanup_expired(cached.recipe_by_id_cache)

  let total_removed = food_removed + recipe_removed + recipe_id_removed

  let cleaned =
    CachedStorage(
      food_cache: cleaned_food,
      recipe_cache: cleaned_recipe,
      recipe_by_id_cache: cleaned_recipe_id,
    )

  #(cleaned, total_removed)
}

/// Get cache statistics
pub fn stats(cached: CachedStorage) -> String {
  let food_stats = cache.stats(cached.food_cache)
  let recipe_stats = cache.stats(cached.recipe_cache)
  let recipe_id_stats = cache.stats(cached.recipe_by_id_cache)
  let search_cache_stats = storage_optimized.get_cache_stats(cached.food_search_cache)

  "Cache Statistics:\n"
  <> "  Food Cache: "
  <> int.to_string(food_stats.total_entries)
  <> " total, "
  <> int.to_string(food_stats.expired_entries)
  <> " expired\n"
  <> "  Recipe List Cache: "
  <> int.to_string(recipe_stats.total_entries)
  <> " total, "
  <> int.to_string(recipe_stats.expired_entries)
  <> " expired\n"
  <> "  Recipe ID Cache: "
  <> int.to_string(recipe_id_stats.total_entries)
  <> " total, "
  <> int.to_string(recipe_id_stats.expired_entries)
  <> " expired\n"
  <> "  Search Cache (Optimized): "
  <> int.to_string(search_cache_stats.size)
  <> " entries, "
  <> int.to_string(search_cache_stats.hits)
  <> " hits, "
  <> int.to_string(search_cache_stats.misses)
  <> " misses"
}

/// Build a unique filter key from SearchFilters
fn build_filter_key(filters: types.SearchFilters) -> String {
  let verified = case filters.verified_only {
    True -> "v1"
    False -> "v0"
  }
  let branded = case filters.branded_only {
    True -> "b1"
    False -> "b0"
  }
  let category = case filters.category {
    Some(cat) -> "c:" <> cat
    None -> "c:none"
  }
  verified <> ":" <> branded <> ":" <> category
}

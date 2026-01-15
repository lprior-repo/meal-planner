//! Nutrition Cache Layer
//!
//! This module provides caching for FatSecret food lookups to reduce API calls
//! and improve performance. The cache supports:
//!
//! - In-memory caching with configurable TTL
//! - LRU eviction when capacity is reached
//! - Cache statistics tracking
//! - Serialization for persistence
//!
//! # Cache Keys
//!
//! - Food ID: Direct lookup by FatSecret food ID
//! - Search query: Cached search results
//! - Ingredient name: Normalized ingredient to food mapping

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{Duration, Instant};

use super::errors::{SyncError, SyncResult};
use super::types::{FatSecretFood, NutritionData, FatSecretFoodId};

// =============================================================================
// CONFIGURATION
// =============================================================================

/// Cache configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CacheConfig {
    /// Maximum number of entries
    pub max_entries: usize,
    /// Time-to-live in seconds
    pub ttl_seconds: u64,
    /// Whether to track statistics
    pub track_stats: bool,
    /// Whether to log cache operations
    pub log_operations: bool,
}

impl Default for CacheConfig {
    fn default() -> Self {
        Self {
            max_entries: 1000,
            ttl_seconds: 3600, // 1 hour
            track_stats: true,
            log_operations: false,
        }
    }
}

impl CacheConfig {
    /// Create a cache config with a specific TTL in hours
    #[must_use]
    pub fn with_ttl_hours(hours: u64) -> Self {
        Self {
            ttl_seconds: hours * 3600,
            ..Self::default()
        }
    }

    /// Create a cache config for testing (short TTL)
    #[must_use]
    pub fn for_testing() -> Self {
        Self {
            max_entries: 100,
            ttl_seconds: 60,
            track_stats: true,
            log_operations: true,
        }
    }

    /// Validate configuration
    pub fn validate(&self) -> SyncResult<()> {
        if self.max_entries == 0 {
            return Err(SyncError::config_invalid(
                "max_entries",
                "Must be at least 1",
            ));
        }
        Ok(())
    }
}

// =============================================================================
// CACHE ENTRY
// =============================================================================

/// A cached entry with metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CacheEntry<T> {
    /// The cached value
    pub value: T,
    /// When the entry was created
    #[serde(skip)]
    created_at: Option<Instant>,
    /// When the entry was last accessed
    #[serde(skip)]
    last_accessed: Option<Instant>,
    /// Number of times accessed
    pub access_count: u64,
    /// TTL in seconds (for serialization)
    ttl_seconds: u64,
}

impl<T> CacheEntry<T> {
    /// Create a new cache entry
    pub fn new(value: T, ttl_seconds: u64) -> Self {
        let now = Instant::now();
        Self {
            value,
            created_at: Some(now),
            last_accessed: Some(now),
            access_count: 1,
            ttl_seconds,
        }
    }

    /// Check if the entry is expired
    #[must_use]
    pub fn is_expired(&self) -> bool {
        self.created_at
            .map_or(true, |created| {
                created.elapsed() > Duration::from_secs(self.ttl_seconds)
            })
    }

    /// Mark the entry as accessed
    pub fn touch(&mut self) {
        self.last_accessed = Some(Instant::now());
        self.access_count = self.access_count.saturating_add(1);
    }

    /// Get the age of the entry in seconds
    #[must_use]
    pub fn age_seconds(&self) -> u64 {
        self.created_at.map_or(0, |created| created.elapsed().as_secs())
    }

    /// Get time since last access in seconds
    #[must_use]
    pub fn idle_seconds(&self) -> u64 {
        self.last_accessed.map_or(0, |accessed| accessed.elapsed().as_secs())
    }
}

impl<T: Clone> CacheEntry<T> {
    /// Get the cached value (updates access time)
    pub fn get(&mut self) -> T {
        self.touch();
        self.value.clone()
    }
}

// =============================================================================
// CACHE STATISTICS
// =============================================================================

/// Cache statistics
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CacheStats {
    /// Number of cache hits
    pub hits: u64,
    /// Number of cache misses
    pub misses: u64,
    /// Number of entries inserted
    pub insertions: u64,
    /// Number of entries evicted
    pub evictions: u64,
    /// Number of entries expired
    pub expirations: u64,
    /// Current number of entries
    pub current_entries: usize,
    /// Total bytes used (estimated)
    pub bytes_used: usize,
}

impl CacheStats {
    /// Calculate hit rate
    #[must_use]
    #[allow(clippy::cast_precision_loss)] // u64 to f64 for hit rate percentage calculation
    pub fn hit_rate(&self) -> f64 {
        let total = self.hits + self.misses;
        if total == 0 {
            return 0.0;
        }
        self.hits as f64 / total as f64
    }

    /// Reset statistics
    pub fn reset(&mut self) {
        self.hits = 0;
        self.misses = 0;
        self.insertions = 0;
        self.evictions = 0;
        self.expirations = 0;
    }
}

// =============================================================================
// NUTRITION CACHE
// =============================================================================

/// Cache for nutrition data and food lookups
#[derive(Debug)]
pub struct NutritionCache {
    /// Configuration
    config: CacheConfig,
    /// Cached foods by ID
    foods_by_id: HashMap<String, CacheEntry<FatSecretFood>>,
    /// Cached nutrition by ingredient name
    nutrition_by_ingredient: HashMap<String, CacheEntry<NutritionData>>,
    /// Cached search results
    search_cache: HashMap<String, CacheEntry<Vec<FatSecretFood>>>,
    /// Cached ingredient-to-food mappings
    ingredient_mappings: HashMap<String, CacheEntry<FatSecretFoodId>>,
    /// Statistics
    stats: CacheStats,
}

impl NutritionCache {
    /// Create a new cache with the given configuration
    #[must_use]
    pub fn new(config: CacheConfig) -> Self {
        Self {
            config,
            foods_by_id: HashMap::new(),
            nutrition_by_ingredient: HashMap::new(),
            search_cache: HashMap::new(),
            ingredient_mappings: HashMap::new(),
            stats: CacheStats::default(),
        }
    }

    /// Create a cache with default configuration
    #[must_use]
    pub fn with_defaults() -> Self {
        Self::new(CacheConfig::default())
    }

    // =========================================================================
    // FOOD BY ID
    // =========================================================================

    /// Get a food by ID from cache
    #[must_use]
    pub fn get_food(&mut self, food_id: &str) -> Option<FatSecretFood> {
        self.cleanup_expired_foods();

        if let Some(entry) = self.foods_by_id.get_mut(food_id) {
            if entry.is_expired() {
                self.foods_by_id.remove(food_id);
                if self.config.track_stats {
                    self.stats.expirations += 1;
                    self.stats.misses += 1;
                }
                return None;
            }
            if self.config.track_stats {
                self.stats.hits += 1;
            }
            return Some(entry.get());
        }

        if self.config.track_stats {
            self.stats.misses += 1;
        }
        None
    }

    /// Cache a food by ID
    pub fn put_food(&mut self, food_id: &str, food: FatSecretFood) {
        self.ensure_capacity();

        let entry = CacheEntry::new(food, self.config.ttl_seconds);
        self.foods_by_id.insert(food_id.to_string(), entry);

        if self.config.track_stats {
            self.stats.insertions += 1;
            self.stats.current_entries = self.total_entries();
        }
    }

    // =========================================================================
    // NUTRITION BY INGREDIENT
    // =========================================================================

    /// Get nutrition by ingredient name from cache
    #[must_use]
    pub fn get_nutrition(&mut self, ingredient: &str) -> Option<NutritionData> {
        let key = ingredient.to_lowercase();

        if let Some(entry) = self.nutrition_by_ingredient.get_mut(&key) {
            if entry.is_expired() {
                self.nutrition_by_ingredient.remove(&key);
                if self.config.track_stats {
                    self.stats.expirations += 1;
                    self.stats.misses += 1;
                }
                return None;
            }
            if self.config.track_stats {
                self.stats.hits += 1;
            }
            return Some(entry.get());
        }

        if self.config.track_stats {
            self.stats.misses += 1;
        }
        None
    }

    /// Cache nutrition by ingredient name
    pub fn put_nutrition(&mut self, ingredient: &str, nutrition: NutritionData) {
        self.ensure_capacity();

        let key = ingredient.to_lowercase();
        let entry = CacheEntry::new(nutrition, self.config.ttl_seconds);
        self.nutrition_by_ingredient.insert(key, entry);

        if self.config.track_stats {
            self.stats.insertions += 1;
            self.stats.current_entries = self.total_entries();
        }
    }

    // =========================================================================
    // SEARCH RESULTS
    // =========================================================================

    /// Get cached search results
    #[must_use]
    pub fn get_search_results(&mut self, query: &str) -> Option<Vec<FatSecretFood>> {
        let key = query.to_lowercase();

        if let Some(entry) = self.search_cache.get_mut(&key) {
            if entry.is_expired() {
                self.search_cache.remove(&key);
                if self.config.track_stats {
                    self.stats.expirations += 1;
                    self.stats.misses += 1;
                }
                return None;
            }
            if self.config.track_stats {
                self.stats.hits += 1;
            }
            return Some(entry.get());
        }

        if self.config.track_stats {
            self.stats.misses += 1;
        }
        None
    }

    /// Cache search results
    pub fn put_search_results(&mut self, query: &str, results: Vec<FatSecretFood>) {
        self.ensure_capacity();

        let key = query.to_lowercase();
        let entry = CacheEntry::new(results, self.config.ttl_seconds);
        self.search_cache.insert(key, entry);

        if self.config.track_stats {
            self.stats.insertions += 1;
            self.stats.current_entries = self.total_entries();
        }
    }

    // =========================================================================
    // INGREDIENT MAPPINGS
    // =========================================================================

    /// Get cached ingredient-to-food mapping
    #[must_use]
    pub fn get_mapping(&mut self, ingredient: &str) -> Option<FatSecretFoodId> {
        let key = ingredient.to_lowercase();

        if let Some(entry) = self.ingredient_mappings.get_mut(&key) {
            if entry.is_expired() {
                self.ingredient_mappings.remove(&key);
                if self.config.track_stats {
                    self.stats.expirations += 1;
                    self.stats.misses += 1;
                }
                return None;
            }
            if self.config.track_stats {
                self.stats.hits += 1;
            }
            return Some(entry.get());
        }

        if self.config.track_stats {
            self.stats.misses += 1;
        }
        None
    }

    /// Cache ingredient-to-food mapping
    pub fn put_mapping(&mut self, ingredient: &str, food_id: FatSecretFoodId) {
        self.ensure_capacity();

        let key = ingredient.to_lowercase();
        let entry = CacheEntry::new(food_id, self.config.ttl_seconds);
        self.ingredient_mappings.insert(key, entry);

        if self.config.track_stats {
            self.stats.insertions += 1;
            self.stats.current_entries = self.total_entries();
        }
    }

    // =========================================================================
    // CACHE MANAGEMENT
    // =========================================================================

    /// Get total number of entries across all caches
    #[must_use]
    pub fn total_entries(&self) -> usize {
        self.foods_by_id.len()
            + self.nutrition_by_ingredient.len()
            + self.search_cache.len()
            + self.ingredient_mappings.len()
    }

    /// Clear all caches
    pub fn clear(&mut self) {
        self.foods_by_id.clear();
        self.nutrition_by_ingredient.clear();
        self.search_cache.clear();
        self.ingredient_mappings.clear();

        if self.config.track_stats {
            self.stats.current_entries = 0;
        }
    }

    /// Get cache statistics
    #[must_use]
    pub fn stats(&self) -> &CacheStats {
        &self.stats
    }

    /// Get mutable cache statistics
    pub fn stats_mut(&mut self) -> &mut CacheStats {
        &mut self.stats
    }

    /// Ensure capacity by evicting oldest entries if necessary
    fn ensure_capacity(&mut self) {
        while self.total_entries() >= self.config.max_entries {
            self.evict_oldest();
        }
    }

    /// Evict the oldest entry (LRU)
    fn evict_oldest(&mut self) {
        // Find the oldest entry across all caches
        let mut oldest_key: Option<(CacheType, String)> = None;
        let mut oldest_time: Option<Instant> = None;

        for (key, entry) in &self.foods_by_id {
            if let Some(accessed) = entry.last_accessed {
                if oldest_time.is_none() || Some(accessed) < oldest_time {
                    oldest_time = Some(accessed);
                    oldest_key = Some((CacheType::Food, key.clone()));
                }
            }
        }

        for (key, entry) in &self.nutrition_by_ingredient {
            if let Some(accessed) = entry.last_accessed {
                if oldest_time.is_none() || Some(accessed) < oldest_time {
                    oldest_time = Some(accessed);
                    oldest_key = Some((CacheType::Nutrition, key.clone()));
                }
            }
        }

        for (key, entry) in &self.search_cache {
            if let Some(accessed) = entry.last_accessed {
                if oldest_time.is_none() || Some(accessed) < oldest_time {
                    oldest_time = Some(accessed);
                    oldest_key = Some((CacheType::Search, key.clone()));
                }
            }
        }

        for (key, entry) in &self.ingredient_mappings {
            if let Some(accessed) = entry.last_accessed {
                if oldest_time.is_none() || Some(accessed) < oldest_time {
                    oldest_time = Some(accessed);
                    oldest_key = Some((CacheType::Mapping, key.clone()));
                }
            }
        }

        // Remove the oldest entry
        if let Some((cache_type, key)) = oldest_key {
            match cache_type {
                CacheType::Food => {
                    self.foods_by_id.remove(&key);
                }
                CacheType::Nutrition => {
                    self.nutrition_by_ingredient.remove(&key);
                }
                CacheType::Search => {
                    self.search_cache.remove(&key);
                }
                CacheType::Mapping => {
                    self.ingredient_mappings.remove(&key);
                }
            }

            if self.config.track_stats {
                self.stats.evictions += 1;
                self.stats.current_entries = self.total_entries();
            }
        }
    }

    /// Remove expired entries from the food cache
    fn cleanup_expired_foods(&mut self) {
        let expired: Vec<String> = self
            .foods_by_id
            .iter()
            .filter(|(_, entry)| entry.is_expired())
            .map(|(key, _)| key.clone())
            .collect();

        for key in expired {
            self.foods_by_id.remove(&key);
            if self.config.track_stats {
                self.stats.expirations += 1;
            }
        }
    }

    /// Clean up all expired entries
    pub fn cleanup_expired(&mut self) {
        self.cleanup_expired_foods();

        // Nutrition cache
        let expired: Vec<String> = self
            .nutrition_by_ingredient
            .iter()
            .filter(|(_, entry)| entry.is_expired())
            .map(|(key, _)| key.clone())
            .collect();
        for key in expired {
            self.nutrition_by_ingredient.remove(&key);
            if self.config.track_stats {
                self.stats.expirations += 1;
            }
        }

        // Search cache
        let expired: Vec<String> = self
            .search_cache
            .iter()
            .filter(|(_, entry)| entry.is_expired())
            .map(|(key, _)| key.clone())
            .collect();
        for key in expired {
            self.search_cache.remove(&key);
            if self.config.track_stats {
                self.stats.expirations += 1;
            }
        }

        // Mapping cache
        let expired: Vec<String> = self
            .ingredient_mappings
            .iter()
            .filter(|(_, entry)| entry.is_expired())
            .map(|(key, _)| key.clone())
            .collect();
        for key in expired {
            self.ingredient_mappings.remove(&key);
            if self.config.track_stats {
                self.stats.expirations += 1;
            }
        }

        if self.config.track_stats {
            self.stats.current_entries = self.total_entries();
        }
    }

    /// Get configuration
    #[must_use]
    pub fn config(&self) -> &CacheConfig {
        &self.config
    }
}

impl Default for NutritionCache {
    fn default() -> Self {
        Self::with_defaults()
    }
}

/// Internal enum for cache type identification
#[derive(Debug, Clone, Copy)]
enum CacheType {
    Food,
    Nutrition,
    Search,
    Mapping,
}

// =============================================================================
// CACHE BUILDER
// =============================================================================

/// Builder for constructing a cache with preloaded data
#[derive(Debug, Default)]
pub struct CacheBuilder {
    config: Option<CacheConfig>,
    foods: Vec<(String, FatSecretFood)>,
    nutrition: Vec<(String, NutritionData)>,
    mappings: Vec<(String, FatSecretFoodId)>,
}

impl CacheBuilder {
    /// Create a new cache builder
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the cache configuration
    #[must_use]
    pub fn with_config(mut self, config: CacheConfig) -> Self {
        self.config = Some(config);
        self
    }

    /// Add a food to preload
    #[must_use]
    pub fn with_food(mut self, food_id: impl Into<String>, food: FatSecretFood) -> Self {
        self.foods.push((food_id.into(), food));
        self
    }

    /// Add nutrition to preload
    #[must_use]
    pub fn with_nutrition(
        mut self,
        ingredient: impl Into<String>,
        nutrition: NutritionData,
    ) -> Self {
        self.nutrition.push((ingredient.into(), nutrition));
        self
    }

    /// Add a mapping to preload
    #[must_use]
    pub fn with_mapping(
        mut self,
        ingredient: impl Into<String>,
        food_id: FatSecretFoodId,
    ) -> Self {
        self.mappings.push((ingredient.into(), food_id));
        self
    }

    /// Build the cache
    #[must_use]
    pub fn build(self) -> NutritionCache {
        let mut cache = NutritionCache::new(self.config.unwrap_or_default());

        for (food_id, food) in self.foods {
            cache.put_food(&food_id, food);
        }

        for (ingredient, nutrition) in self.nutrition {
            cache.put_nutrition(&ingredient, nutrition);
        }

        for (ingredient, food_id) in self.mappings {
            cache.put_mapping(&ingredient, food_id);
        }

        cache
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::sync::types::{FoodType, ServingInfo};

    fn create_test_food(id: &str) -> FatSecretFood {
        FatSecretFood {
            food_id: id.to_string(),
            name: format!("Test Food {id}"),
            brand: None,
            food_type: FoodType::Generic,
            servings: vec![ServingInfo::default_serving("1 serving", 100.0)],
            nutrition: NutritionData::macros_only(100.0, 10.0, 5.0, 15.0),
            description: None,
        }
    }

    #[test]
    fn test_cache_entry_expiration() {
        let entry: CacheEntry<i32> = CacheEntry::new(42, 1); // 1 second TTL
        assert!(!entry.is_expired());

        // Wait for expiration (in real tests, would use mock time)
        // For now, just test the logic
        let entry: CacheEntry<i32> = CacheEntry {
            value: 42,
            created_at: Some(Instant::now() - Duration::from_secs(10)),
            last_accessed: Some(Instant::now()),
            access_count: 1,
            ttl_seconds: 1,
        };
        assert!(entry.is_expired());
    }

    #[test]
    fn test_cache_food_operations() {
        let mut cache = NutritionCache::with_defaults();

        // Miss before insert
        assert!(cache.get_food("123").is_none());
        assert_eq!(cache.stats().misses, 1);

        // Insert
        let food = create_test_food("123");
        cache.put_food("123", food.clone());
        assert_eq!(cache.stats().insertions, 1);

        // Hit after insert
        let cached = cache.get_food("123");
        assert!(cached.is_some());
        assert_eq!(cached.unwrap().food_id, "123");
        assert_eq!(cache.stats().hits, 1);
    }

    #[test]
    fn test_cache_nutrition_operations() {
        let mut cache = NutritionCache::with_defaults();

        let nutrition = NutritionData::macros_only(200.0, 20.0, 10.0, 30.0);
        cache.put_nutrition("chicken breast", nutrition.clone());

        let cached = cache.get_nutrition("chicken breast");
        assert!(cached.is_some());
        assert!((cached.unwrap().calories - 200.0).abs() < 0.001);

        // Case insensitive
        let cached = cache.get_nutrition("CHICKEN BREAST");
        assert!(cached.is_some());
    }

    #[test]
    fn test_cache_search_results() {
        let mut cache = NutritionCache::with_defaults();

        let results = vec![create_test_food("1"), create_test_food("2")];
        cache.put_search_results("chicken", results.clone());

        let cached = cache.get_search_results("chicken");
        assert!(cached.is_some());
        assert_eq!(cached.unwrap().len(), 2);
    }

    #[test]
    fn test_cache_mappings() {
        let mut cache = NutritionCache::with_defaults();

        let food_id = FatSecretFoodId::new("12345");
        cache.put_mapping("chicken breast", food_id.clone());

        let cached = cache.get_mapping("chicken breast");
        assert!(cached.is_some());
        assert_eq!(cached.unwrap().as_str(), "12345");
    }

    #[test]
    fn test_cache_capacity_eviction() {
        let config = CacheConfig {
            max_entries: 3,
            ..CacheConfig::default()
        };
        let mut cache = NutritionCache::new(config);

        // Fill cache
        cache.put_food("1", create_test_food("1"));
        cache.put_food("2", create_test_food("2"));
        cache.put_food("3", create_test_food("3"));

        assert_eq!(cache.total_entries(), 3);

        // Add one more, should trigger eviction
        cache.put_food("4", create_test_food("4"));
        assert_eq!(cache.total_entries(), 3);
        assert!(cache.stats().evictions > 0);
    }

    #[test]
    fn test_cache_clear() {
        let mut cache = NutritionCache::with_defaults();

        cache.put_food("1", create_test_food("1"));
        cache.put_nutrition("test", NutritionData::zero());
        cache.put_mapping("test", FatSecretFoodId::new("1"));

        assert!(cache.total_entries() > 0);

        cache.clear();
        assert_eq!(cache.total_entries(), 0);
    }

    #[test]
    fn test_cache_stats() {
        let mut cache = NutritionCache::with_defaults();

        // Initial stats
        assert_eq!(cache.stats().hits, 0);
        assert_eq!(cache.stats().misses, 0);
        assert!((cache.stats().hit_rate() - 0.0).abs() < 0.001);

        // After operations
        assert!(cache.get_food("missing").is_none());
        cache.put_food("1", create_test_food("1"));
        assert!(cache.get_food("1").is_some());

        assert_eq!(cache.stats().misses, 1);
        assert_eq!(cache.stats().hits, 1);
        assert!((cache.stats().hit_rate() - 0.5).abs() < 0.001);
    }

    #[test]
    fn test_cache_builder() {
        let food = create_test_food("123");
        let nutrition = NutritionData::macros_only(100.0, 10.0, 5.0, 15.0);

        let mut cache = CacheBuilder::new()
            .with_config(CacheConfig::for_testing())
            .with_food("123", food)
            .with_nutrition("test", nutrition)
            .with_mapping("chicken", FatSecretFoodId::new("456"))
            .build();

        assert!(cache.get_food("123").is_some());
        assert!(cache.get_nutrition("test").is_some());
        assert!(cache.get_mapping("chicken").is_some());
    }

    #[test]
    fn test_config_validation() {
        let valid = CacheConfig::default();
        assert!(valid.validate().is_ok());

        let invalid = CacheConfig {
            max_entries: 0,
            ..CacheConfig::default()
        };
        assert!(invalid.validate().is_err());
    }

    #[test]
    fn test_cache_entry_touch() {
        let mut entry: CacheEntry<i32> = CacheEntry::new(42, 3600);
        assert_eq!(entry.access_count, 1);

        entry.touch();
        assert_eq!(entry.access_count, 2);

        let _ = entry.get();
        assert_eq!(entry.access_count, 3);
    }
}

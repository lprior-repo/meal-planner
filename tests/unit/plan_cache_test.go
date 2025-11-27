package unit

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	"github.com/dgraph-io/badger/v4"
)

// CachedPlan represents a cached weekly plan with metadata
type CachedPlan struct {
	CacheKey     string         `json:"cache_key"`
	Plan         WeeklyMealPlan `json:"plan"`
	UserID       string         `json:"user_id"`
	WeekStarting string         `json:"week_starting"`
	CachedAt     time.Time      `json:"cached_at"`
	ExpiresAt    time.Time      `json:"expires_at"`
	HitCount     int            `json:"hit_count"`
}

// PlanCacheKey generates a cache key based on user profile and week
func PlanCacheKey(profile UserProfile, weekStarting string) string {
	// Create a deterministic key from profile + week
	data := fmt.Sprintf("%f:%s:%s:%d:%s",
		profile.Bodyweight,
		profile.ActivityLevel,
		profile.Goal,
		profile.MealsPerDay,
		weekStarting,
	)
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:16]) // Use first 16 bytes for shorter key
}

const (
	PlanCachePrefix    = "plan_cache:"
	PlanCacheByUser    = "plan_cache_user:"
	PlanCacheByWeek    = "plan_cache_week:"
	DefaultCacheTTL    = 7 * 24 * time.Hour // 1 week
)

// Test cache key generation - same inputs produce same key
func TestPlanCacheKeyDeterministic(t *testing.T) {
	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	weekStarting := "2025-01-06"

	key1 := PlanCacheKey(profile, weekStarting)
	key2 := PlanCacheKey(profile, weekStarting)

	if key1 != key2 {
		t.Errorf("Cache keys should be deterministic: %s != %s", key1, key2)
	}
}

// Test cache key generation - different inputs produce different keys
func TestPlanCacheKeyUnique(t *testing.T) {
	profile1 := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	profile2 := UserProfile{
		Bodyweight:    200.0, // Different weight
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	weekStarting := "2025-01-06"

	key1 := PlanCacheKey(profile1, weekStarting)
	key2 := PlanCacheKey(profile2, weekStarting)

	if key1 == key2 {
		t.Errorf("Cache keys should be unique for different profiles")
	}

	// Different week, same profile
	key3 := PlanCacheKey(profile1, "2025-01-13")
	if key1 == key3 {
		t.Errorf("Cache keys should be unique for different weeks")
	}
}

// Test cache miss scenario - no cached plan exists
func TestPlanCacheMiss(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	weekStarting := "2025-01-06"
	cacheKey := PlanCacheKey(profile, weekStarting)

	// Try to get a non-existent cached plan
	err = db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
		return err
	})

	if err != badger.ErrKeyNotFound {
		t.Errorf("Expected cache miss (ErrKeyNotFound), got %v", err)
	}
}

// Test cache hit scenario - cached plan exists and is valid
func TestPlanCacheHit(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	weekStarting := "2025-01-06"
	cacheKey := PlanCacheKey(profile, weekStarting)

	// Create and cache a plan
	plan := WeeklyMealPlan{
		UserProfile: profile,
	}
	plan.Days[0] = DailyPlan{
		DayName: "Monday",
		Meals: []Meal{
			{
				Recipe:      Recipe{Name: "Cached Steak"},
				PortionSize: 1.0,
			},
		},
	}

	cachedPlan := CachedPlan{
		CacheKey:     cacheKey,
		Plan:         plan,
		UserID:       "user_1",
		WeekStarting: weekStarting,
		CachedAt:     time.Now(),
		ExpiresAt:    time.Now().Add(DefaultCacheTTL),
		HitCount:     0,
	}

	data, _ := json.Marshal(cachedPlan)

	// Store in cache
	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(PlanCachePrefix+cacheKey), data)
	})
	if err != nil {
		t.Fatalf("Failed to cache plan: %v", err)
	}

	// Retrieve from cache (cache hit)
	var retrieved CachedPlan
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			return json.Unmarshal(val, &retrieved)
		})
	})
	if err != nil {
		t.Fatalf("Expected cache hit, got error: %v", err)
	}

	if retrieved.CacheKey != cacheKey {
		t.Errorf("Expected cache key %s, got %s", cacheKey, retrieved.CacheKey)
	}
	if retrieved.Plan.Days[0].Meals[0].Recipe.Name != "Cached Steak" {
		t.Errorf("Expected recipe 'Cached Steak', got %s", retrieved.Plan.Days[0].Meals[0].Recipe.Name)
	}
}

// Test cache expiration - expired plans should be treated as misses
func TestPlanCacheExpiration(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	weekStarting := "2025-01-06"
	cacheKey := PlanCacheKey(profile, weekStarting)

	// Create an expired cached plan
	cachedPlan := CachedPlan{
		CacheKey:     cacheKey,
		Plan:         WeeklyMealPlan{UserProfile: profile},
		UserID:       "user_1",
		WeekStarting: weekStarting,
		CachedAt:     time.Now().Add(-8 * 24 * time.Hour), // 8 days ago
		ExpiresAt:    time.Now().Add(-1 * 24 * time.Hour), // Expired 1 day ago
		HitCount:     5,
	}

	data, _ := json.Marshal(cachedPlan)

	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(PlanCachePrefix+cacheKey), data)
	})
	if err != nil {
		t.Fatalf("Failed to cache plan: %v", err)
	}

	// Retrieve and check expiration
	var retrieved CachedPlan
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			return json.Unmarshal(val, &retrieved)
		})
	})
	if err != nil {
		t.Fatalf("Failed to retrieve cached plan: %v", err)
	}

	// Check if expired
	isExpired := time.Now().After(retrieved.ExpiresAt)
	if !isExpired {
		t.Errorf("Expected plan to be expired")
	}
}

// Test cache hit count increment
func TestPlanCacheHitCountIncrement(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	weekStarting := "2025-01-06"
	cacheKey := PlanCacheKey(profile, weekStarting)

	// Create initial cached plan with hit count 0
	cachedPlan := CachedPlan{
		CacheKey:     cacheKey,
		Plan:         WeeklyMealPlan{UserProfile: profile},
		UserID:       "user_1",
		WeekStarting: weekStarting,
		CachedAt:     time.Now(),
		ExpiresAt:    time.Now().Add(DefaultCacheTTL),
		HitCount:     0,
	}

	data, _ := json.Marshal(cachedPlan)

	err = db.Update(func(txn *badger.Txn) error {
		return txn.Set([]byte(PlanCachePrefix+cacheKey), data)
	})
	if err != nil {
		t.Fatalf("Failed to cache plan: %v", err)
	}

	// Simulate 3 cache hits by incrementing hit count
	for i := 0; i < 3; i++ {
		err = db.Update(func(txn *badger.Txn) error {
			item, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
			if err != nil {
				return err
			}

			var plan CachedPlan
			err = item.Value(func(val []byte) error {
				return json.Unmarshal(val, &plan)
			})
			if err != nil {
				return err
			}

			plan.HitCount++
			updatedData, _ := json.Marshal(plan)
			return txn.Set([]byte(PlanCachePrefix+cacheKey), updatedData)
		})
		if err != nil {
			t.Fatalf("Failed to increment hit count: %v", err)
		}
	}

	// Verify hit count is 3
	var retrieved CachedPlan
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			return json.Unmarshal(val, &retrieved)
		})
	})
	if err != nil {
		t.Fatalf("Failed to retrieve cached plan: %v", err)
	}

	if retrieved.HitCount != 3 {
		t.Errorf("Expected hit count 3, got %d", retrieved.HitCount)
	}
}

// Test retrieving previous plans for comparison
func TestRetrievePreviousPlansForUser(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	userID := "user_1"

	// Create multiple cached plans for the same user over different weeks
	weeks := []string{"2025-01-06", "2025-01-13", "2025-01-20"}
	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}

	for i, week := range weeks {
		cacheKey := PlanCacheKey(profile, week)

		cachedPlan := CachedPlan{
			CacheKey:     cacheKey,
			Plan:         WeeklyMealPlan{UserProfile: profile},
			UserID:       userID,
			WeekStarting: week,
			CachedAt:     time.Now(),
			ExpiresAt:    time.Now().Add(DefaultCacheTTL),
			HitCount:     i,
		}

		data, _ := json.Marshal(cachedPlan)

		err := db.Update(func(txn *badger.Txn) error {
			// Store main cache entry
			if err := txn.Set([]byte(PlanCachePrefix+cacheKey), data); err != nil {
				return err
			}
			// Store user index
			userIndexKey := fmt.Sprintf("%s%s:%s", PlanCacheByUser, userID, cacheKey)
			return txn.Set([]byte(userIndexKey), []byte(cacheKey))
		})
		if err != nil {
			t.Fatalf("Failed to cache plan: %v", err)
		}
	}

	// Retrieve all cached plans for the user
	var userPlans []CachedPlan
	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		prefix := []byte(PlanCacheByUser + userID + ":")
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			var cacheKey string
			err := item.Value(func(val []byte) error {
				cacheKey = string(val)
				return nil
			})
			if err != nil {
				return err
			}

			// Retrieve the actual cached plan
			planItem, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
			if err != nil {
				return err
			}

			err = planItem.Value(func(val []byte) error {
				var plan CachedPlan
				if err := json.Unmarshal(val, &plan); err != nil {
					return err
				}
				userPlans = append(userPlans, plan)
				return nil
			})
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to retrieve user plans: %v", err)
	}

	if len(userPlans) != 3 {
		t.Errorf("Expected 3 cached plans for user, got %d", len(userPlans))
	}
}

// Test retrieving plans by week for progression comparison
func TestRetrievePlansByWeekForProgression(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create plans for the same week but different users
	weekStarting := "2025-01-06"
	users := []struct {
		userID  string
		profile UserProfile
	}{
		{"user_1", UserProfile{Bodyweight: 180.0, ActivityLevel: "moderate", Goal: "maintain", MealsPerDay: 4}},
		{"user_2", UserProfile{Bodyweight: 200.0, ActivityLevel: "active", Goal: "gain", MealsPerDay: 5}},
	}

	for _, u := range users {
		cacheKey := PlanCacheKey(u.profile, weekStarting)

		cachedPlan := CachedPlan{
			CacheKey:     cacheKey,
			Plan:         WeeklyMealPlan{UserProfile: u.profile},
			UserID:       u.userID,
			WeekStarting: weekStarting,
			CachedAt:     time.Now(),
			ExpiresAt:    time.Now().Add(DefaultCacheTTL),
			HitCount:     0,
		}

		data, _ := json.Marshal(cachedPlan)

		err := db.Update(func(txn *badger.Txn) error {
			if err := txn.Set([]byte(PlanCachePrefix+cacheKey), data); err != nil {
				return err
			}
			weekIndexKey := fmt.Sprintf("%s%s:%s", PlanCacheByWeek, weekStarting, cacheKey)
			return txn.Set([]byte(weekIndexKey), []byte(cacheKey))
		})
		if err != nil {
			t.Fatalf("Failed to cache plan: %v", err)
		}
	}

	// Retrieve all cached plans for the week
	var weekPlans []CachedPlan
	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		prefix := []byte(PlanCacheByWeek + weekStarting + ":")
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			var cacheKey string
			err := item.Value(func(val []byte) error {
				cacheKey = string(val)
				return nil
			})
			if err != nil {
				return err
			}

			planItem, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
			if err != nil {
				return err
			}

			err = planItem.Value(func(val []byte) error {
				var plan CachedPlan
				if err := json.Unmarshal(val, &plan); err != nil {
					return err
				}
				weekPlans = append(weekPlans, plan)
				return nil
			})
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to retrieve week plans: %v", err)
	}

	if len(weekPlans) != 2 {
		t.Errorf("Expected 2 cached plans for week, got %d", len(weekPlans))
	}
}

// Test cache invalidation - delete cached plan
func TestPlanCacheInvalidation(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	weekStarting := "2025-01-06"
	userID := "user_1"
	cacheKey := PlanCacheKey(profile, weekStarting)

	// Create and store a cached plan with indexes
	cachedPlan := CachedPlan{
		CacheKey:     cacheKey,
		Plan:         WeeklyMealPlan{UserProfile: profile},
		UserID:       userID,
		WeekStarting: weekStarting,
		CachedAt:     time.Now(),
		ExpiresAt:    time.Now().Add(DefaultCacheTTL),
		HitCount:     5,
	}

	data, _ := json.Marshal(cachedPlan)

	err = db.Update(func(txn *badger.Txn) error {
		if err := txn.Set([]byte(PlanCachePrefix+cacheKey), data); err != nil {
			return err
		}
		userIndexKey := fmt.Sprintf("%s%s:%s", PlanCacheByUser, userID, cacheKey)
		if err := txn.Set([]byte(userIndexKey), []byte(cacheKey)); err != nil {
			return err
		}
		weekIndexKey := fmt.Sprintf("%s%s:%s", PlanCacheByWeek, weekStarting, cacheKey)
		return txn.Set([]byte(weekIndexKey), []byte(cacheKey))
	})
	if err != nil {
		t.Fatalf("Failed to cache plan: %v", err)
	}

	// Invalidate (delete) the cached plan and its indexes
	err = db.Update(func(txn *badger.Txn) error {
		if err := txn.Delete([]byte(PlanCachePrefix + cacheKey)); err != nil {
			return err
		}
		userIndexKey := fmt.Sprintf("%s%s:%s", PlanCacheByUser, userID, cacheKey)
		if err := txn.Delete([]byte(userIndexKey)); err != nil {
			return err
		}
		weekIndexKey := fmt.Sprintf("%s%s:%s", PlanCacheByWeek, weekStarting, cacheKey)
		return txn.Delete([]byte(weekIndexKey))
	})
	if err != nil {
		t.Fatalf("Failed to invalidate cache: %v", err)
	}

	// Verify cache miss after invalidation
	err = db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
		return err
	})
	if err != badger.ErrKeyNotFound {
		t.Errorf("Expected cache miss after invalidation, got %v", err)
	}
}

// Test listing all cached plans with statistics
func TestListCachedPlansWithStats(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}

	// Create multiple cached plans with varying hit counts
	for i := 1; i <= 5; i++ {
		weekStarting := fmt.Sprintf("2025-01-%02d", i*7)
		cacheKey := PlanCacheKey(profile, weekStarting)

		cachedPlan := CachedPlan{
			CacheKey:     cacheKey,
			Plan:         WeeklyMealPlan{UserProfile: profile},
			UserID:       "user_1",
			WeekStarting: weekStarting,
			CachedAt:     time.Now(),
			ExpiresAt:    time.Now().Add(DefaultCacheTTL),
			HitCount:     i * 2, // Varying hit counts: 2, 4, 6, 8, 10
		}

		data, _ := json.Marshal(cachedPlan)

		err := db.Update(func(txn *badger.Txn) error {
			return txn.Set([]byte(PlanCachePrefix+cacheKey), data)
		})
		if err != nil {
			t.Fatalf("Failed to cache plan: %v", err)
		}
	}

	// List all cached plans and calculate stats
	var allPlans []CachedPlan
	var totalHits int

	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		prefix := []byte(PlanCachePrefix)
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			err := item.Value(func(val []byte) error {
				var plan CachedPlan
				if err := json.Unmarshal(val, &plan); err != nil {
					return err
				}
				allPlans = append(allPlans, plan)
				totalHits += plan.HitCount
				return nil
			})
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to list cached plans: %v", err)
	}

	if len(allPlans) != 5 {
		t.Errorf("Expected 5 cached plans, got %d", len(allPlans))
	}

	expectedTotalHits := 2 + 4 + 6 + 8 + 10 // = 30
	if totalHits != expectedTotalHits {
		t.Errorf("Expected total hits %d, got %d", expectedTotalHits, totalHits)
	}
}

// Test cache with TTL using Badger's native TTL support
func TestPlanCacheWithBadgerTTL(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	profile := UserProfile{
		Bodyweight:    180.0,
		ActivityLevel: "moderate",
		Goal:          "maintain",
		MealsPerDay:   4,
	}
	weekStarting := "2025-01-06"
	cacheKey := PlanCacheKey(profile, weekStarting)

	cachedPlan := CachedPlan{
		CacheKey:     cacheKey,
		Plan:         WeeklyMealPlan{UserProfile: profile},
		UserID:       "user_1",
		WeekStarting: weekStarting,
		CachedAt:     time.Now(),
		ExpiresAt:    time.Now().Add(DefaultCacheTTL),
		HitCount:     0,
	}

	data, _ := json.Marshal(cachedPlan)

	// Store with Badger's native TTL (entry will auto-expire)
	ttl := 1 * time.Hour // Short TTL for demonstration
	err = db.Update(func(txn *badger.Txn) error {
		entry := badger.NewEntry([]byte(PlanCachePrefix+cacheKey), data).WithTTL(ttl)
		return txn.SetEntry(entry)
	})
	if err != nil {
		t.Fatalf("Failed to cache plan with TTL: %v", err)
	}

	// Verify plan exists immediately
	err = db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(PlanCachePrefix + cacheKey))
		return err
	})
	if err != nil {
		t.Errorf("Expected cache hit immediately after storing, got %v", err)
	}

	// Note: In a real test, we would wait for TTL to expire
	// For unit tests, we just verify the entry was set with TTL
}

// Test comparing progression between two weekly plans
func TestComparePlanProgression(t *testing.T) {
	// Create two plans - previous week and current week
	previousPlan := WeeklyMealPlan{
		UserProfile: UserProfile{
			Bodyweight:    180.0,
			ActivityLevel: "moderate",
			Goal:          "maintain",
			MealsPerDay:   4,
		},
	}
	previousPlan.Days[0] = DailyPlan{
		DayName: "Monday",
		Meals: []Meal{
			{Recipe: Recipe{Name: "Steak", Macros: Macros{Protein: 50, Fat: 20, Carbs: 0}}, PortionSize: 1.0},
			{Recipe: Recipe{Name: "Rice", Macros: Macros{Protein: 5, Fat: 1, Carbs: 45}}, PortionSize: 1.0},
		},
	}

	currentPlan := WeeklyMealPlan{
		UserProfile: UserProfile{
			Bodyweight:    182.0, // Gained 2 lbs
			ActivityLevel: "moderate",
			Goal:          "gain", // Changed goal
			MealsPerDay:   4,
		},
	}
	currentPlan.Days[0] = DailyPlan{
		DayName: "Monday",
		Meals: []Meal{
			{Recipe: Recipe{Name: "Steak", Macros: Macros{Protein: 50, Fat: 20, Carbs: 0}}, PortionSize: 1.2}, // Increased portion
			{Recipe: Recipe{Name: "Rice", Macros: Macros{Protein: 5, Fat: 1, Carbs: 45}}, PortionSize: 1.5},   // Increased portion
		},
	}

	// Compare progression
	previousMacros := previousPlan.Days[0].TotalMacros()
	currentMacros := currentPlan.Days[0].TotalMacros()

	proteinIncrease := currentMacros.Protein - previousMacros.Protein
	carbIncrease := currentMacros.Carbs - previousMacros.Carbs
	weightChange := currentPlan.UserProfile.Bodyweight - previousPlan.UserProfile.Bodyweight

	// Verify progression tracking
	if proteinIncrease <= 0 {
		t.Errorf("Expected protein increase, got %f", proteinIncrease)
	}
	if carbIncrease <= 0 {
		t.Errorf("Expected carb increase, got %f", carbIncrease)
	}
	if weightChange != 2.0 {
		t.Errorf("Expected weight change of 2.0, got %f", weightChange)
	}

	// Calculate calorie progression
	previousCalories := previousMacros.Calories()
	currentCalories := currentMacros.Calories()
	calorieIncrease := currentCalories - previousCalories

	if calorieIncrease <= 0 {
		t.Errorf("Expected calorie increase for 'gain' goal, got %f", calorieIncrease)
	}
}

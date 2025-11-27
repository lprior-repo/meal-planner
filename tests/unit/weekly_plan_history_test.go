package unit

import (
	"encoding/json"
	"fmt"
	"strconv"
	"testing"
	"time"

	"github.com/dgraph-io/badger/v4"
)

// StoredWeeklyPlan wraps WeeklyMealPlan with storage metadata and indexing
type StoredWeeklyPlan struct {
	ID           string         `json:"id"`
	UserID       string         `json:"user_id"`
	Plan         WeeklyMealPlan `json:"plan"`
	WeekStarting string         `json:"week_starting"` // YYYY-MM-DD format for date indexing
	CreatedAt    time.Time      `json:"created_at"`
}

const (
	WeeklyPlanPrefix  = "weekly_plan:"
	WeeklyPlanByDate  = "weekly_plan_date:"  // Index: date -> plan IDs
	WeeklyPlanByUser  = "weekly_plan_user:"  // Index: user -> plan IDs
	WeeklyPlanCounter = "weekly_plan_counter"
)

// Test WeeklyPlanHistory storage - Create operation
func TestWeeklyPlanCreate(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create a weekly plan
	plan := WeeklyMealPlan{
		UserProfile: UserProfile{
			Bodyweight:    180.0,
			ActivityLevel: "moderate",
			Goal:          "maintain",
			MealsPerDay:   4,
		},
	}

	// Set up some meals for day 0
	plan.Days[0] = DailyPlan{
		DayName: "Monday",
		Meals: []Meal{
			{
				Recipe: Recipe{
					Name: "Test Recipe",
					Macros: Macros{
						Protein: 40.0,
						Fat:     15.0,
						Carbs:   60.0,
					},
				},
				PortionSize: 1.0,
			},
		},
	}

	// Get next ID
	var counter int
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(WeeklyPlanCounter))
		if err == badger.ErrKeyNotFound {
			counter = 0
			return nil
		}
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			counter, _ = strconv.Atoi(string(val))
			return nil
		})
	})
	if err != nil {
		t.Fatalf("Failed to get counter: %v", err)
	}

	counter++
	planID := "plan_" + strconv.Itoa(counter)
	userID := "user_1"
	weekStarting := "2025-01-06"

	storedPlan := StoredWeeklyPlan{
		ID:           planID,
		UserID:       userID,
		Plan:         plan,
		WeekStarting: weekStarting,
		CreatedAt:    time.Now(),
	}

	data, err := json.Marshal(storedPlan)
	if err != nil {
		t.Fatalf("Failed to marshal plan: %v", err)
	}

	// Store the plan with indexes
	err = db.Update(func(txn *badger.Txn) error {
		// Update counter
		if err := txn.Set([]byte(WeeklyPlanCounter), []byte(strconv.Itoa(counter))); err != nil {
			return err
		}
		// Store main plan
		if err := txn.Set([]byte(WeeklyPlanPrefix+planID), data); err != nil {
			return err
		}
		// Store date index (date:planID -> planID for lookup)
		dateIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByDate, weekStarting, planID)
		if err := txn.Set([]byte(dateIndexKey), []byte(planID)); err != nil {
			return err
		}
		// Store user index (user:planID -> planID for lookup)
		userIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByUser, userID, planID)
		return txn.Set([]byte(userIndexKey), []byte(planID))
	})
	if err != nil {
		t.Fatalf("Failed to store plan: %v", err)
	}

	// Verify the plan was stored
	var retrieved StoredWeeklyPlan
	err = db.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(WeeklyPlanPrefix + planID))
		if err != nil {
			return err
		}
		return item.Value(func(val []byte) error {
			return json.Unmarshal(val, &retrieved)
		})
	})
	if err != nil {
		t.Fatalf("Failed to retrieve plan: %v", err)
	}

	if retrieved.WeekStarting != weekStarting {
		t.Errorf("Expected week starting %s, got %s", weekStarting, retrieved.WeekStarting)
	}
	if retrieved.UserID != userID {
		t.Errorf("Expected user ID %s, got %s", userID, retrieved.UserID)
	}
}

// Test WeeklyPlanHistory - Query by date
func TestWeeklyPlanQueryByDate(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create multiple plans with different dates
	dates := []string{"2025-01-06", "2025-01-13", "2025-01-06"} // Two plans for same date
	userID := "user_1"

	for i, date := range dates {
		planID := fmt.Sprintf("plan_%d", i+1)

		plan := WeeklyMealPlan{
			UserProfile: UserProfile{
				Bodyweight: 180.0,
				Goal:       "maintain",
			},
		}

		storedPlan := StoredWeeklyPlan{
			ID:           planID,
			UserID:       userID,
			Plan:         plan,
			WeekStarting: date,
			CreatedAt:    time.Now(),
		}

		data, _ := json.Marshal(storedPlan)

		err := db.Update(func(txn *badger.Txn) error {
			if err := txn.Set([]byte(WeeklyPlanPrefix+planID), data); err != nil {
				return err
			}
			dateIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByDate, date, planID)
			return txn.Set([]byte(dateIndexKey), []byte(planID))
		})
		if err != nil {
			t.Fatalf("Failed to store plan: %v", err)
		}
	}

	// Query plans for 2025-01-06
	targetDate := "2025-01-06"
	var foundPlanIDs []string

	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		prefix := []byte(WeeklyPlanByDate + targetDate + ":")
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			err := item.Value(func(val []byte) error {
				foundPlanIDs = append(foundPlanIDs, string(val))
				return nil
			})
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to query by date: %v", err)
	}

	// Should find 2 plans for 2025-01-06
	if len(foundPlanIDs) != 2 {
		t.Errorf("Expected 2 plans for date %s, got %d", targetDate, len(foundPlanIDs))
	}
}

// Test WeeklyPlanHistory - Query by user
func TestWeeklyPlanQueryByUser(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create plans for multiple users
	type planData struct {
		userID       string
		weekStarting string
	}

	plans := []planData{
		{"user_1", "2025-01-06"},
		{"user_1", "2025-01-13"},
		{"user_2", "2025-01-06"},
	}

	for i, pd := range plans {
		planID := fmt.Sprintf("plan_%d", i+1)

		plan := WeeklyMealPlan{
			UserProfile: UserProfile{Bodyweight: 180.0},
		}

		storedPlan := StoredWeeklyPlan{
			ID:           planID,
			UserID:       pd.userID,
			Plan:         plan,
			WeekStarting: pd.weekStarting,
			CreatedAt:    time.Now(),
		}

		data, _ := json.Marshal(storedPlan)

		err := db.Update(func(txn *badger.Txn) error {
			if err := txn.Set([]byte(WeeklyPlanPrefix+planID), data); err != nil {
				return err
			}
			userIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByUser, pd.userID, planID)
			return txn.Set([]byte(userIndexKey), []byte(planID))
		})
		if err != nil {
			t.Fatalf("Failed to store plan: %v", err)
		}
	}

	// Query plans for user_1
	targetUser := "user_1"
	var foundPlanIDs []string

	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		prefix := []byte(WeeklyPlanByUser + targetUser + ":")
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			err := item.Value(func(val []byte) error {
				foundPlanIDs = append(foundPlanIDs, string(val))
				return nil
			})
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to query by user: %v", err)
	}

	// Should find 2 plans for user_1
	if len(foundPlanIDs) != 2 {
		t.Errorf("Expected 2 plans for user %s, got %d", targetUser, len(foundPlanIDs))
	}
}

// Test WeeklyPlanHistory - Date range query
func TestWeeklyPlanDateRangeQuery(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create plans across different weeks
	dates := []string{"2024-12-30", "2025-01-06", "2025-01-13", "2025-01-20", "2025-01-27"}
	userID := "user_1"

	for i, date := range dates {
		planID := fmt.Sprintf("plan_%d", i+1)

		storedPlan := StoredWeeklyPlan{
			ID:           planID,
			UserID:       userID,
			Plan:         WeeklyMealPlan{},
			WeekStarting: date,
			CreatedAt:    time.Now(),
		}

		data, _ := json.Marshal(storedPlan)

		err := db.Update(func(txn *badger.Txn) error {
			if err := txn.Set([]byte(WeeklyPlanPrefix+planID), data); err != nil {
				return err
			}
			dateIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByDate, date, planID)
			return txn.Set([]byte(dateIndexKey), []byte(planID))
		})
		if err != nil {
			t.Fatalf("Failed to store plan: %v", err)
		}
	}

	// Query plans for January 2025 (between 2025-01-01 and 2025-01-31)
	startDate := "2025-01-01"
	endDate := "2025-01-31"
	var foundPlanIDs []string

	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		prefix := []byte(WeeklyPlanByDate)
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			key := string(item.Key())

			// Extract date from key format: weekly_plan_date:YYYY-MM-DD:planID
			if len(key) > len(WeeklyPlanByDate)+10 {
				dateStr := key[len(WeeklyPlanByDate) : len(WeeklyPlanByDate)+10]
				if dateStr >= startDate && dateStr <= endDate {
					err := item.Value(func(val []byte) error {
						foundPlanIDs = append(foundPlanIDs, string(val))
						return nil
					})
					if err != nil {
						return err
					}
				}
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to query date range: %v", err)
	}

	// Should find 4 plans in January 2025 (01-06, 01-13, 01-20, 01-27)
	if len(foundPlanIDs) != 4 {
		t.Errorf("Expected 4 plans in January 2025, got %d", len(foundPlanIDs))
	}
}

// Test WeeklyPlanHistory - Delete with index cleanup
func TestWeeklyPlanDeleteWithIndexes(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create a plan
	planID := "plan_delete_test"
	userID := "user_1"
	weekStarting := "2025-01-06"

	storedPlan := StoredWeeklyPlan{
		ID:           planID,
		UserID:       userID,
		Plan:         WeeklyMealPlan{},
		WeekStarting: weekStarting,
		CreatedAt:    time.Now(),
	}

	data, _ := json.Marshal(storedPlan)

	// Store with indexes
	err = db.Update(func(txn *badger.Txn) error {
		if err := txn.Set([]byte(WeeklyPlanPrefix+planID), data); err != nil {
			return err
		}
		dateIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByDate, weekStarting, planID)
		if err := txn.Set([]byte(dateIndexKey), []byte(planID)); err != nil {
			return err
		}
		userIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByUser, userID, planID)
		return txn.Set([]byte(userIndexKey), []byte(planID))
	})
	if err != nil {
		t.Fatalf("Failed to store plan: %v", err)
	}

	// Delete the plan and its indexes
	err = db.Update(func(txn *badger.Txn) error {
		// Delete main entry
		if err := txn.Delete([]byte(WeeklyPlanPrefix + planID)); err != nil {
			return err
		}
		// Delete date index
		dateIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByDate, weekStarting, planID)
		if err := txn.Delete([]byte(dateIndexKey)); err != nil {
			return err
		}
		// Delete user index
		userIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByUser, userID, planID)
		return txn.Delete([]byte(userIndexKey))
	})
	if err != nil {
		t.Fatalf("Failed to delete plan: %v", err)
	}

	// Verify main entry is deleted
	err = db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(WeeklyPlanPrefix + planID))
		return err
	})
	if err != badger.ErrKeyNotFound {
		t.Errorf("Expected ErrKeyNotFound for main entry, got %v", err)
	}

	// Verify date index is deleted
	dateIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByDate, weekStarting, planID)
	err = db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(dateIndexKey))
		return err
	})
	if err != badger.ErrKeyNotFound {
		t.Errorf("Expected ErrKeyNotFound for date index, got %v", err)
	}

	// Verify user index is deleted
	userIndexKey := fmt.Sprintf("%s%s:%s", WeeklyPlanByUser, userID, planID)
	err = db.View(func(txn *badger.Txn) error {
		_, err := txn.Get([]byte(userIndexKey))
		return err
	})
	if err != badger.ErrKeyNotFound {
		t.Errorf("Expected ErrKeyNotFound for user index, got %v", err)
	}
}

// Test listing all WeeklyPlans
func TestWeeklyPlanListAll(t *testing.T) {
	tempDir := t.TempDir()

	opts := badger.DefaultOptions(tempDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		t.Fatalf("Failed to open BadgerDB: %v", err)
	}
	defer db.Close()

	// Create multiple plans
	for i := 1; i <= 5; i++ {
		planID := fmt.Sprintf("plan_%d", i)

		storedPlan := StoredWeeklyPlan{
			ID:           planID,
			UserID:       "user_1",
			Plan:         WeeklyMealPlan{},
			WeekStarting: fmt.Sprintf("2025-01-%02d", i*7),
			CreatedAt:    time.Now(),
		}

		data, _ := json.Marshal(storedPlan)

		err := db.Update(func(txn *badger.Txn) error {
			return txn.Set([]byte(WeeklyPlanPrefix+planID), data)
		})
		if err != nil {
			t.Fatalf("Failed to store plan: %v", err)
		}
	}

	// List all plans
	var retrievedPlans []StoredWeeklyPlan
	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		prefix := []byte(WeeklyPlanPrefix)
		for it.Seek(prefix); it.ValidForPrefix(prefix); it.Next() {
			item := it.Item()
			err := item.Value(func(val []byte) error {
				var stored StoredWeeklyPlan
				if err := json.Unmarshal(val, &stored); err != nil {
					return err
				}
				retrievedPlans = append(retrievedPlans, stored)
				return nil
			})
			if err != nil {
				return err
			}
		}
		return nil
	})
	if err != nil {
		t.Fatalf("Failed to list plans: %v", err)
	}

	if len(retrievedPlans) != 5 {
		t.Errorf("Expected 5 plans, got %d", len(retrievedPlans))
	}
}

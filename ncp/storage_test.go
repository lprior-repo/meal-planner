package ncp

import (
	"os"
	"testing"
	"time"

	"github.com/dgraph-io/badger/v4"
)

func setupTestDB(t *testing.T) (*badger.DB, func()) {
	t.Helper()

	// Create temp directory for test DB
	tmpDir, err := os.MkdirTemp("", "ncp_test_*")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}

	opts := badger.DefaultOptions(tmpDir)
	opts.Logger = nil

	db, err := badger.Open(opts)
	if err != nil {
		os.RemoveAll(tmpDir)
		t.Fatalf("Failed to open test DB: %v", err)
	}

	cleanup := func() {
		db.Close()
		os.RemoveAll(tmpDir)
	}

	return db, cleanup
}

func TestStoreNutritionState(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	date := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)
	state := NutritionState{
		Date: date,
		Consumed: NutritionData{
			Date:     date,
			Protein:  150.5,
			Fat:      60.0,
			Carbs:    200.0,
			Calories: 1950.5,
		},
		SyncedAt: time.Now(),
	}

	err := StoreNutritionState(db, state)
	if err != nil {
		t.Fatalf("Failed to store state: %v", err)
	}

	// Retrieve and verify
	retrieved, err := GetNutritionState(db, date)
	if err != nil {
		t.Fatalf("Failed to retrieve state: %v", err)
	}

	if retrieved.Consumed.Protein != state.Consumed.Protein {
		t.Errorf("Expected protein %f, got %f", state.Consumed.Protein, retrieved.Consumed.Protein)
	}
}

func TestGetNutritionState_NotFound(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	date := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)

	_, err := GetNutritionState(db, date)
	if err == nil {
		t.Error("Expected error for non-existent state, got nil")
	}
}

func TestGetNutritionHistory(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	// Store 7 days of data
	baseDate := time.Date(2024, 11, 23, 0, 0, 0, 0, time.UTC)
	for i := 0; i < 7; i++ {
		date := baseDate.AddDate(0, 0, i)
		state := NutritionState{
			Date: date,
			Consumed: NutritionData{
				Date:     date,
				Protein:  150.0 + float64(i*10),
				Fat:      60.0,
				Carbs:    200.0,
				Calories: 2000.0,
			},
			SyncedAt: time.Now(),
		}
		err := StoreNutritionState(db, state)
		if err != nil {
			t.Fatalf("Failed to store state for day %d: %v", i, err)
		}
	}

	// Get history
	endDate := baseDate.AddDate(0, 0, 6) // 2024-11-29
	history, err := GetNutritionHistory(db, baseDate, endDate)
	if err != nil {
		t.Fatalf("Failed to get history: %v", err)
	}

	if len(history) != 7 {
		t.Errorf("Expected 7 days of history, got %d", len(history))
	}

	// Verify first and last entries
	if history[0].Consumed.Protein != 150.0 {
		t.Errorf("Expected first day protein 150.0, got %f", history[0].Consumed.Protein)
	}
	if history[6].Consumed.Protein != 210.0 {
		t.Errorf("Expected last day protein 210.0, got %f", history[6].Consumed.Protein)
	}
}

func TestGetNutritionHistory_PartialData(t *testing.T) {
	db, cleanup := setupTestDB(t)
	defer cleanup()

	// Store only 3 days of data (with gaps)
	dates := []time.Time{
		time.Date(2024, 11, 23, 0, 0, 0, 0, time.UTC),
		time.Date(2024, 11, 25, 0, 0, 0, 0, time.UTC),
		time.Date(2024, 11, 27, 0, 0, 0, 0, time.UTC),
	}

	for _, date := range dates {
		state := NutritionState{
			Date: date,
			Consumed: NutritionData{
				Date:     date,
				Protein:  150.0,
				Fat:      60.0,
				Carbs:    200.0,
				Calories: 2000.0,
			},
			SyncedAt: time.Now(),
		}
		err := StoreNutritionState(db, state)
		if err != nil {
			t.Fatalf("Failed to store state: %v", err)
		}
	}

	// Get history for 7 days
	startDate := time.Date(2024, 11, 23, 0, 0, 0, 0, time.UTC)
	endDate := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)
	history, err := GetNutritionHistory(db, startDate, endDate)
	if err != nil {
		t.Fatalf("Failed to get history: %v", err)
	}

	// Should only return the 3 days that have data
	if len(history) != 3 {
		t.Errorf("Expected 3 days of history, got %d", len(history))
	}
}

func TestParseStateKey_Valid(t *testing.T) {
	key := "ncp:state:2024-11-29"

	date, err := ParseStateKey(key)
	if err != nil {
		t.Fatalf("ParseStateKey failed: %v", err)
	}

	if date.Year() != 2024 || date.Month() != 11 || date.Day() != 29 {
		t.Errorf("ParseStateKey returned wrong date: %v", date)
	}
}

func TestParseStateKey_Invalid(t *testing.T) {
	tests := []struct {
		name string
		key  string
	}{
		{"too short", "ncp:state:"},
		{"empty", ""},
		{"wrong prefix", "other:2024-11-29"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := ParseStateKey(tt.key)
			if err == nil {
				t.Error("Expected error for invalid key, got nil")
			}
		})
	}
}

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

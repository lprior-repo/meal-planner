package ncp

import (
	"testing"
	"time"

	"github.com/jrmycanady/gocronometer"
)

// TestGoCronometerImport verifies the gocronometer dependency is available
func TestGoCronometerImport(t *testing.T) {
	// Verify we can reference the gocronometer package
	// This is a compile-time check that the dependency is properly installed
	var _ *gocronometer.Client
	t.Log("gocronometer package imported successfully")
}


func TestParseDailyNutritionCSV_Empty(t *testing.T) {
	date := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)

	result, err := parseDailyNutritionCSV("", date)
	if err != nil {
		t.Fatalf("Expected no error for empty data, got %v", err)
	}

	if result.Date != date {
		t.Errorf("Expected date %v, got %v", date, result.Date)
	}
}

func TestParseDailyNutritionCSV_WithData(t *testing.T) {
	date := time.Date(2024, 11, 29, 0, 0, 0, 0, time.UTC)
	csvData := "some,csv,data"

	result, err := parseDailyNutritionCSV(csvData, date)
	if err != nil {
		t.Fatalf("Expected no error, got %v", err)
	}

	// Function currently returns empty nutrition data
	// but should not error
	if result == nil {
		t.Error("Expected non-nil result")
	}
}
